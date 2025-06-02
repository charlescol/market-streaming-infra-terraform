variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Default region"
  type        = string
}

variable "zone" {
  description = "Default zone"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  type        = string
}

variable "artifact_repo_name" {
  type        = string
}