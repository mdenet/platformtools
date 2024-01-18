#! /bin/bash
if [ ! -z "${XTEXT_ES_STOP_CRON_TIME}" ]; then 
        (crontab -l; echo "${XTEXT_ES_STOP_CRON_TIME}" echo Scheduled shutdown triggered. "&&" killall -u root) | crontab - 
        crontab -l 
        echo cron job for scheduled shutdown configured.; 
fi