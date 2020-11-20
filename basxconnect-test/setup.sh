#!/bin/bash

branch=master
if [ ! -z "$1" ]; then
  branch=$1
fi

curl https://get.basxconnect.solidcharity.com | bash -s prod --branch=$branch --behindsslproxy=true || exit -1

# we are contacting the site through http://localhost but still want to use the CSRF cookie
echo "CSRF_COOKIE_SECURE = False" >> /home/django/basxconnect/basxconnect/settings/production.py
systemctl restart basxconnect

mkdir -p /tmp/test
cd /tmp/test
virtualenv -p /usr/bin/python3 .venv || exit -1
source .venv/bin/activate
pip install requests

cat > test.py <<FINISH
import requests

User="admin"
Pwd="CHANGEME"
url="http://localhost:8000"

S = requests.Session()

# Retrieve login token first
r1 = S.get(url=url + "/accounts/login/?next=/")
csrftoken = S.cookies['csrftoken']

PARAMS = {
    'csrfmiddlewaretoken':csrftoken,
    'username':User,
    'password':Pwd,
}
r2 = S.post(url + "/accounts/login/?next=/", data=PARAMS, cookies=r1.cookies)
if "Please enter a correct username and password" in r2.text:
  print("wrong username or password")
  exit(-1)
if not '/core/person/browse' in r2.text:
  print("cannot find link to browsing persons")
  exit(-1)
FINISH

python3 test.py || exit -1
