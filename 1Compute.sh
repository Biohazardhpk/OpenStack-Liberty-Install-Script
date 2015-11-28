#!/bin/bash
#Install NTP service
apt-get install chrony
sed -i '20,23d' /etc/chrony/chrony.conf
sed -i '20 a server controller iburst' /etc/chrony/chrony.conf
service chrony restart
#Enable OpenStack Repository
apt-get update && apt-get dist-upgrade -y
apt-get install software-properties-common
yes '' | add-apt-repository cloud-archive:liberty
apt-get update && apt-get dist-upgrade -y
reboot
