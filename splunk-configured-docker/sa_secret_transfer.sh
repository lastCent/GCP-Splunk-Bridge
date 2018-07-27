#!/bin/sh
# Transfer service account secret from volume to designated Splunk location and format
# This is a workaround
# Forgive me

echo "Starting service account secret import from mounted volume."

echo -n 'google_credentials = ' >> ${SPLUNK_HOME}/etc/apps/Splunk_TA_google-cloudplatform/local/google_cloud_credentials.conf && 
cat /etc/gcp_credentials/credentials.json | tr -d '\n' >> ${SPLUNK_HOME}/etc/apps/Splunk_TA_google-cloudplatform/local/google_cloud_credentials.conf 


echo "Service account secret import complete." 
exit 0
