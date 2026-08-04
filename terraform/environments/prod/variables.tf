variable "project_name" {
  description = "Project identifier used for future infrastructure naming."
  type        = string
  default     = "replace-with-project-name"
}

variable "environment" {
  description = "Environment identifier for this root module."
  type        = string
  default     = "prod"
}
