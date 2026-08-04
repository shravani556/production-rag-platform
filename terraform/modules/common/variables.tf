variable "project_name" {
  description = "Provider-neutral project identifier."
  type        = string
}

variable "environment" {
  description = "Deployment environment identifier."
  type        = string
}

variable "tags" {
  description = "Common metadata for resources added in future phases."
  type        = map(string)
  default     = {}
}
