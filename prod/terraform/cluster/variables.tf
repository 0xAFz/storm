variable "os_username" {
  description = "OpenStack username"
  type        = string
}

variable "os_tenant_name" {
  description = "OpenStack tenant name"
  type        = string
}

variable "os_password" {
  description = "OpenStack password"
  type        = string
  sensitive   = true
}

variable "os_auth_url" {
  description = "OpenStack authentication URL"
  type        = string
}

variable "os_region" {
  description = "OpenStack region name"
  type        = string
}

variable "pubkey_path" {
  description = "The path to the public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "instance_name" {
  description = "Hostname of VM"
  type        = string
  default     = "nova"
}

variable "image_name" {
  description = "OpenStack operation system image"
  type        = string
}

variable "flavor_name" {
  description = "OpenStack flavor name"
  type        = string
}

variable "network_name" {
  description = "OpenStack network name"
  type        = string
}

variable "keypair_name" {
  description = "OpenStack keypair name"
  type        = string
}

variable "instance_count" {
  description = "OpenStack instance count"
  type        = number
  default     = 1
}

variable "security_groups" {
  description = "List of security groups to assign to the instance"
  type        = list(string)
  default     = ["allow_all"]
}
