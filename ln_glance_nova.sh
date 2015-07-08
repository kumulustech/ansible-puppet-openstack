#!/bin/bash

cd /var/lib
mv glance glance.orig
ln -s /mnt/storage-pool/glance glance
#mv nova nova.orig
#ln -s /mnt/storage-pool/nova nova
#rm -rf nova.orig glance.orig

rm /mnt/storage-pool/migrated
