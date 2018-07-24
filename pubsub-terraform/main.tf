/* Terraform for the GCP pubsub setup.
 * This setup will transfer logs from stackdriver
 * and let them end up in the Splunk forwarder.
 */

provider google {
  region = "${var.region}"
}

variable region {
  default = "europe-west1"
}

/* Log pipeline
 * -----------------------------------------------------------
 */ 

// Stackdriver logging sink
resource "google_logging_project_sink" "splunk-sink" {
  name = "splunk-sink"
  destination = "pubsub.googleapis.com/projects/pantel-2decb/topics/splunk-logging"
  filter = ""
  unique_writer_identity = true
  project = "pantel-2decb"
  depends_on = ["google_pubsub_topic.splunk-logging"]
}

// Explicit permission for the sink's export service-account
// Might work without it, but will produce an error message
resource "google_pubsub_topic_iam_member" "log-writer" {
  topic = "splunk-logging"
  role = "roles/pubsub.publisher"
  project = "pantel-2decb"
  member = "${google_logging_project_sink.splunk-sink.writer_identity}"
  depends_on = ["google_logging_project_sink.splunk-sink"]
} 

// Log export topic
resource "google_pubsub_topic" "splunk-logging" {
  project = "pantel-2decb"
  name = "splunk-logging"
}

// Subscription that connects splunk-exporter service account to the topic
resource "google_pubsub_subscription" "splunk-subscription" {
  name = "splunk-sub"
  topic = "splunk-logging"
  ack_deadline_seconds = 10
  project = "pantel-2decb"
  depends_on = ["google_pubsub_topic.splunk-logging"]
}


/* Splunk-exporter service account
 * -------------------------------------------------------------------------------
 */

// The service account itself
resource "google_service_account" "splunk_pubsub_sa" {
  account_id = "splunk-sa"
  display_name = "Splunk log puller"
  project = "pantel-2decb"
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
  subscription = "splunk-sub"
  role = "roles/pubsub.subscriber"
  member = "serviceAccount:${google_service_account.splunk_pubsub_sa.email}"
  project = "pantel-2decb"
  depends_on = ["google_pubsub_subscription.splunk-subscription", "google_service_account.splunk_pubsub_sa"]
}

// Subscription viewer permission
resource "google_pubsub_subscription_iam_member" "splunk-fetcher-view" {
  subscription = "splunk-sub"
  role = "roles/pubsub.viewer"
  member = "serviceAccount:${google_service_account.splunk_pubsub_sa.email}"
  project = "pantel-2decb"
  depends_on = ["google_pubsub_subscription.splunk-subscription", "google_service_account.splunk_pubsub_sa"]
}

// Project viewer permission
// Appears to be needed in order to load project- and sink-name correctly when adding the import
// TODO: See if a more restrictive permission may be used
resource "google_project_iam_member" "pantel" {
  project = "pantel-2decb"
  role = "roles/viewer"
  member = "serviceAccount:${google_service_account.splunk_pubsub_sa.email}"
  depends_on = ["google_service_account.splunk_pubsub_sa"]
}
