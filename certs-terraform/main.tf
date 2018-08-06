// WARNING: This terraform assumes that the used bucket has very restricted access.
// Use with care, secrets inside!

// Variables
// -----------------------------------------------------------------
variable region {
  default = "europe-west1"
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
// -----------------------------------------------------------------
terraform {
  backend "gcs" {
    bucket = "tortoise-hull-hyujdmkj3d"
    prefix = "certs-terraform/state"
  }
}

// Secrets as files in bucket
// -------------------------------------------------------------------
resource "google_storage_bucket_object" "ca-cert" {
  name = "ca/CA-splunk.telenor.net.pem"
  source = "${path.module}/ca/CA-splunk.telenor.net.pem"
  bucket = "${var.bucket_name}"
}

resource "google_storage_bucket_object" "client-csr" {
  name = "certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.csr"
  source = "${path.module}/certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.csr"
  bucket = "${var.bucket_name}"
}

resource "google_storage_bucket_object" "client-key" {
  name = "certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.key"
  source = "${path.module}/certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.key"
  bucket = "${var.bucket_name}"
}

resource "google_storage_bucket_object" "client-pem" {
  name = "certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.pem"
  source = "${path.module}/certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.pem"
  bucket = "${var.bucket_name}"
}

// Splunk certificate kubernetes secrets 
// -------------------------------------------------------------------
resource "kubernetes_secret" "splunk-ca" {
  metadata {
    name = "splunk-ca-cert"
  } 
  data {
    CA-splunk.telenor.net.pem = "${file("${path.module}/ca/CA-splunk.telenor.net.pem")}"
  }
}

resource "kubernetes_secret" "certs" {
  metadata {
    name = "panaceamvno-redotter-sg-certs"
  }
  data {
    panaceamvno.redotter.sg.csr = "${file("${path.module}/certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.csr")}"
    panaceamvno.redotter.sg.pem = "${file("${path.module}/certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.pem")}"
    panaceamvno.redotter.sg.key = "${file("${path.module}/certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.key")}"
  }
}

