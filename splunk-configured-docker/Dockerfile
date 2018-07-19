FROM splunk/splunk:latest

ENV SPLUNK_HOME /opt/splunk
ENV GCP_ADDON splunk-add-on-for-google-cloud-platform_120.tgz

# Deploy output configuration
#COPY outputs.conf ${SPLUNK_HOME}/etc/system/local/outputs.conf

# Install GCP addon, supplied in .tgz format
ADD splunk-add-on-for-google-cloud-platform_120.tgz ${SPLUNK_HOME}/etc/apps/

# Apply service account credentials
COPY google_cloud_credentials.conf ${SPLUNK_HOME}/etc/apps/Splunk_TA_google-cloudplatform/local/

# Configure Cloud Pub/Sub inputs
COPY inputs.conf ${SPLUNK_HOME}/etc/apps/Splunk_TA_google-cloudplatform/local/

# Enable these before release: 

# Configure Cloud Monitoring inputs
#COPY google_cloud_monitor_inputs.conf ${SPLUNK_HOME}/etc/apps/Splunk_TA_google-cloudplatform/local/

# Disable splunk web interface
#COPY web.conf ${SPLUNK_HOME}/etc/system/local/

# -------------------------------------- DEBUG ----------------------------------------------------

# Install curl to check that the nat-ed IP is correct
RUN apt-get update
RUN apt-get install -y curl

