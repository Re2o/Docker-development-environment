#! /bin/bash

service apache2 stop
python3 manage.py migrate
python3 manage.py collectstatic --noinput
python3 manage.py compilemessages
service apache2 start
service slapd start
sleep infinity
