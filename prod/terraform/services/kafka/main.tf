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
  config_path    = "~/kube/storm/k3s.yaml"
  config_context = "default"
}

provider "helm" {
  kubernetes {
    config_path = "~/kube/storm/k3s.yaml"
  }
}

resource "kubernetes_namespace" "kafka" {
  metadata {
    name = "kafka"
  }
}

resource "helm_release" "strimzi" {
  name       = "strimzi"
  repository = "https://strimzi.io/charts/"
  chart      = "strimzi-kafka-operator"
  version    = "0.44.0"
  namespace  = kubernetes_namespace.kafka.metadata[0].name
}

resource "kubernetes_manifest" "kafka_cluster" {
  manifest = yamldecode(file("../../../k8s/kafka/kafka-cluster.yml"))
}
