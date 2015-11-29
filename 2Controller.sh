#!/bin/bash
#Aici trebuie relogare cel mai probabil o sa rup scriptul
apt-get install python-openstackclient -y
#Install SQL database
apt-get install mariadb-server python-pymysql -y
#Will be prompted for pass generaly use stack
apt-get install crudini -y
touch /etc/mysql/conf.d/mysqld_openstack.cnf
crudini --set /etc/mysql/conf.d/mysqld_openstack.cnf mysqld bind-address 10.0.0.11
crudini --set /etc/mysql/conf.d/mysqld_openstack.cnf mysqld default-storage-engine innodb
crudini --set /etc/mysql/conf.d/mysqld_openstack.cnf mysqld collation-server utf8_general_ci
crudini --set /etc/mysql/conf.d/mysqld_openstack.cnf mysqld init-connect "'SET NAMES utf8'"
crudini --set /etc/mysql/conf.d/mysqld_openstack.cnf mysqld character-set-server utf8
sed -i '6 a innodb_file_per_table' /etc/mysql/conf.d/mysqld_openstack.cnf
service mysql restart
# Automate Secure script install
apt-get -y install expect
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"stack\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"n\r\"
expect \"Disallow root login remotely?\"
send \"n\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
echo "$SECURE_MYSQL"
aptitude -y purge expect
#Install NoSQL database
apt-get install mongodb-server mongodb-clients python-pymongo -y
sed -i 's/bind_ip = 127.0.0.1/bind_ip = 10.0.0.11/g' /etc/mongodb.conf
sed -i '$ a smallfiles = true' /etc/mongodb.conf
service mongodb stop
rm /var/lib/mongodb/journal/prealloc.*
service mongodb start
#Install Message Queue
apt-get install rabbitmq-server -y
rabbitmqctl add_user openstack RABBIT_PASS
rabbitmqctl set_permissions openstack ".*" ".*" ".*"
#Install the identity
mysql -u root --password=stack <<MYSQL_SCRIPT
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';
exit;
MYSQL_SCRIPT
export ADMIN_TOKEN=$(openssl rand -hex 10)
echo "manual" > /etc/init/keystone.override
apt-get install keystone apache2 libapache2-mod-wsgi \
  memcached python-memcache -y
crudini --set /etc/keystone/keystone.conf DEFAULT admin_token $ADMIN_TOKEN
crudini --set /etc/keystone/keystone.conf DEFAULT verbose True
crudini --set /etc/keystone/keystone.conf database connection mysql+pymysql://keystone:KEYSTONE_DBPASS@controller/keystone
crudini --set /etc/keystone/keystone.conf memcache servers localhost:11211
crudini --set /etc/keystone/keystone.conf token provider uuid
crudini --set /etc/keystone/keystone.conf token driver memcache
crudini --set /etc/keystone/keystone.conf revoke driver sql
su -s /bin/sh -c "keystone-manage db_sync" keystone
#Configure the Apache Server
sed -i '14 a ServerName controller' /etc/apache2/apache2.conf
cp wsgi-keystone.conf /etc/apache2/sites-available/wsgi-keystone.conf
ln -s /etc/apache2/sites-available/wsgi-keystone.conf /etc/apache2/sites-enabled
service apache2 restart
rm -f /var/lib/keystone/keystone.db
#Create Service Enty and API endpoints
export OS_TOKEN=$ADMIN_TOKEN
export OS_URL=http://controller:35357/v3
export OS_IDENTITY_API_VERSION=3
openstack service create \
  --name keystone --description "OpenStack Identity" identity
openstack endpoint create --region RegionOne \
  identity public http://controller:5000/v2.0
openstack endpoint create --region RegionOne \
  identity internal http://controller:5000/v2.0
openstack endpoint create --region RegionOne \
  identity admin http://controller:35357/v2.0
#Create projects, users and roles
openstack project create --domain default \
  --description "Admin Project" admin
openstack user create --domain default \
  --password ADMIN_PASS admin
openstack role create admin
openstack role add --project admin --user admin admin
openstack project create --domain default \
  --description "Service Project" service
openstack project create --domain default \
  --description "Demo Project" demo
openstack user create --domain default \
  --password DEMO_PASS demo
openstack role create user  
openstack role add --project demo --user demo user
#Verify Operation
unset OS_TOKEN OS_URL
sed -i 's/sizelimit url_normalize request_id build_auth_context token_auth admin_token_auth json_body ec2_extension user_crud_extension public_service/sizelimit url_normalize request_id build_auth_context token_auth json_body ec2_extension user_crud_extension public_service/g' /etc/keystone/keystone-paste.ini
sed -i 's/sizelimit url_normalize request_id build_auth_context token_auth admin_token_auth json_body ec2_extension s3_extension crud_extension admin_service/sizelimit url_normalize request_id build_auth_context token_auth json_body ec2_extension s3_extension crud_extension admin_service/g' /etc/keystone/keystone-paste.ini
sed -i 's/sizelimit url_normalize request_id build_auth_context token_auth admin_token_auth json_body ec2_extension_v3 s3_extension simple_cert_extension revoke_extension federation_extension oauth1_extension endpoint_filter_extension service_v3/sizelimit url_normalize request_id build_auth_context token_auth json_body ec2_extension_v3 s3_extension simple_cert_extension revoke_extension federation_extension oauth1_extension endpoint_filter_extension service_v3/g' /etc/keystone/keystone-paste.ini
openstack --os-auth-url http://controller:35357/v3 \
  --os-project-domain-id default --os-user-domain-id default \
  --os-project-name admin --os-username admin --os-password ADMIN_PASS\
  token issue
openstack --os-auth-url http://controller:5000/v3 \
  --os-project-domain-id default --os-user-domain-id default \
  --os-project-name demo --os-username demo --os-password DEMO_PASS \
  token issue
#Create Client environment Scripts the files are are presumed to be copyed and already configured
source admin-openrc.sh
#Add image service
mysql -u root --password=stack <<MYSQL_SCRIPT 
CREATE DATABASE glance;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'GLANCE_DBPASS';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'GLANCE_DBPASS';
exit;
MYSQL_SCRIPT
source admin-openrc.sh
openstack user create --domain default --password GLANCE_DBPASS glance
openstack role add --project service --user glance admin
openstack service create --name glance \
  --description "OpenStack Image service" image
openstack endpoint create --region RegionOne \
  image public http://controller:9292
openstack endpoint create --region RegionOne \
  image internal http://controller:9292
openstack endpoint create --region RegionOne \
  image admin http://controller:9292
#Install and configure components
apt-get install glance python-glanceclient -y
crudini --set /etc/glance/glance-api.conf database connection mysql+pymysql://glance:GLANCE_DBPASS@controller/glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_uri http://controller:5000
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_url http://controller:35357
crudini --set /etc/glance/glance-api.conf keystone_authtoken auth_plugin password
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_domain_id default
crudini --set /etc/glance/glance-api.conf keystone_authtoken user_domain_id default
crudini --set /etc/glance/glance-api.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-api.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-api.conf keystone_authtoken password GLANCE_DBPASS
crudini --set /etc/glance/glance-api.conf paste_deploy flavor keystone
crudini --set /etc/glance/glance-api.conf glance_store default_store file
crudini --set /etc/glance/glance-api.conf glance_store filesystem_store_datadir /var/lib/glance/images/
crudini --set /etc/glance/glance-api.conf DEFAULT notification_driver noop
crudini --set /etc/glance/glance-api.conf DEFAULT verbose True
#Configure glance auth
crudini --set /etc/glance/glance-registry.conf database connection mysql+pymysql://glance:GLANCE_DBPASS@controller/glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_uri http://controller:5000
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_url http://controller:35357
crudini --set /etc/glance/glance-registry.conf keystone_authtoken auth_plugin password
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_domain_id default
crudini --set /etc/glance/glance-registry.conf keystone_authtoken user_domain_id default
crudini --set /etc/glance/glance-registry.conf keystone_authtoken project_name service
crudini --set /etc/glance/glance-registry.conf keystone_authtoken username glance
crudini --set /etc/glance/glance-registry.conf keystone_authtoken password GLANCE_DBPASS
crudini --set /etc/glance/glance-registry.conf paste_deploy flavor keystone
crudini --set /etc/glance/glance-registry.conf DEFAULT notification_driver noop
crudini --set /etc/glance/glance-registry.conf DEFAULT verbose True
su -s /bin/sh -c "glance-manage db_sync" glance
service glance-registry restart
service glance-api restart
rm -f /var/lib/glance/glance.sqlite
#Verify Glance
echo "export OS_IMAGE_API_VERSION=2" \
  | tee -a admin-openrc.sh demo-openrc.sh
source admin-openrc.sh
wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
glance image-create --name "cirros" \
  --file cirros-0.3.4-x86_64-disk.img \
  --disk-format qcow2 --container-format bare \
  --visibility public --progress
glance image-list
#Add the compute service
mysql -u root --password=stack <<MYSQL_SCRIPT 
CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';
exit;
MYSQL_SCRIPT
source admin-openrc.sh
openstack user create --domain default --password NOVA_PASS nova 
openstack role add --project service --user nova admin
openstack service create --name nova \
  --description "OpenStack Compute" compute
openstack endpoint create --region RegionOne \
  compute public http://controller:8774/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  compute internal http://controller:8774/v2/%\(tenant_id\)s
openstack endpoint create --region RegionOne \
  compute admin http://controller:8774/v2/%\(tenant_id\)s
#Install and configure components
apt-get install nova-api nova-cert nova-conductor \
  nova-consoleauth nova-novncproxy nova-scheduler \
  python-novaclient -y
crudini --set /etc/nova/nova.conf database connection mysql+pymysql://nova:NOVA_DBPASS@controller/nova
crudini --set /etc/nova/nova.conf DEFAULT rpc_backend rabbit
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_host controller
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/nova/nova.conf oslo_messaging_rabbit rabbit_password RABBIT_PASS
crudini --set /etc/nova/nova.conf DEFAULT auth_strategy keystone
crudini --set /etc/nova/nova.conf keystone_authtoken auth_uri http://controller:5000
crudini --set /etc/nova/nova.conf keystone_authtoken auth_url http://controller:35357
crudini --set /etc/nova/nova.conf keystone_authtoken auth_plugin password
crudini --set /etc/nova/nova.conf keystone_authtoken project_domain_id default
crudini --set /etc/nova/nova.conf keystone_authtoken user_domain_id default
crudini --set /etc/nova/nova.conf keystone_authtoken project_name service
crudini --set /etc/nova/nova.conf keystone_authtoken username nova
crudini --set /etc/nova/nova.conf keystone_authtoken password NOVA_PASS
crudini --set /etc/nova/nova.conf DEFAULT my_ip 10.0.0.11
crudini --set /etc/nova/nova.conf DEFAULT network_api_class nova.network.neutronv2.api.API
crudini --set /etc/nova/nova.conf DEFAULT security_group_api neutron
crudini --set /etc/nova/nova.conf DEFAULT linuxnet_interface_driver nova.network.linux_net.NeutronLinuxBridgeInterfaceDriver
crudini --set /etc/nova/nova.conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver
crudini --set /etc/nova/nova.conf vnc vncserver_listen $my_ip
crudini --set /etc/nova/nova.conf vnc vncserver_proxyclient_address $my_ip
crudini --set /etc/nova/nova.conf glance host controller
crudini --set /etc/nova/nova.conf oslo_concurrency lock_path /var/lib/nova/tmp
crudini --set /etc/nova/nova.conf DEFAULT enabled_apis osapi_compute,metadata
crudini --set /etc/nova/nova.conf DEFAULT verbose True
#Restart nova services
su -s /bin/sh -c "nova-manage db sync" nova
service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart
rm -f /var/lib/nova/nova.sqlite
#Verify nova install
source admin-openrc.sh
nova service-list
nova image-list
#Install Neutron
mysql -u root --password=stack <<MYSQL_SCRIPT 
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO neutron@'localhost' IDENTIFIED BY 'NEUTRON_DBPASS';
GRANT ALL PRIVILEGES ON neutron.* TO neutron@'%' IDENTIFIED BY 'NEUTRON_DBPASS';
exit;
MYSQL_SCRIPT
source admin-openrc.sh
openstack user create --domain default --password NEUTRON_PASS neutron
openstack role add --project service --user neutron admin
openstack service create --name neutron \
  --description "OpenStack Networking" network
openstack endpoint create --region RegionOne \
  network public http://controller:9696
openstack endpoint create --region RegionOne \
  network internal http://controller:9696
openstack endpoint create --region RegionOne \
  network admin http://controller:9696
#Instal and config neutron on controller
apt-get install neutron-server neutron-plugin-ml2 \
  neutron-plugin-linuxbridge-agent neutron-l3-agent neutron-dhcp-agent \
  neutron-metadata-agent python-neutronclient -y
#Configure the api and nova for neutron
crudini --set /etc/neutron/neutron.conf database connection mysql+pymysql://neutron:NEUTRON_DBPASS@controller/neutron
crudini --set /etc/neutron/neutron.conf DEFAULT core_plugin ml2
crudini --set /etc/neutron/neutron.conf DEFAULT service_plugins router
crudini --set /etc/neutron/neutron.conf DEFAULT allow_overlapping_ips True
crudini --set /etc/neutron/neutron.conf DEFAULT rpc_backend rabbit
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_host controller
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_userid openstack
crudini --set /etc/neutron/neutron.conf oslo_messaging_rabbit rabbit_password RABBIT_PASS
crudini --set /etc/neutron/neutron.conf DEFAULT auth_strategy keystone
crudini --del /etc/neutron/neutron.conf keystone_authtoken
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_uri http://controller:5000
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_url http://controller:35357
crudini --set /etc/neutron/neutron.conf keystone_authtoken auth_plugin password
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_domain_id default
crudini --set /etc/neutron/neutron.conf keystone_authtoken user_domain_id default
crudini --set /etc/neutron/neutron.conf keystone_authtoken project_name service
crudini --set /etc/neutron/neutron.conf keystone_authtoken username neutron
crudini --set /etc/neutron/neutron.conf keystone_authtoken password NEUTRON_PASS
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_status_changes True
crudini --set /etc/neutron/neutron.conf DEFAULT notify_nova_on_port_data_changes True
crudini --set /etc/neutron/neutron.conf DEFAULT nova_url http://controller:8774/v2
crudini --set /etc/neutron/neutron.conf nova auth_url http://controller:35357
crudini --set /etc/neutron/neutron.conf nova auth_plugin password
crudini --set /etc/neutron/neutron.conf nova project_domain_id default
crudini --set /etc/neutron/neutron.conf nova user_domain_id default
crudini --set /etc/neutron/neutron.conf nova region_name RegionOne
crudini --set /etc/neutron/neutron.conf nova project_name service
crudini --set /etc/neutron/neutron.conf nova username nova
crudini --set /etc/neutron/neutron.conf nova password NOVA_PASS
crudini --set /etc/neutron/neutron.conf DEFAULT verbose True
#Ml2 plugin config, layer 3 and dhcp
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 type_drivers flat,gre
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 tenant_network_types gre
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 mechanism_drivers linuxbridge,l2population,openvswitch
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2 extension_drivers port_security
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_flat flat_networks public
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini ml2_type_gre tunnel_id_ranges 1:1000
crudini --set /etc/neutron/plugins/ml2/ml2_conf.ini securitygroup enable_ipset True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini linux_bridge physical_interface_mappings public:eth1
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini gre enable_gre True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini gre local_ip 10.0.0.11
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini gre l2_population True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini agent prevent_arp_spoofing True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup enable_security_group True
crudini --set /etc/neutron/plugins/ml2/linuxbridge_agent.ini securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver
crudini --set /etc/neutron/l3_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.BridgeInterfaceDriver
crudini --set /etc/neutron/l3_agent.ini DEFAULT external_network_bridge 
crudini --set /etc/neutron/l3_agent.ini DEFAULT verbose True
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT interface_driver neutron.agent.linux.interface.BridgeInterfaceDriver
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT enable_isolated_metadata True
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT verbose True
crudini --set /etc/neutron/dhcp_agent.ini DEFAULT dnsmasq_config_file /etc/neutron/dnsmasq-neutron.conf
#config DHCP
touch /etc/neutron/dnsmasq-neutron.conf
echo "dhcp-option-force=26,1450" >> /etc/neutron/dnsmasq-neutron.conf
#Cobnfig metadata
crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_uri http://controller:5000
crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_url http://controller:35357
crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_region RegionOne
crudini --set /etc/neutron/metadata_agent.ini DEFAULT auth_plugin password
crudini --set /etc/neutron/metadata_agent.ini DEFAULT project_domain_id default
crudini --set /etc/neutron/metadata_agent.ini DEFAULT user_domain_id default
crudini --set /etc/neutron/metadata_agent.ini DEFAULT project_name service
crudini --set /etc/neutron/metadata_agent.ini DEFAULT username neutron
crudini --set /etc/neutron/metadata_agent.ini DEFAULT password NEUTRON_PASS
crudini --set /etc/neutron/metadata_agent.ini DEFAULT nova_metadata_ip controller
crudini --set /etc/neutron/metadata_agent.ini DEFAULT metadata_proxy_shared_secret METADATA_SECRET
crudini --set /etc/neutron/metadata_agent.ini DEFAULT verbose True
#Configure compute to use the network
crudini --set /etc/nova/nova.conf neutron url http://controller:9696
crudini --set /etc/nova/nova.conf neutron auth_url http://controller:35357
crudini --set /etc/nova/nova.conf neutron auth_plugin password
crudini --set /etc/nova/nova.conf neutron project_domain_id default
crudini --set /etc/nova/nova.conf neutron user_domain_id default
crudini --set /etc/nova/nova.conf neutron region_name RegionOne
crudini --set /etc/nova/nova.conf neutron project_name service
crudini --set /etc/nova/nova.conf neutron username neutron
crudini --set /etc/nova/nova.conf neutron password NEUTRON_PASS
crudini --set /etc/nova/nova.conf neutron service_metadata_proxy True
crudini --set /etc/nova/nova.conf neutron metadata_proxy_shared_secret METADATA_SECRET
crudini --set /etc/nova/nova.conf DEFAULT service_metadata_proxy True
crudini --set /etc/nova/nova.conf DEFAULT metadata_proxy_shared_secret METADATA_SECRET
#populate neutron
su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
  --config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade head" neutron
#Restart the Networking and Compute services.
service nova-api restart
service neutron-server restart
service neutron-plugin-linuxbridge-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service neutron-l3-agent restart
rm -f /var/lib/neutron/neutron.sqlite
#Dashboard installl
apt-get install openstack-dashboard -y
#to check if not working if sed is passing the lines!!!
sed -i 's/OPENSTACK_HOST = "127.0.0.1"/OPENSTACK_HOST = "controller"/g' /etc/openstack-dashboard/local_settings.py
sed -i 's/OPENSTACK_KEYSTONE_DEFAULT_ROLE = "_member_"/OPENSTACK_KEYSTONE_DEFAULT_ROLE = "user"/g' /etc/openstack-dashboard/local_settings.py
sed -i '675d' /etc/openstack-dashboard/local_settings.py
echo "ALLOWED_HOSTS = ['*', ]" >> /etc/openstack-dashboard/local_settings.py
service apache2 reload
#Restart Controller+network
source admin-openrc.sh
service mysql restart
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

