#!/bin/bash

while true; do
  LEVEL=$(shuf -e INFO WARN ERROR DEBUG TRACE -n 1)
  USER=$(shuf -e admin user1 user2 guest api-service backend-service -n 1)
  ACTION=$(shuf -e login logout update delete create read write access modify execute -n 1)
  IP="192.168.$((RANDOM%255)).$((RANDOM%255))"
  ID=$((RANDOM % 100000))
  TS="$(date '+%Y-%m-%d %H:%M:%S')"
  TS_JSON="$(date '+%Y-%m-%dT%H:%M:%S')"

  echo "$TS $LEVEL user=$USER action=$ACTION ip=$IP record_id=$ID" >> /var/log/myapp/app.log

  echo "{\"timestamp\":\"$TS_JSON\",\"level\":\"$LEVEL\",\"user\":\"$USER\",\"action\":\"$ACTION\",\"ip\":\"$IP\",\"record_id\":$ID}" >> /var/log/myapp/app.json

  for i in {1..10}; do
    LEVEL2=$(shuf -e INFO WARN ERROR DEBUG -n 1)
    echo "$TS $LEVEL2 burst_log=true id=$RANDOM message=Auto-generated" >> /var/log/myapp/app.log
  done

  sleep 1
done
