/* The whole GCP_Splunk-bridge, contained inside a Terraform.
 * Remember to set up the bucket before deploying this. 
 * Variables without default values can be set in the terraform.tfvars file
 */

/* Variables
 * ----------------------------------------------------------------------------
 */

// General
variable region {
  description = "The region where the forwarder will reside."
}

variable zone {
  description = "The zone where the forwarder will reside."
}

variable project {
  description = "The full name of the GCP project where the forwarder will be deployed."
}

variable bucket_name {
  description = "The bucket where the tf-states and certificates are stored. Remember to set this manually in the backend as well."
}

// Pubsub setup
variable sink_name {
  description = "The name of the sink which wil export the logs from Stackdriver Logging."
  default = "splunk-sink"
}

variable topicName {
  default = "splunk-logging"
  description = "The GCP pubsub topic's name."
}

variable subscriptionName {
  default = "splunk-sub"
  description = "The name of the subscription to the logging pubsub topic."
}

variable gke_node_tag {
  default = "send-through-nat"
  description = "The network tag of the nodes that will have their traffic sent through the NAT-gateway."
}

// Network
variable network {
  default = "splunk-fwd"
  description = "The name of the forwarder's isolated VPC network."
}

variable subnetwork {
  default = "splunk-simple-subnet"
  description = "The name of the forwarder's subnetwork."
}

variable subnet_cidr_range {
  description = "The CIDR IP range available for entities on the forwarder's subnet."
  default = "10.10.0.0/24"
}

variable cluster_name {
  description = "The name of the forwarder's kubernetes cluster."
  default = "splunk-fw-isolated"
}

variable node_count {
  description = "The number of nodes in the forwarder's kubernetes cluster."
  default = 1
}

  
/* Provider
 * ----------------------------------------------------------------------------
 */

provider google {
  region = "${var.region}"
}

/* Backend - Location of the remote state
 * ----------------------------------------------------------------------------
 */

terraform {
  backend "gcs" {
    bucket = "tortoise-hull-hyujdmkj3d"
    prefix = "bridge-terraform/state"
  }
}

/* Network module
 * ----------------------------------------------------------------------------
 */

module "network" {
  source = "./modules/network-terraform"
  region = "${var.region}"
  zone = "${var.zone}"
  project = "${var.project}"
  network = "${var.network}"
  subnetwork = "${var.subnetwork}"
  subnet_cidr_range = "${var.subnet_cidr_range}"
  cluster_name = "${var.cluster_name}"
  gke_node_tag = "${var.gke_node_tag}"
  node_count = "${var.node_count}"
}

/* PubSub module
 * ----------------------------------------------------------------------------
 */

module "pubsub" {
  source = "./modules/pubsub-terraform"
  region = "${var.region}"
  project = "${var.project}"
  sink_name = "${var.sink_name}"
  topicName = "${var.topicName}"
  subscriptionName = "${var.subscriptionName}"
  bucket_name = "${var.bucket_name}"
}

/* Secrets module
 * ----------------------------------------------------------------------------
 */

module "secrets" {
  source = "./modules/certs-terraform"
  region = "${var.region}"
  project = "${var.project}"
}  

/* NAT module
 * ----------------------------------------------------------------------------
 */

module "nat-gw" {
  source = "./modules/nat-terraform"
  region = "${var.region}"
  zone = "${var.zone}"
  project = "${var.project}"
  network = "${var.network}"
  subnetwork = "${var.subnetwork}"
  gke_master_ip = "${module.network.kubernetes_master_node}"
  gke_node_tag = "${var.gke_node_tag}"
}

output "master-node-ip" {
  value = "${module.network.kubernetes_master_node}"
}

output "nat-gw-ip" {
  value = "${module.nat-gw.ip-nat-gateway}"
}
