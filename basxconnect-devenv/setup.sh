#!/bin/bash

branch=master
if [ ! -z "$1" ]; then
  branch=$1
fi

curl https://get.basxconnect.solidcharity.com | bash -s devenv --branch=$branch --behindsslproxy=true || exit -1

# we need psmisc for killall
apt-get -y install psmisc || dnf -y install psmisc || exit -1

function fail {
  echo "failure: it does not work"
  killall python
  exit -1
}

# run as user django
su - django -c "cd /home/django/basxconnect_demo && source .venv/bin/activate && python manage.py runserver 127.0.0.1:8080 > /dev/null 2>&1 &"
sleep 10 # wait for the server to start

mkdir -p /home/django/test
cd /home/django/test
python3 -m venv .venv || exit -1
source .venv/bin/activate
pip install requests lxml

cat > test.py <<FINISH
import requests
from lxml import html

User="admin"
Pwd="CHANGEME"
url="http://localhost:8080"
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

python3 test.py || fail

killall python || exit -1
