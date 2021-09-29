Test scripts for basxConnect
=======================

This repository contains install and tests scripts.

These scripts are being run every night on the LightBuildServer (LBS), to see if the current main branch is actually working.

We have two projects:

1. We can test the development environment of basxConnect, see in action at https://lbs.solidcharity.com/package/basx/basxconnect/basxconnect-devenv. This makes use of https://get.basxconnect.solidcharity.com; After installing the development environment (with sqlite database), a script will attempt to login via Python through the web interface running on localhost.
2. We can run some tests on the current branch, see in action at https://lbs.solidcharity.com/package/basx/basxconnect/basxconnect-test. This also makes use of https://get.basxconnect.solidcharity.com; After installing a production environment (with mysql database), a script will attempt to login via Python through the web interface running on localhost.
