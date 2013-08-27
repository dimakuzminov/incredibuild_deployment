#!/bin/sh
rm -rf /var/log/incredibuild
mkdir -p /var/log/incredibuild
service rsyslog restart
