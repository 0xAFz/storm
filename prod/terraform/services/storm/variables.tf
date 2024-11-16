variable "CI_REGISTRY_USER" {
  description = "Gitlab registry username"
  type        = string
}

variable "CI_REGISTRY_PASSWORD" {
  description = "Gitlab registry access token"
  type = string
}

variable "CI_REGISTRY_EMAIL" {
  description = "Gitlab registry email"
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
