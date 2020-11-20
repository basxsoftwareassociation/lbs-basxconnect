#!/bin/bash

branch=master
if [ ! -z "$1" ]; then
  branch=$1
fi

curl https://get.basxconnect.solidcharity.com | bash -s prod --branch=$branch --behindsslproxy=true || exit -1

cat > /tmp/test.py <<FINISH

FINISH



python /tmp/test.py || exit -1
