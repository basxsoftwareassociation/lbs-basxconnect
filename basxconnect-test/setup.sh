#!/bin/bash

branch=master
if [ ! -z "$1" ]; then
  branch=$1
fi

curl https://get.basxconnect.solidcharity.com | bash -s prod --branch=$branch --behindsslproxy=true || exit -1

mkdir -p /tmp/test
cd /tmp/test
python3 -m venv .venv || exit -1
source .venv/bin/activate
pip install requests lxml

# $DOMAINNAME will be set by calling script
if [ -z "$DOMAINNAME" ]; then
  echo "missing environment variable DOMAINNAME"
  exit -1
fi

settings=/home/django/basxconnect_demo/basxconnect_demo/settings/production.py
echo "ALLOWED_HOSTS = ['localhost','$DOMAINNAME']" >> $settings
echo "SECURE_SSL_REDIRECT = False" >> $settings
systemctl restart basxconnect

cat > test.py <<FINISH
import requests
from lxml import html

User="admin"
Pwd="CHANGEME"
url="https://$DOMAINNAME/"
loginpath="/basxbread/accounts/login/?next=/"

S = requests.Session()

# Retrieve login token first
r1 = S.get(url=url + loginpath)
csrftoken = S.cookies['csrftoken']

tree = html.fromstring(r1.content)
token = tree.xpath('//input[@name="csrfmiddlewaretoken"]')[0].attrib['value']

PARAMS = {
    'csrfmiddlewaretoken':token,
    'username':User,
    'password':Pwd+'Wrong',
}
r2 = S.post(url + loginpath, data=PARAMS, cookies=r1.cookies)
if not "Please enter a correct username and password" in r2.text:
  print("Does not complain about wrong password")
  exit(-1)

PARAMS = {
    'csrfmiddlewaretoken':token,
    'username':User,
    'password':Pwd,
}
r2 = S.post(url + loginpath, data=PARAMS, cookies=r1.cookies)
if "Please enter a correct username and password" in r2.text:
  print("wrong username or password")
  exit(-1)
if not '/basxconnect/core/person/browse' in r2.text:
  print("cannot find link to browsing persons")
  exit(-1)
FINISH

python3 test.py || exit -1
