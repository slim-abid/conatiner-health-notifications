## container-health-notifications
Get emails on failing containers for docker on linux 


install sSMTP
edit files /etc/ssmtp/ssmtp.conf /etc/ssmtp/revaliases
schedule systemd timer and service  /etc/systemd/system/container.health.timer /etc/systemd/system/container.health.timer

reload systemd:
systemctl daemon-reload

start the new timer:
systemctl start container.health.timer