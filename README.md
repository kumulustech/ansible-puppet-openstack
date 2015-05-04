Use ansible to setup and deploy puppet

Install iptools python package:
pip install iptools

Install ansible python package (or upgrade):
pip install ansible --upgrade

Add maskconvert filter in:
/usr/lib/python2.7/ansible/runner/filter_plugins/core.py
  # it may be in /usr/local/lib. or python2.6

from iptools.ipv4 import *

after the UUID declaration add:

def maskconvert(mask):
        return netmask2prefix(mask)

in the 'def filters(self)' section at the end of the file, add the following:

'maskconvert': maskconvert,

