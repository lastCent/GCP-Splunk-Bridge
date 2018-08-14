/*
 * Copyright 2017 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * MODIFIED (slightly)
 */ 

// Variables
// -----------------------------------------------------------------------------------------------

variable gke_master_ip {
  /* The IP of the master node, prevents breaking of node-master communication
   * Can be found using:
   * $(gcloud compute firewall-rules describe ${NODE_TAG/-node/-ssh} --format='value(sourceRanges)')
   */
  description = "The IP address of the GKE master or a semicolon separated string of multiple IPs."
}

variable gke_node_tag {
  /* Determines which Google Compute instances will have their traffic sent through the NAT-Gateway
   * Set a default value for manual tagging. 
   * Add tag using: gcloud compute instances add-tags [INSTANCE-NAME] --zone [ZONE] --tags [TAGS]
   * Or, use the output of:
   * $(gcloud compute instance-templates describe $(gcloud compute instance-templates list --filter=name~gke-${CLUSTER_NAME} --limit=1 --uri) --format='get(properties.tags.items[0])')
   * instead, in order to mark all nodes in cluster to be NAT-ed
   */
  description = "The network tag of the nodes that will have their traffic sent through the NAT-gateway."
}

variable region {
  description = "The region where the forwarder will reside."
}

variable zone {
  description = "The zone where the forwarder will reside."
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

provider google {
  region = "${var.region}"
}

// Backend - Location of remote state 
// --------------------------------------------------------------------------------------------------
//terraform {
//  backend "gcs" {
//    bucket = "tortoise-hull-hyujdmkj3d"
//    prefix = "nat-terraform/state"
//  }
//}


// Nat Gateway and routing 
// --------------------------------------------------------------------------------------------------
module "nat" {
  source  = "GoogleCloudPlatform/nat-gateway/google"
  region     = "${var.region}"
  zone       = "${var.zone}"
  tags       = ["${var.gke_node_tag}"]
  network    = "${var.network}"
  subnetwork = "${var.subnetwork}"
  project = "${var.project}"
  ip_address_name = "splunk-forwarder-adr"
}

// Route so that traffic to the master goes through the default gateway.
// This fixes things like kubectl exec and logs
resource "google_compute_route" "gke-master-default-gw" {
  //count            = "${var.gke_master_ip == "" ? 0 : length(split(";", var.gke_master_ip))}"
  //name             = "${var.gke_node_tag}-master-default-gw-${count.index + 1}"
  //dest_range       = "${element(split(";", replace(var.gke_master_ip, "/32", "")), count.index)}"
  name             = "${var.gke_node_tag}-master-default-gw-1"
  dest_range       =  "${var.gke_master_ip}"
  network          = "${var.network}"
  next_hop_gateway = "default-internet-gateway"
  tags             = ["${var.gke_node_tag}"]
  priority         = 700
  project          = "${var.project}"
}

output "ip-nat-gateway" {
  value = "${module.nat.external_ip}"
}
