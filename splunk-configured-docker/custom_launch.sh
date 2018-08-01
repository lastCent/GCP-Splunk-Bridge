#!/bin/sh

echo "Starting custom Splunk Enterprise launch:"

# Normal Splunk launch, inherited from Splunk Docker image
/sbin/entrypoint.sh start-service & 
# Automatic secret import
/etc/splunk_setup/sa_secret_transfer.sh &
# Give Splunk admin account a random password
dd if=/dev/urandom bs=32 count=1 2> /dev/null | md5sum | cut -b 1-32 >> ${SPLUNK_HOME}/etc/system/local/user-seed.conf &
wait

echo "Custom server launch complete"
exit 0


# Reasoning for secret transfer:
# Mounted volumes are for security reasons readonly https://github.com/coreos/bugs/issues/2384
# Splunk can't access them
# Therefore secrets are fetched from separate volume after pod launch

