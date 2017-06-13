# Travis Platform Terraform Variables

variable "env" {
    description = "One of [ production | staging | development | test ]"
    default = "development"
}

variable "count" { default = 1 }
variable "key_name" {}
variable "key_path" {}
variable "region" { default = "us-east-1" }
variable "role" { default = "travis-platform" }
