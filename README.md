Use ansible to setup and deploy puppet

Install iptools python package:
pip install iptools

Install ansible python package:
pip install ansible

Add maskconvert filter:
cat >> /usr/lib/python2.7/ansible/runner/filter_plugins/core.py <<EOF
from iptools.ipv4 import *

def maskconvert(mask):
        return netmask2prefix(mask)
EOF

sed -e '/utils.unicode/i from iptools.ipv4 import netmask2prefix' -i \
/usr/lib/python2.7/site-packages/ansible/runner/filter_plugins/core.py

sed -e '/netmask2prefix/i \
def maskconvert(mask):\
    return netmask2prefix(mask)\
' -i \
/usr/lib/python2.7/site-packages/ansible/runner/filter_plugins/core.py

sed -e "/: randomize_list,/i \'maskconvert\': maskconvert" -i \
/usr/lib/python2.7/site-packages/ansible/runner/filter_plugins/core.py

