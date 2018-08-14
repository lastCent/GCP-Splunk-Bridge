// Creates kubernetes secrets which contain the Splunk certs. 
// Use with care, secrets inside!

// Variables
// -----------------------------------------------------------------
variable region {
  description = "The region where the forwarder will reside."
}

variable project {
  description = "The full name of the GCP project where the forwarder will be deployed."
}

provider google {
  region = "${var.region}"
}

// Backend - Location of remote state
// -----------------------------------------------------------------
//terraform {
//  backend "gcs" {
//    bucket = "tortoise-hull-hyujdmkj3d"
//    prefix = "certs-terraform/state"
//  }
//}

// Splunk certificate kubernetes secrets 
// -------------------------------------------------------------------
resource "kubernetes_secret" "splunk-ca" {
  metadata {
    name = "splunk-ca-cert"
  } 
  type = "Opaque"
  data {
    CA-splunk.telenor.net.pem = "${file("${path.module}/ca/CA-splunk.telenor.net.pem")}"
  }
}

resource "kubernetes_secret" "certs" {
  metadata {
    name = "panaceamvno-redotter-sg-certs"
  }
  type = "Opaque"
  data {
    panaceamvno.redotter.sg.csr = "${file("${path.module}/certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.csr")}"
    panaceamvno.redotter.sg.pem = "${file("${path.module}/certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.pem")}"
    panaceamvno.redotter.sg.key = "${file("${path.module}/certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.key")}"
  }
}

