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
COPY sa_secret_transfer.sh /etc/splunk_setup/
RUN chmod 755 /etc/splunk_setup/sa_secret_transfer.sh

# Set license to "Forwarder" and specify CA-cert
# This license is free, as long as no data is indexed locally
# TODO: readd [license] active_group = Forwarder
COPY server.conf ${SPLUNK_HOME}/etc/systen/local/

# Deploy output configuration
COPY outputs.conf ${SPLUNK_HOME}/etc/system/local/outputs.conf

# Insert Splunk user account file. Random password for "admin" is generated at launch. 
#COPY user-seed.conf ${SPLUNK_HOME}/etc/system/local/
 
# Override parent entrypoint and add runtime secret import
ENTRYPOINT ["/etc/splunk_setup/custom_launch.sh"]

# Enable these before release: 

# Configure Cloud Monitoring inputs ?
#COPY google_cloud_monitor_inputs.conf ${SPLUNK_HOME}/etc/apps/Splunk_TA_google-cloudplatform/local/

# Disable splunk web interface
#COPY web.conf ${SPLUNK_HOME}/etc/system/local/

# -------------------------------------- DEBUG ----------------------------------------------------

# Install curl to check that the nat-ed IP is correct
#RUN apt-get update
#RUN apt-get install -y curl

