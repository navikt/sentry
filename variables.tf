variable "github_api_secret" {}
variable "github_app_client_id" {}
variable "github_app_client_secret" {}
variable "github_app_id" {}
variable "github_app_name" {}
variable "github_app_private_key" {}
variable "github_app_webhook_secret" {}
variable "scaleft_enrollment_token" {}
variable "sentry_db_name" {}
variable "sentry_db_password" {}
variable "sentry_db_user" {}
variable "sentry_image" {}
variable "sentry_secret_key" {}
variable "sentry_slack_client_id" {}
variable "sentry_slack_client_secret" {}
variable "sentry_slack_verification_token" {}
variable "sentry_url" {
  default = "sentry-open.gc.nav.no"
}
variable "nginx_image" {
  default = "nginx:1.17-alpine"
}
