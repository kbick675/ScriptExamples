variable "aws_region" {
  description = "id of preferred aws region"
  type        = string
  default     = "us-west-2"
}
variable "aws_profile" {
  description = "aws cli profile"
  type        = string
  default     = ""
}
variable "vpc_id" {
  description = "id of preferred vpc"
  type        = string
  default     = ""
}
variable "ec2_subnet_id" {
  description = "subnet id for EC2 instance deployment"
  type        = string
  default     = ""
}
variable "ec2_ami_filter" {
  description = "map of ami filter values"
  type        = map
  default = {
    name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20200729"
    virtualization_type = "hvm"
    owners              = "099720109477"
  }
}
variable "ec2_keypair_name" {
  description = "name of key pair for ssh access"
  type        = string
  default     = "msk_client_key_pair"
}
variable "ec2_instance_size" {
  description = "size of ec2 instance"
  type        = string
  default     = "t3.medium"
}
variable "ec2_ebs_vol_size" {
  description = "size of primary ebs volume"
  type        = number
  default     = 10
}
variable "ec2_ebs_vol_type" {
  description = "ebs volume type"
  type        = string
  default     = "gp2"
}
variable "ec2_instance_count" {
  description = "count of ec2 instances for client systems"
  type        = number
  default     = 2
}
variable "rootca_arn" {
  description = "arn of the root CA for deployment"
  type        = string
  default     = ""
}
variable "issuingca_arn" {
  description = "arn of the issuing/subordinate CA for deployment"
  type        = string
  default     = ""
}
variable "cluster_settings" {
  type = map
  default = {
    private_subnet_count = 2
    public_subnet_count  = 2
    instances_per_subnet = 1
    instance_type        = "kafka.t3.small"
    environment          = "dev"
    cluster_name         = "kafka-cluster"
    cluster_version      = "2.4.1"
    ebs_vol_size         = 30
    monitoring_type      = "PER_TOPIC_PER_BROKER"
  }
}
variable "private_cidr_blocks" {
  description = "available CIDR blocks"
  type        = list(string)
  default = [
    "10.245.10.0/27",
    "10.245.10.32/27",
    "10.245.10.64/27",
    "10.245.10.96/27"
  ]
}


