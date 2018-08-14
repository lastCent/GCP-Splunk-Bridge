/* An isolated VPC network for a Splunk forwarder.
 * Note: By using a non-default network it will no longer be possible to keep the forwarder
 * in the same cluster as other resources. 
 */

variable region {
  description = "The region where the network will reside."
}

variable zone {
  description = "The zone where the network will reside."
}

variable project {
  description = "The full name of the GCP project where the forwarder will be deployed."
}

variable network {
  description = "The name of the forwarder's isolated VPC network."
}

variable subnetwork {
  description = "The name of the forwarder's subnetwork."
}

variable subnet_cidr_range {
  description = "The CIDR IP range available for entities on the forwarder's subnet."
}

variable cluster_name {
  description = "The name of the forwarder's kubernetes cluster."
}

variable gke_node_tag {
  description = "The network tag of the nodes that will have their traffic sent through the NAT-gateway."
}

variable node_count {
  description = "The number of nodes in the forwarder's kubernetes cluster."
}

provider google {
  region = "${var.region}"
}

// Backend - Location of remote state
// --------------------------------------------------------------------------------------------------
//terraform {
//  backend "gcs" {
//    bucket = "tortoise-hull-hyujdmkj3d"
//    prefix = "network-terraform/state"
//  }
//}

// The network and subnetwork
// --------------------------------------------------------------------------------------------------
resource "google_compute_network" "splunk-fwd-network" {
  name = "${var.network}"
  project = "${var.project}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "minimal-network" {
  name = "${var.subnetwork}"
  ip_cidr_range = "${var.subnet_cidr_range}"
  region = "${var.region}"
  network = "${google_compute_network.splunk-fwd-network.self_link}"
  enable_flow_logs = "true"
  project = "${var.project}"
  depends_on = ["google_compute_network.splunk-fwd-network"]
}

// The Kubernetes cluster
// --------------------------------------------------------------------------------------------------
resource "google_container_cluster" "splunk-fwd" {
  name = "${var.cluster_name}"
  zone = "${var.zone}"
  project = "${var.project}"
  network = "${google_compute_network.splunk-fwd-network.self_link}"
  subnetwork = "${google_compute_subnetwork.minimal-network.self_link}"
  initial_node_count = "${var.node_count}"
  node_config {
    tags = ["${var.gke_node_tag}"]
  }
  depends_on = ["google_compute_subnetwork.minimal-network"]
}

output "kubernetes_master_node" {
  value = "${google_container_cluster.splunk-fwd.endpoint}"
}

