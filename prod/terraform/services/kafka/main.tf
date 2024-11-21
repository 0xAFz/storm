terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.33.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/storm/config"
  config_context = "default"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/storm/config"
    config_context = "default"
  }
}

resource "helm_release" "strimzi" {
  name       = "strimzi"
  repository = "https://strimzi.io/charts/"
  chart      = "strimzi-kafka-operator"
  version    = "0.44.0"
  namespace  = "kafka"
  create_namespace = true
}
