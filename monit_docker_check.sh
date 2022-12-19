#!/bin/bash
list_of_containers="proxy integration api ingress engine rabbitmq fluentd mqtt redis"
containers=`docker ps -f status=running --format "{{.Names}}"`
failed_containers=()
Recipients="XXXXXX@ltd"
[[ -f "/tmp/failing_iotc_container_found" ]] && exit 0 

# Set the options string to "fvh" to specify that the script should recognize the -s, -m, and -h flags
OPTSTRING=smh

# Set the default values for the flags
flag_s=0
flag_m=0

# Use a while loop to process the flags passed to the script
while getopts $OPTSTRING opt; do
  case "$opt" in
    s) flag_s=1;;
    m) flag_m=1;;
    h)
      # Display the help message if the -h or --help flag is set
      echo "Usage: monit_docker_check.sh [options]"
      echo "  -s        Enable internal smtp client to send mails"
      echo "  -m        Enable mailgun api to send mails"
      echo "  -h        Display this help message"
      exit 0
      ;;
    *) echo "Error: Invalid option" >&2; exit 1;;
  esac
done

# Shift the positional parameters to remove the processed options
shift $((OPTIND-1))

for container in $list_of_containers
do
  if echo $containers | grep -iq $container
    then  echo "$container online "
  else echo "$container offline"
    failed_containers+=($container)
  fi
done

#TODO: add logs as attachement to the mail body
# Warning if any of IoTC containers fail
if [ ${#failed_containers[@]} -ne 0 ];
then
    # Use the values of the flags to determine the behavior of the script
    if [ "$flag_s" -eq 1 ]; then
            # Do something if the -s flag is set
            # Split the input string into an array of words
            IFS=' ' read -r -a words <<< "$Recipients"
            # Concatenate the words into a comma-delimited string
            for word in "${words[@]}"; do
                Recipients="$Recipients$word,"
            done
            # Remove the trailing comma
            Recipients=${Recipients%,}
            emailSubject="Subject: WARNING: showing exited or stopped containers"
            printf "To: ${Recipients}\n" > mail.txt
            echo $emailSubject >> mail.txt
            printf "\nFailing containers are: %s.\n" "${failed_containers[@]}" >> mail.txt
            for container in "${failed_containers[@]}"
            do
              printf "\nLogs for %s are the following:\n" $container >> mail.txt
              docker ps -a -f "name=$container" --format "{{.Names}}" | xargs docker logs -f --tail 20 |& tee -a mail.txt
              echo "" >> mail.txt
            done
            set -x
                sendmail -vt < ./mail.txt
            set +x 
    elif [ "$flag_m" -eq 1 ]; then
      # Do something if the -m flag is set
            source mailgun_config.sh
            for container in "${failed_containers[@]}"
            do
              printf "\nLogs for %s are the following:\n" $container > mail.txt
              docker ps -a -f "name=$container" --format "{{.Names}}" | xargs docker logs -f --tail 20 |& tee -a mail.txt
              echo "" >> mail.txt
            done
            set -x
                curl -s --user "api:$YOUR_API_KEY" \
                https://api.mailgun.net/v3/$(echo -n "$YOUR_DOMAIN_NAME" )/messages \
                -F from="Container health <$YOUR_SENDER_MAIL>" \
                -F subject='WARNING: showing exited or stopped containers' \
                -F text="$(cat mail.txt)" \
                  $( for Recipient in $Recipients; do echo -nE "-F to=$Recipient "; done )

            set +x 
    else
      # Do something if no flags are set
      echo "No flags set"
    fi 
    [ $? -eq 0 ] && touch /tmp/failing_iotc_container_found
fi
exit 0

