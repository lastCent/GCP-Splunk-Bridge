FROM splunk/splunk:latest

ENV SPLUNK_HOME /opt/splunk
ENV GCP_ADDON splunk-add-on-for-google-cloud-platform_120.tgz

# Install GCP addon, supplied in .tgz format
ADD splunk-add-on-for-google-cloud-platform_120.tgz ${SPLUNK_HOME}/etc/apps/

# Apply service account credentials preset file 
# Contains only a splunk stanza, secrets applied at launch
COPY google_cloud_credentials.conf ${SPLUNK_HOME}/etc/apps/Splunk_TA_google-cloudplatform/local/

# Configure Cloud Pub/Sub inputs
COPY inputs.conf ${SPLUNK_HOME}/etc/apps/Splunk_TA_google-cloudplatform/local/

# Transfer setup files, and make executable
COPY custom_launch.sh /etc/splunk_setup/
RUN chmod 755 /etc/splunk_setup/custom_launch.sh
COPY launch-setup.sh /etc/splunk_setup/
RUN chmod 755 /etc/splunk_setup/launch-setup.sh

# Set license to "Forwarder" and specify CA-cert
# This license is free, as long as no data is indexed locally
COPY server.conf ${SPLUNK_HOME}/etc/systen/local/

# Deploy output configuration
COPY outputs.conf ${SPLUNK_HOME}/etc/system/local/

# Insert custom panaceamvno index
COPY indexes.conf ${SPLUNK_HOME}/etc/system/local/

# Disable the first-time login prompt. Password for "admin" is set at deployment, check logs.
COPY .ui_login ${SPLUNK_HOME}/etc/

# Disable splunk web interface
COPY web.conf ${SPLUNK_HOME}/etc/system/local/

# Override parent entrypoint and add runtime secret import
ENTRYPOINT ["/etc/splunk_setup/custom_launch.sh"]


