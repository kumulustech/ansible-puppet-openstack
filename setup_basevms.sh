#!/bin/bash

# Launch VMs for OpenStack Development

#Networks:
# eth0 management
# eth1 api
# eth2 data
# eth3 external

# Model A: Libvirt
# Model B: OpenStack "UnderCloud"

## Model B:
#
# Credentials for UnderCloud:
export OS_AUTH_URL=https://region-a.geo-1.identity.hpcloudsvc.com:35357/v2.0/
export OS_TENANT_ID=10195846978052
export OS_TENANT_NAME="10032560941299-Project"
export OS_USERNAME="rstarmer"
export OS_REGION_NAME="region-b.geo-1"
# Still need a password, so if it's not already set, ask for it:

if [ ! ${OS_PASSWORD} ];then 
	echo "Please enter your OpenStack Password: "
    read -sr OS_PASSWORD_INPUT
    export OS_PASSWORD=$OS_PASSWORD_INPUT
fi

# Get some parameters and system ids:
#
# Network
private=`neutron net-list | awk '/ private / {print $2}' | head -1`
echo "Private Network ID: ${private}"
# Image
image=`glance image-list | awk '/ CentOS 7 x86_64 / {print $2}' | head -1`
echo "Image ID: ${image}"

# Set secuirty groups for 22,80,443,and ping
neutron security-group-rule-create default --direction ingress --protocol tcp --port-range-min 22 --port-range-max 22
neutron security-group-rule-create default --direction ingress --protocol tcp --port-range-min 80 --port-range-max 80
neutron security-group-rule-create default --direction ingress --protocol tcp --port-range-min 443 --port-range-max 443
neutron security-group-rule-create default --direction ingress --protocol tcp --port-range-min 3306 --port-range-max 3306
neutron security-group-rule-create default --direction ingress --protocol icmp --port-range-min 1 --port-range-max 1

if [ `neutron floatingip-list | grep -v '' | wc -l` -le 0 ]; then
  float_one=$(neutron floatingip-create Ext-Net | awk '/ floating_ip_address / {print $4}')
  float_one_id=$(neutron floatingip-list | awk "/ ${float_one} / {print \$2}")

  float_two=$(neutron floatingip-create Ext-Net | awk '/ floating_ip_address / {print $4}')
  float_two_id=$(neutron floatingip-list | awk "/ ${float_two} / {print \$2}")
elif [ -z ${FLOAT_ONE} || -z ${FLOAT_TWO}  ]; then
  echo "You must provide the pre-defined floating_ip addresses"
  exit 1
else
  float_one=${FLOAT_ONE}
  float_two=${FLOAT_TWO}
  float_one_id=$(neutron floatingip-list | awk "/ ${FLOAT_ONE} / {print \$2}")
  float_two_id=$(neutron floatingip-list | awk "/ ${FLOAT_TWO} / {print \$2}")
fi


nova boot --image ${image} --flavor standard.small --nic net-id=${private} --key-name rhs --poll node1
nova boot --image ${image} --flavor standard.small --nic net-id=${private} --key-name rhs --poll node2

# Allocate Floating IPs:
node1_priv=$(nova show node1 | awk '/ private network / {print $5}')
node2_priv=$(nova show node2 | awk '/ private network / {print $5}')

nova floating-ip-associate node1 ${float_one} --fixed-address ${node1_priv}
nova floating-ip-associate node2 ${float_two} --fixed-address ${node2_priv}





