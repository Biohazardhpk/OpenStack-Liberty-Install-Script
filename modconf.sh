#!/bin/bash
# Ask the user for the management ip address
echo Hello, Please insert the Controller management IP address!
read varmanagIPc
sed -i 's/10.0.0.11/$varmanagIPcon/g' 2Controller
echo Hello, Please insert the Compute management IP address!
read varmanagIPcom
sed -i 's/10.0.0.11/$varmanagIPcom/g' 2Compute
echo Your management interface IP  address was set to $varmanagIP
echo Hello, Please insert the mysql root pass!
read varmysqlrpass
sed -i 's/"stack/"$varmysqlrpass/g' 2Controller
echo Your mysql root pass was set to $varmysqlrpass
echo Hello, Please insert Password of user admin
read varADMIN_PASS	
sed -i 's/ADMIN_PASS/$varADMIN_PASS/g' 2Controller
sed -i 's/ADMIN_PASS/$varADMIN_PASS/g' admin-openrc.sh
echo Your Password of user admin was set to $varADMIN_PASS
echo Hello, Please insert Database password for the Telemetry service
read varCEILOMETER_DBPASS
sed -i 's/CEILOMETER_DBPASS/$varCEILOMETER_DBPASS/g' 2Controller	
echo Your Database password for the Telemetry service was set to $varCEILOMETER_DBPASS
echo Hello, Please insert Password of Telemetry service user ceilometer
read varCEILOMETER_PASS	
sed -i 's/CEILOMETER_PASS/$varCEILOMETER_PASS/g' 2Controller
echo Your Password of Telemetry service user ceilometer was set to $varCEILOMETER_PASS
echo Hello, Please insert Database password for the Block Storage service
read varCINDER_DBPASS	
sed -i 's/CINDER_DBPASS/$varCINDER_DBPASS/g' 2Controller
echo Your Database password for the Block Storage service was set to $varCINDER_DBPASS
echo Hello, Please insert Password of Block Storage service user cinder
read varCINDER_PASS	
sed -i 's/CINDER_PASS/$varCINDER_PASS/g' 2Controller
echo Your Please insert Password of Block Storage service user cinder was set to $varCINDER_PASS
echo Hello, Please insert Database password for the dashboard
read varDASH_DBPASS	
sed -i 's/DASH_DBPASS/$varDASH_DBPASS/g' 2Controller
echo Your Database password for the dashboard was set to $varDASH_DBPASS
echo Hello, Please insert Password of user demo
read varDEMO_PASS	
sed -i 's/DEMO_PASS/$varDEMO_PASS/g' 2Controller
sed -i 's/DEMO_PASS/$varDEMO_PASS/g' demo-openrc.sh
echo Your Password of user demo was set to $varDEMO_PASS
echo Hello, Please insert Database password for Image service
read varGLANCE_DBPASS	
sed -i 's/GLANCE_DBPASS/$varGLANCE_DBPASS/g' 2Controller
echo Your Database password for Image service was set to $varGLANCE_DBPASS
echo Hello, Please insert Password of Image service user glance
read varGLANCE_PASS	
sed -i 's/GLANCE_PASS/$varGLANCE_PASS/g' 2Controller
echo Your Password of Image service user glance was set to $varGLANCE_PASS
echo Hello, Please insert Database password for the Orchestration service
read varHEAT_DBPASS	
sed -i 's/HEAT_DBPASS/$varHEAT_DBPASS/g' 2Controller
echo Your Database password for the Orchestration service was set to $varHEAT_DBPASS
echo Hello, Please insert Password of Orchestration domain
read varHEAT_DOMAIN_PASS	
sed -i 's/HEAT_DOMAIN_PASS/$varHEAT_DOMAIN_PASS/g' 2Controller
echo Your Password of Orchestration domain was set to $varHEAT_DOMAIN_PASS
echo Hello, Please insert Password of Orchestration service user heat
read varHEAT_PASS	
sed -i 's/HEAT_PASS/$varHEAT_PASS/g' 2Controller
echo Your Password of Orchestration service user heat was set to $varHEAT_PASS
echo Hello, Please insert Database password of Identity service
read varKEYSTONE_DBPASS	
sed -i 's/KEYSTONE_DBPASS/$varKEYSTONE_DBPASS/g' 2Controller
echo Your Database password of Identity service was set to $varKEYSTONE_DBPASS
echo Hello, Please insert Database password for the Networking service
read varNEUTRON_DBPASS	
sed -i 's/NEUTRON_DBPASS/$varNEUTRON_DBPASS/g' 2Controller
echo Your Database password for the Networking service was set to $varNEUTRON_DBPASS
echo Hello, Please insert Password of Networking service user neutron
read varNEUTRON_PASS	
sed -i 's/NEUTRON_PASS/$varNEUTRON_PASS/g' 2Controller
sed -i 's/NEUTRON_PASS/$varNEUTRON_PASS/g' 2Compute
echo Your Password of Networking service user neutron was set to $varNEUTRON_PASS
echo Hello, Please insert Database password for Compute service
read varNOVA_DBPASS	
sed -i 's/NOVA_DBPASS/$varNOVA_DBPASS/g' 2Controller
echo Your Database password for Compute service was set to $varNOVA_DBPASS
echo Hello, Please insert Password of Compute service user nova
read varNOVA_PASS	
sed -i 's/NOVA_PASS/$varNOVA_PASS/g' 2Controller
sed -i 's/NOVA_PASS/$varNOVA_PASS/g' 2Compute
echo Your Password of Compute service user nova was set to $varNOVA_PASS
echo Hello, Please insert Password of user guest of RabbitMQ
read varRABBIT_PASS	
sed -i 's/RABBIT_PASS/$varRABBIT_PASS/g' 2Controller
sed -i 's/RABBIT_PASS/$varRABBIT_PASS/g' 2Compute
echo Your Password of user guest of RabbitMQ was set to $varRABBIT_PASS
echo Hello, Please insert Password of Object Storage service user swift
read varSWIFT_PASS 
sed -i 's/SWIFT_PASS/$varSWIFT_PASS/g' 2Controller
echo Your Password of Object Storage service user swift was set to $varSWIFT_PASS
