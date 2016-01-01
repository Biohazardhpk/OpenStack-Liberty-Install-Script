# To install just download the files provided and follow the guide.
##If the files from here do not work as a script please refer to this link: 
https://www.dropbox.com/s/yr8czy0bmta8q6x/Scripts.rar?dl=0


# Welcome to the OpenStack-Liberty-Script install wiki! (this installation is following the official documentation therefore the SDN inside OpenStack is using VXLAN with linux bridge)
## Necessary software
- [VMware Workstation](https://www.vmware.com/products/workstation)
- [MobaXterm](http://mobaxterm.mobatek.net/download.html)
- Optional [Notepad++](https://notepad-plus-plus.org/) in case you want to edit a file.

Note: Make a PortFowarding rule for SSH on the NAT network in VMware for the two VM's

## Hardware Infrastructure
For the deployment two virtual machines will be necessary with two NIC cards attached:
- One for managing traffic between the Controller and the Compute nodes
- One for Internet access and data traffic between multiple Compute nodes

### The topology is presented in the figure below
![](http://s20.postimg.org/r77vcrssd/Network_config.png)

## Machine configuration
- If you want to have a decent running speed for the cloud environment I recommend that for each virtual machine to allocate at least 4 GB of RAM memory and a virtual HDD of 320 GB.
- The operation system  on both machines must be [Ubuntu 14.04 LTS "Trusty Tahr" x64](https://help.ubuntu.com/community/Installation/MinimalCD) 
- For the network interfaces you can use NAT for the Management network and a bridged one for the Internet/data network.

During the installation select "Basic Ubuntu server" and "SSH server".

A graphical environment is optional since most of the work will be carried out trough MobaXterm

## Network configuration

### Controller

- The controller node has two Network Interfaces: eth0 (used for management network) and eth1 is external.

___

Change to super user mode:

    sudo su

___

Set the hostname:

    vi /etc/hostname

    controller

___

Edit /etc/hosts:

    vi /etc/hosts

    #controller
    10.0.0.11       controller
    # compute1
    10.0.0.21       compute1

- Note:

Remove or comment the line beginning with 127.0.1.1.

___

Edit network settings to configure the interfaces eth0 and eth1:

    vi /etc/network/interfaces

    # The primary network interface
    auto eth0
    iface eth0 inet static
            address 10.0.0.11
            netmask 255.255.255.0
            gateway 10.0.0.1
            dns-nameserver 10.0.0.1

    # The public network interface
    auto eth1
    iface  eth1 inet manual
        up ip link set dev $IFACE up
        down ip link set dev $IFACE down


### Compute1

- The compute node has two Network Interfaces: eth0 (used for management network) and eth1 is external.

___

Change to super user mode:

    sudo su

___

Set the hostname:

    vi /etc/hostname

    compute1

___

Edit /etc/hosts:

    vi /etc/hosts

    #controller
    10.0.0.11       controller
    # compute1
    10.0.0.21       compute1

- Note:

Remove or comment the line beginning with 127.0.1.1.

___

Edit network settings to configure the interfaces eth0 and eth1:

    vi /etc/network/interfaces

    # The management network interface
    auto eth0
    iface eth0 inet static
            address 10.0.0.21
            netmask 255.255.255.0
            gateway 10.0.0.1
            dns-nameserver 10.0.0.1

    # The public network interface
    auto eth1
    iface  eth1 inet manual
      up ip link set dev $IFACE up
      down ip link set dev $IFACE down

# OpenStack environment details

The environment that is deployed here is the Liberty flavor with the following components:

- Dashboard - **Horizon** - Provides a web-based self-service portal to interact with underlying OpenStack services, such as launching an instance, assigning IP addresses and configuring access controls.

- Compute - **Nova** - Manages the lifecycle of compute instances in an OpenStack environment. Responsibilities include spawning, scheduling and decommissioning of virtual machines on demand.

- Networking - **Neutron** - Enables Network-Connectivity-as-a-Service for other OpenStack services, such as OpenStack Compute. Provides an API for users to define networks and the attachments into them. Has a pluggable architecture that supports many popular networking vendors and technologies.
 	 	
- Identity service - **Keystone** - Provides an authentication and authorization service for other OpenStack services. Provides a catalog of endpoints for all OpenStack services.

- Image service - **Glance** - Stores and retrieves virtual machine disk images. OpenStack Compute makes use of this during instance provisioning.
 + It is intended to add the _Murano_ package and the _App-catalog_ **(need some help for manually implementing them)**

## For the installation of the services presented above the following passwords were used:
- To ease the installation process, this guide only covers password security where applicable. You can create secure passwords manually, generate them using a tool such as [pwgen](http://sourceforge.net/projects/pwgen/), or by running the 

following command:

      openssl rand -hex 10

- If you wish to modify these passwords a script is provided (modconf.sh).

> Database password (no variable used) Root password for the database

> ADMIN_PASS	Password of user admin

> DASH_DBPASS	Database password for the dashboard

> DEMO_PASS	Password of user demo

> GLANCE_DBPASS	Database password for Image service

> GLANCE_PASS	Password of Image service user glance

> KEYSTONE_DBPASS	Database password of Identity service

> NEUTRON_DBPASS	Database password for the Networking service

> NEUTRON_PASS	Password of Networking service user neutron

> NOVA_DBPASS	Database password for Compute service

> NOVA_PASS	Password of Compute service user nova

> RABBIT_PASS	Password of user guest of RabbitMQ

> SERVICE_PASS Password for service tenant

>  SERVICE_DBPASS Password for service database

# OpenStack installation

## Controller node

Copy the required files:
___

Change to super user mode:

    sudo su

___

Make a new directory:

    mkdir Install

Navigate to it:

    cd Install/
___ 

- Just drag and drop from your OS in the MobaXterm interface like this:

![](http://s20.postimg.org/sx3gy6agt/moba_installl.png) 

Note: The required files are:

>1Controller.sh

>2Controller.sh

>2Compute.sh

>modconf.sh

>admin-openrc.sh

>demo-openrc.sh

>contoller-restart.sh

>instance_test.sh

>wsgi-keystone.conf   
              

___

Make all the files executable:

    chmod 755 *

___

Run the first script, after this script the VM will reboot. because it brings the OpenStack repo and upgrades the system.

    ./1Controller.sh

___


After reboot - Change to super user mode:

    sudo su

___ 

- At this point you can modify your installation regarding the IP addresses or the passwords by running the modification script 
:+1: 

    ./modconf.sh

Note: in the prompt you will be asked to input passwords for modules that are not installed like Ceilometer. You can skip those because the script is made for a more complete future installation.

___

After the modconf.sh finishes or if you choose to go with the settled passwords and IP you can continue by running the second script:

    ./2Controller

During the script you will be prompted to enter a password for **MariaDB**
** YOU MUST ENTER **stack** if you did not modify any passwords**  
The prompt is displayed bellow:

![](http://s20.postimg.org/t8kxaxqwt/Mysql_Pass.png)

Go have a beer! Come back in 10 minutes!
If everything goes well you should end up with this on your screen:

![](http://s20.postimg.org/h99f3mlbx/controller_output.png)

## Compute node
Copy the required files:
___

Change to super user mode:

    sudo su

___

Make a new directory:

    mkdir Install

Navigate to it:

    cd Install/
___ 

- Just drag and drop from your OS in the MobaXterm interface like this:

![](http://s20.postimg.org/sx3gy6agt/moba_installl.png) 

Note: The required files are:

>1Compute.sh

>2Compute.sh (if you modify the passwords or IP copy this from the compute node)

>compute-restart.sh

___

Make all the files executable:

    chmod 755 *

___

Run the first script, after this script the VM will reboot. because it brings the OpenStack repo and upgrades the system.

    ./1Compute.sh

___


After reboot - Change to super user mode:

    sudo su

___ 

 Run the second script:

    ./2Controller

Go have another beer! Come back in 10 minutes!
If everything goes well after the installation you should enter in the Controller node:

     nova service-list
     neutron agent-list

and end up with this:    

![](http://s20.postimg.org/6npjrmf0d/controller_final.png)

# Congratulation! 
- You now have an OpenStack environment to play with.
To access it enter in your browser:

>10.0.0.11/horizon

Note: If you modified the IP address for the management interface of the Controller please enter that IP.
If not you should end up with this:

![](http://s20.postimg.org/ie3h907st/openstack_login.png)


- The credentials if the environment was not modified are:

>admin
>>ADMIN_PASS

>demo
>>DEMO_PASS

Note:If you reboot your VM's in order to re-spring the cloud you must run:

>On the Controller

    ./controller-restart.sh

>On the Compute

    ./compute-restart.sh

# Test your new cloud!
To give the newly cloud a test-drive just run this:

    ./instance_test.sh

- At the prompt just enter the corresponding network configuration to the eth1 of your VM's

In my case are the following:

     Public network with cidr
         10.3.3.0/24
     Enter start IP address
         10.3.3.100
     Enter end IP address
         10.3.3.200
     Enter DNS 
         95.77.94.88
     Enter gateway
         10.3.3.1

- After the script finishes you can access the two instances from the console inside Horizon (make a PortFowarding rule for it on the NAT network in VMware)
- The public instace can also be accessed trough ssh from your pc.
- The credentials for the two instances are: cirros/cubswin:)

# This tutorial will be continued with:
- Configuring the network for internet access to the instances
- Adding Murano and App-Catalog **Need some help, if can, please DO!**
- Second Compute node
- Who knows maybe even PIZZA!

# Authors

Copyright (C)Eduard LUCHIAN : eduard.luchian@com.utcluj.ro

# References
- http://docs.openstack.org/liberty/install-guide-ubuntu/
- https://github.com/ChaimaGhribi/OpenStack-Juno-Installation
