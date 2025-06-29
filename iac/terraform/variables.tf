variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "automode-cluster"
  validation {
    condition     = length(var.cluster_name) > 0
    error_message = "The cluster name must not be an empty string"
  }
}

variable "region" {
  description = "region"
  default     = "ap-southeast-2" 
  type        = string
}

variable "eks_cluster_version" {
  description = "EKS Cluster version"
  default     = "1.31"
  type        = string
}

# VPC with 65536 IPs (10.0.0.0/16) for 3 AZs
variable "vpc_cidr" {
  description = "VPC CIDR. This should be a valid private (RFC 1918) CIDR range"
  default     = "10.0.0.0/16"
  type        = string
}