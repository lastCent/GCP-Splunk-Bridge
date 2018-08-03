/* Terraform for the GCP pubsub setup.
 * This setup will transfer logs from stackdriver
 * and let them end up in the Splunk forwarder.
 */

variable region {
  default = "europe-west1"
}

variable project {
  default = "pantel-2decb"
}

variable topicName {
  default = "splunk-logging"
  description = "The GCP pubsub topic's name"
}

variable subscriptionName {
  default = "splunk-sub"
  description = "The name of the subscription to the logging topic"
}

variable bucket_name {
  description = "Must be set manually in backend as well"
  default = "tortoise-hull-hyujdmkj3d"
}

provider google {
  region = "${var.region}"
}

terraform {
  backend "gcs" {
    bucket = "tortoise-hull-hyujdmkj3d"
    prefix = "pubsub-terraform/state"
  }
}

/* Log pipeline
 * -----------------------------------------------------------
 */ 

// Stackdriver logging sink
resource "google_logging_project_sink" "splunk-sink" {
  name = "splunk-sink"
  destination = "pubsub.googleapis.com/projects/${var.project}/topics/${var.topicName}"
  filter = ""
  unique_writer_identity = true
  project = "${var.project}"
  depends_on = ["google_pubsub_topic.splunk-logging"]
}

// Explicit permission for the sink's export service-account
// Might work without it, but will produce an error message
resource "google_pubsub_topic_iam_member" "log-writer" {
  topic = "${var.topicName}"
  role = "roles/pubsub.publisher"
  project = "${var.project}"
  member = "${google_logging_project_sink.splunk-sink.writer_identity}"
  depends_on = ["google_logging_project_sink.splunk-sink"]
} 

// Log export topic
resource "google_pubsub_topic" "splunk-logging" {
  project = "${var.project}"
  name = "${var.topicName}"
}

// Subscription that connects splunk-exporter service account to the topic
resource "google_pubsub_subscription" "splunk-subscription" {
  name = "${var.subscriptionName}"
  topic = "${var.topicName}"
  ack_deadline_seconds = 10
  project = "${var.project}"
  depends_on = ["google_pubsub_topic.splunk-logging"]
}


/* Splunk-exporter service account
 * -------------------------------------------------------------------------------
 */

// The service account itself
resource "google_service_account" "splunk_pubsub_sa" {
  account_id = "splunk-sa"
  display_name = "Splunk log puller"
  project = "${var.project}"
}

// The account's key, used by Splunk to gain access to logs
resource "google_service_account_key" "splunk_pubsub_key" {
  service_account_id = "${google_service_account.splunk_pubsub_sa.name}"
  depends_on = ["google_service_account.splunk_pubsub_sa"]
  //TODO: Possibility: Encrypt with gpg key, so that private key won't be stored in unencrypted state
}

// The produced secret, which is mounted on a volume on the Splunk container
resource "kubernetes_secret" "splunk-google-application-credentials" {
  metadata {
    name = "splunk-google-application-credentials"
  }
  data {
    credentials.json = "${base64decode(google_service_account_key.splunk_pubsub_key.private_key)}"
  }
  depends_on = ["google_service_account_key.splunk_pubsub_key"]
}

// Subscription subscriber permission
resource "google_pubsub_subscription_iam_member" "splunk-fetcher-sub" {
  subscription = "${var.subscriptionName}"
  role = "roles/pubsub.subscriber"
  member = "serviceAccount:${google_service_account.splunk_pubsub_sa.email}"
  project = "${var.project}"
  depends_on = ["google_pubsub_subscription.splunk-subscription", "google_service_account.splunk_pubsub_sa"]
}

// Subscription viewer permission
resource "google_pubsub_subscription_iam_member" "splunk-fetcher-view" {
  subscription = "${var.subscriptionName}"
  role = "roles/pubsub.viewer"
  member = "serviceAccount:${google_service_account.splunk_pubsub_sa.email}"
  project = "${var.project}"
  depends_on = ["google_pubsub_subscription.splunk-subscription", "google_service_account.splunk_pubsub_sa"]
}

// Project viewer permission
// Appears to be needed in order to load project- and sink-name correctly when adding the import
// TODO: See if a more restrictive permission may be used
resource "google_project_iam_member" "logging-project-viewer" {
  project = "${var.project}"
  role = "roles/viewer"
  member = "serviceAccount:${google_service_account.splunk_pubsub_sa.email}"
  depends_on = ["google_service_account.splunk_pubsub_sa"]
}
