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

// MODIFIED (slightly)


// Variables
// -----------------------------------------------------------------------------------------------
/* The IP of the master node, prevents breaking of node-master communication
 * Can be found using:
 * $(gcloud compute firewall-rules describe ${NODE_TAG/-node/-ssh} --format='value(sourceRanges)')
 */
variable gke_master_ip {
  description = "The IP address of the GKE master or a semicolon separated string of multiple IPs"
}

/* Determines which Google Compute instances will have their traffic sent through the NAT-Gateway
 * Use default value for manual tagging
 * Add tag using: gcloud compute instances add-tags [INSTANCE-NAME] --zone [ZONE] --tags [TAGS]
 * Use the output of:
 * $(gcloud compute instance-templates describe $(gcloud compute instance-templates list --filter=name~gke-${CLUSTER_NAME} --limit=1 --uri) --format='get(properties.tags.items[0])')
 * instead, in order to mark all nodes in cluster to be NAT-ed
 */
variable gke_node_tag {
  default = "Splunk-send-through-NAT-GW"
  description = "The network tag for the gke nodes"
}

variable region {
  default = "europe-west1"
}

variable zone {
  default = "europe-west1-b"
}

variable project {
  default = "pantel-2decb"
}

variable network {
  default = "splunk-fwd"
}

variable subnetwork {
  default = "splunk-simple-subnet"
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
    prefix = "nat-terraform/state"
  }
}


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
}

// Route so that traffic to the master goes through the default gateway.
// This fixes things like kubectl exec and logs
resource "google_compute_route" "gke-master-default-gw" {
  count            = "${var.gke_master_ip == "" ? 0 : length(split(";", var.gke_master_ip))}"
  name             = "${var.gke_node_tag}-master-default-gw-${count.index + 1}"
  dest_range       = "${element(split(";", replace(var.gke_master_ip, "/32", "")), count.index)}"
  network          = "${var.network}"
  next_hop_gateway = "default-internet-gateway"
  tags             = ["${var.gke_node_tag}"]
  priority         = 700
  project          = "${var.project}"
}

output "ip-nat-gateway" {
  value = "${module.nat.external_ip}"
}
