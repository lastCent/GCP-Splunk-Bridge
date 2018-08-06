#!/bin/sh

echo "Starting service account secret import from mounted volume."

# Transfer service account secret from volume to designated Splunk location and format
# This is a workaround
# Forgive me
echo -n 'google_credentials = ' >> ${SPLUNK_HOME}/etc/apps/Splunk_TA_google-cloudplatform/local/google_cloud_credentials.conf && 
cat /etc/gcp_credentials/credentials.json | tr -d '\n' >> ${SPLUNK_HOME}/etc/apps/Splunk_TA_google-cloudplatform/local/google_cloud_credentials.conf 
echo "Service account secret import complete." 

# Override default admin password with a secure, randomly generated one. Remember to save it,
# and that this password is in your logs!
# For optimal security, mount the host machine /dev/[u]random to guest /dev/urandom for this
tempPassword=$(dd if=/dev/urandom bs=32 count=1 2> /dev/null | md5sum | cut -b 1-27)
echo  "The new admin password is: ${tempPassword}"
echo "[user_info]\nUSERNAME=admin\nPASSWORD=${tempPassword}" > ${SPLUNK_HOME}/etc/system/local/user-seed.conf
unset tempPassword

# Secrets for the connection to the Splunk receiver are used directly from mounted volumes.
exit 0
