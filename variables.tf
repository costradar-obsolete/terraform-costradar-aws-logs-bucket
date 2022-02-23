variable "bucket_name" {
  type = string
}

variable "notification_topic_name" {
  type = string
}

variable "encryption" {
  type = object({
    sse_algorithm     = string
    kms_master_key_id = string
  })
  default = {
    sse_algorithm     = "AES256"
    kms_master_key_id = null
    #    kms_master_key_id = "aws/s3"
  }
}

variable "block_public_access" {
  type    = bool
  default = true
}

locals {
  service_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "billingreports.amazonaws.com"
  ]
}

data "aws_caller_identity" "current" {}