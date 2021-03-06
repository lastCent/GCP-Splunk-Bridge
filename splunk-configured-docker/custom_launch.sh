#!/bin/sh

echo "Starting custom Splunk Enterprise launch:"

# Normal Splunk launch, inherited from Splunk Docker image
/sbin/entrypoint.sh start-service & 
# Automatic secret import
/etc/splunk_setup/launch-setup.sh &
wait

exit 0


# Reasoning for secret transfer:
# Mounted volumes are for security reasons readonly https://github.com/coreos/bugs/issues/2384
# Splunk can't access them
# Therefore secrets are fetched from separate volume after pod launch

