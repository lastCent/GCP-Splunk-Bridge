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

variable gke_master_ip {
  description = "The IP address of the GKE master or a semicolon separated string of multiple IPs"
}

variable gke_node_tag {
  description = "The network tag for the gke nodes"
}

variable region {
  default = "europe-west1"
}

variable zone {
  default = "europe-west1-b"
}

variable network {
  default = "default"
}

provider google {
  region = "${var.region}"
}

module "nat" {
  source  = "GoogleCloudPlatform/nat-gateway/google"
  region     = "${var.region}"
  zone       = "${var.zone}"
  tags       = ["${var.gke_node_tag}"]
  network    = "${var.network}"
  subnetwork = "${var.network}"
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
}

output "ip-nat-gateway" {
  value = "${module.nat.external_ip}"
}
