variable "CI_REGISTRY_USER" {
  description = "gitlab registry username"
  type        = string
}

variable "CI_REGISTRY_PASSWORD" {
  description = "gitlab registry access token"
  type = string
}

variable "CI_REGISTRY_EMAIL" {
  description = "gitlab registry email"
  type = string
}

variable "SUBDOMAIN" {
  description = "sub domain of project"
  type = string
}

variable "image_tag" {
  description = "project image tag"
  type = string
}

variable "grpc_server_addr" {
  description = "gRPC server addr"
  type = string
}

variable "kafka_broker_list" {
  description = "kafka cluster broker list"
  type = string
}
