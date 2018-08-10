/* An isolated VPC network for a Splunk forwarder.
 * Note: By using a non-default network it will no longer be possible to keep the forwarder
 * in the same cluster as other resources. 
 */



variable region {
  default = "europe-west1"
}

variable zone {
  default = "europe-west1-b"
}

variable project {
  default = "pantel-2decb"
}

variable bucket_name {
  description = "Must be set manually in backend as well"
  default = "tortoise-hull-hyujdmkj3d"
}

provider google {
  region = "${var.region}"
}

// Backend - Location of remote state
// --------------------------------------------------------------------------------------------------
terraform {
  backend "gcs" {
    bucket = "tortoise-hull-hyujdmkj3d"
    prefix = "network-terraform/state"
  }
}

// The network and subnetwork
// --------------------------------------------------------------------------------------------------
resource "google_compute_network" "splunk-fwd-network" {
  name = "splunk-fwd"
  project = "${var.project}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "minimal-network" {
  name = "splunk-simple-subnet"
  ip_cidr_range = "10.10.0.0/24"
  region = "${var.region}"
  network = "${google_compute_network.splunk-fwd-network.self_link}"
  enable_flow_logs = "true"
  project = "${var.project}"
  depends_on = ["google_compute_network.splunk-fwd-network"]
}

// The Kubernetes cluster
// --------------------------------------------------------------------------------------------------
resource "google_container_cluster" "splunk-tf-test" {
  name = "splunk-fw-isolated"
  zone = "${var.zone}"
  project = "${var.project}"
  network = "${google_compute_network.splunk-fwd-network.self_link}"
  subnetwork = "${google_compute_subnetwork.minimal-network.self_link}"
  initial_node_count = 1
  depends_on = ["google_compute_subnetwork.minimal-network"]
}

