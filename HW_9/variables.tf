variable "env_name" {
  description = "environment name"
  type        = string
  default     = "HW9"
}

variable "allowed_ips" {
  description = "List of allowed IP ranges for SSH and HTTP access"
  type        = list(string)
  default     = ["195.24.131.82", "85.198.144.34", "91.193.129.182", "91.204.120.178", "92.119.220.145", "109.87.190.6", "40.91.223.95"]
}
