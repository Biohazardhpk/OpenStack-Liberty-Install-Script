#!/bin/bash
#Create the public network
source admin-openrc.sh
 neutron net-create public --shared --provider:physical_network public \
  --provider:network_type flat
#Config security group
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule default tcp 22 22 0.0.0.0/0
#Get some usefull data
echo -n "Public network with cidr > "
read PUBLIC_NETWORK_CIDR
echo -n "Enter start IP address > "
read START_IP_ADDRESS
echo -n "Enter end IP address > "
read END_IP_ADDRESS
echo -n "Enter DNS > "
read DNS_RESOLVER
echo -n "Enter gateway > "
read PUBLIC_NETWORK_GATEWAY
#Create public subnet
neutron subnet-create public $PUBLIC_NETWORK_CIDR --name public \
  --allocation-pool start=$START_IP_ADDRESS,end=$END_IP_ADDRESS\
  --dns-nameserver $DNS_RESOLVER --gateway $PUBLIC_NETWORK_GATEWAY
#Create private net and subnet
source demo-openrc.sh
neutron net-create private
neutron subnet-create private 172.16.16.0/24 --name private --dns-nameserver $DNS_RESOLVER --gateway 172.16.16.1
#Create router
source admin-openrc.sh
neutron net-update public --router:external
source demo-openrc.sh
neutron router-create router
neutron router-interface-add router private
neutron router-gateway-set router public
#Create floating IP
neutron floatingip-create public
#Create private instance
source demo-openrc.sh
neutron net-list
echo -n "Copy private network ID > "
read PRIVATE_NET_ID
nova boot private-instance --flavor m1.tiny --image cirros --nic net-id=$PRIVATE_NET_ID --security-group default
#Associate floating IP
nova floating-ip-associate private-instance neutron $(neutron floatingip-list | awk 'NR==4 {print$6}')
#Check them
nova list
