/* Disclaimer:
 * This terraform is meant as an example of how to set up the Splunk-forwarder bucket.
 * It can't have a remote state on the bucket it creates. => No (easy) state sharing
 * Use it as an example, or as a "deploy once and be done with it thing". 
 * TODO: Make this applicable in single terraform-apply (currently 2 required)
 */

// Variables
// -----------------------------------------------------------------
variable region {
  default = "europe-west1"
}

variable project {
  default = "pantel-2decb"
}

variable bucket_name {
  default = "tortoise-hull-hyujdmkj3d"
}

variable bucket_admin {
  description = "Used to restrict access to minimum number of people"
  default = "richard.bachmann@telenordigital.com"
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

