# GCP\_Splunk\_bridge

## Description
A Splunk forwarder, ready to transfer logs from Google Stackdriver Logging to a receiving Splunk network.

## Disclaimer:
This is a prototype, made by an intern. Some things are probably hacky, misconfigured, and hacky. 

## Prerequisites
* Helm
* Terraform 
* Gcloud and kubectl 
* Splunk Enterprise certificates 

## Usage
1. Deploy a Storage Bucket for the certs and the .tfstate files. Do this manually, or using the example bucket-terraform. Remember to edit the terraform.tfvars file. 
2. Move the splunk-certs to bridge-terraform/ and apply it in two steps: 
```
terraform apply -target=module.network
gcloud container clusters get-credentials splunk-fw-isolated
terraform apply
```
3. Download the latest version of the GCP Addon for Splunk to splunk-configured-docker, an add the destination IP-addresses (comma separated) to outputs.conf. Then build the docker image and upload it to the Google Cloud Container registry: 
``` 
sudo docker build -t gcr.io/PROJECT-NAME/splunk
sudo docker push gcr.io/PROJECT-NAME/splunk
```
4. Install Tiller on the cluster:
```
kubectl create serviceaccount -n kube-system
kubectl create clusterrolebinding tiller-binding --clusterrole=cluster-admin --serviceaccount kube-system:tiller
helm init --service-account tiller
```
5. Deploy the Forwarder on the cluster:
``` 
helm package splunk-hf
helm install --name splunk-latest splunk-hf-0.1.0.tgz
```
6. Activate the Forwarder license: 
```
kubectl exec -it POD-NAME -- /bin/bash
${SPLUNK_HOME}/bin/splunk edit licenser-groups Forwarder -is_active 1

```
7. Confirm that the forwarder has established a connection
```
kubectl exec -it POD-NAME -- /bin/bash
cat $SPLUNK_HOME/var/log/splunk/splunkd.log
cat $SPLUNK_HOME/var/log/splunk/metrics.log
``` 
## Architecture
![Architecture](misc/Architecture-v1.6.png)

## Troubleshooting

### The Forwarder is stuck in a pending state
Make sure the pubsub setup has been applied correctly. GCP pods will wait indefinitely if a required resource, such as a secret, is missing. 
