variable "account_id" {
  type = string
}
variable "region" {
  type = string
}
variable "bucket_name" {
  type = string
}
variable "report_name" {
  type = string
}
variable "report_retention" {
  type = number
}
variable "function_name" {
  type = string
}
variable "function_file" {
  type = string
}
variable "function_log_retention" {
  type = number
}
variable "topic_name" {
  type = string
}
variable "subscription_emails" {
  type = list(string)
}
