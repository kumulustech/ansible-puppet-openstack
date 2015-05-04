#!/bin/bash
set -x
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

if [ "${region}" = "east" ]; then
 export OS_REGION_NAME="region-a.geo-1"
else
 export OS_REGION_NAME="region-b.geo-1"
fi
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
neutron security-group-rule-create default --direction ingress --protocol tcp --port-range-min 22 --port-range-max 22 --remote-ip-prefix 0.0.0.0/0
neutron security-group-rule-create default --direction ingress --protocol tcp --port-range-min 80 --port-range-max 80 --remote-ip-prefix 0.0.0.0/0
neutron security-group-rule-create default --direction ingress --protocol tcp --port-range-min 443 --port-range-max 443 --remote-ip-prefix 0.0.0.0/0
neutron security-group-rule-create default --direction ingress --protocol tcp --port-range-min 3306 --port-range-max 3306 --remote-ip-prefix 0.0.0.0/0
neutron security-group-rule-create default --direction ingress --protocol icmp --port-range-min 1 --port-range-max 1 --remote-ip-prefix 0.0.0.0/0

if [[ -z ${FLOAT_ONE} || -z ${FLOAT_TWO}  ]]; then
 if [ `neutron floatingip-list | grep -v grep -v "+\|id" | wc -l` -le 0 ]; then
  float_one=$(neutron floatingip-create Ext-Net | awk '/ floating_ip_address / {print $4}')
  float_one_id=$(neutron floatingip-list | awk "/ ${float_one} / {print \$2}")

  float_two=$(neutron floatingip-create Ext-Net | awk '/ floating_ip_address / {print $4}')
  float_two_id=$(neutron floatingip-list | awk "/ ${float_two} / {print \$2}")
 fi
elif [[ -n "${FLOAT_ONE}" && -n "${FLOAT_TWO}"  ]] ; then
  float_one=${FLOAT_ONE}
  float_two=${FLOAT_TWO}
  float_one_id=$(neutron floatingip-list | awk "/ ${FLOAT_ONE} / {print \$2}")
  float_two_id=$(neutron floatingip-list | awk "/ ${FLOAT_TWO} / {print \$2}")
else
  echo "Seems you only have on Floating IP defined: One: ${FLOAT_ONE} or Two: ${FLOAT_TWO}"
  echo "Please set to appropraite values and re-run"
fi


nova boot --image ${image} --flavor standard.small --nic net-id=${private},v4-fixed-ip=10.0.0.10 --key-name rhs --poll node1
nova boot --image ${image} --flavor standard.small --nic net-id=${private},v4-fixed-ip=10.0.0.11 --key-name rhs --poll node2

# Allocate Floating IPs:
node1_priv=$(nova show node1 | awk '/ private network / {print $5}')
node2_priv=$(nova show node2 | awk '/ private network / {print $5}')

nova floating-ip-associate node1 ${float_one} --fixed-address ${node1_priv}
nova floating-ip-associate node2 ${float_two} --fixed-address ${node2_priv}

if [ "${region}" = "east" ]; then
	inventory="inventory-east"
else
	inventory="inventory-west"
fi

cat > ${inventory} <<EOF
[openstack]
${float_one} remote_name=node2 remote_addr=${node2_priv}
${float_two} remote_name=node1 remote_addr=${node1_priv}
EOF

OIFS=$IFS
IFS='.'
ip=($node1_priv)
IFS=$OIFS
priv_net=${ip[0]}.${ip[1]}.${ip[2]}."%"

cat > nodefiles/${float_one}.fact <<EOF
[management]
controller=${node1_priv}
storage=${node1_priv}
allowedhosts=${priv_net}

[neutron]
private=192.168.0/24

[api]
controller=${node1_priv}
storage=${node1_priv}

[external]
poolstart=10.10.30.100
poolend=10.10.30.200
gateway=10.10.30.1
dns=8.8.8.8

[replica]
remote=${node2_priv}
remoteip=${float_two}
EOF

cat > nodefiles/${float_two}.fact <<EOF
[management]
controller=${node2_priv}
storage=${node2_priv}
allowedhosts=${priv_net}

[neutron]
private=192.168.0/24

[api]
controller=${node2_priv}
storage=${node2_priv}

[external]
poolstart=10.10.30.100
poolend=10.10.30.200
gateway=10.10.30.1
dns=8.8.8.8

[replica]
remote=${node1_priv}
remoteip=${float_one}
EOF

# Now let's ansibleize these machines:
# First a couple preparatory steps...
ansible-playbook -i ${nventory} -u centos run.yml

# Now let's get OpenStack running

