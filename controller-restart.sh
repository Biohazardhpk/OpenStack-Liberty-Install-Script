source admin-openrc.sh
service mysql restart
service apache2 start
service glance-registry restart
service glance-api restart
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
service neutron-server restart
service neutron-plugin-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart
service apache2 reload
nova service-list
neutron agent-list
