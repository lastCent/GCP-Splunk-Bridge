/* Disclaimer:
 * This terraform is meant as an example of how to set up the Splunk-forwarder bucket.
 * It can't have a remote state on the bucket it creates. => No (easy) state sharing
 * Use it as an example, or as a "deploy once and be done with it thing". 
 * Remember: This terraform handles secrets, be careful!
 * TODO: Make this applicable in single terraform-apply (currently 2 required)
 */

// Variables
// -----------------------------------------------------------------
variable region {
  description = "The region where the bucket will reside."
}

variable project {
  description = "The full name of the GCP project where the forwarder will be deployed."
}

variable bucket_name {
  description = "The name of the bucket that will be created."
}

variable bucket_admin {
  description = "Used to restrict access to minimum number of people"
}

provider google {
  region = "${var.region}"
}

// Bucket and permissions
// -----------------------------------------------------------------
resource "google_storage_bucket" "splunk-store" {
  name = "${var.bucket_name}"
  location = "${var.region}"
  project = "${var.project}"
  force_destroy = "true"

  website {
    main_page_suffix = "index.html"
    not_found_page = "404.html"
  }
}

resource "google_storage_bucket_acl" "splunk-store-restrict" {
  bucket = "${google_storage_bucket.splunk-store.name}"
  predefined_acl = "private"
  depends_on = [
    "google_storage_bucket.splunk-store"
  ]
}

data "google_iam_policy" "sole-owner-policy" {
  binding {
    role = "roles/storage.admin"
    members = ["user:${var.bucket_admin}"]
  }
}

resource "google_storage_bucket_iam_policy" "sole-owner" {
  bucket = "${google_storage_bucket.splunk-store.name}"
  policy_data = "${data.google_iam_policy.sole-owner-policy.policy_data}"
  depends_on = [
    "google_storage_bucket.splunk-store", 
    "data.google_iam_policy.sole-owner-policy"
  ]
}

output "bucket-link" {
  value = "${google_storage_bucket.splunk-store.url}"
}

// Secrets as files in bucket
// -------------------------------------------------------------------
resource "google_storage_bucket_object" "ca-cert" {
  name = "ca/CA-splunk.telenor.net.pem"
  source = "${path.module}/ca/CA-splunk.telenor.net.pem"
  bucket = "${var.bucket_name}"
  depends_on=["google_storage_bucket.splunk-store", "google_storage_bucket_iam_policy.sole-owner" ]
}

resource "google_storage_bucket_object" "client-csr" {
  name = "certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.csr"
  source = "${path.module}/certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.csr"
  bucket = "${var.bucket_name}"
  depends_on=["google_storage_bucket.splunk-store", "google_storage_bucket_iam_policy.sole-owner" ]
}

resource "google_storage_bucket_object" "client-key" {
  name = "certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.key"
  source = "${path.module}/certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.key"
  bucket = "${var.bucket_name}"
  depends_on=["google_storage_bucket.splunk-store", "google_storage_bucket_iam_policy.sole-owner" ]
}

resource "google_storage_bucket_object" "client-pem" {
  name = "certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.pem"
  source = "${path.module}/certs/panaceamvno.redotter.sg/panaceamvno.redotter.sg.pem"
  bucket = "${var.bucket_name}"
  depends_on=["google_storage_bucket.splunk-store", "google_storage_bucket_iam_policy.sole-owner" ]
}
