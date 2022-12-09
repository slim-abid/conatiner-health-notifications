#!/bin/bash
list_of_containers="LIST-OF-CONTAINERS"
containers=`docker ps -f status=running --format "{{.Names}}"`
failed_containers=()
Recipients="MAILS-OF-RECIPIENTS"
[[ -f "/tmp/failing_container_found" ]] && exit 0 


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
    emailSubject="Subject: WARNING: showing exiting containers"
    printf "To: ${Recipients}\n" > mail.txt
    echo $emailSubject >> mail.txt
    printf "\nFailing containers are: %s.\n" "${failed_containers[@]}" >> mail.txt
    set -x
        sendmail -vt < ./mail.txt
    set +x    
    [ $? -eq 0 ] && touch /tmp/failing_container_found
fi
exit 0