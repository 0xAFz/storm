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
  manifest = {
    "apiVersion" = "kafka.strimzi.io/v1beta2"
    "kind"       = "Kafka"
    "metadata" = {
      "name"      = "kafka-cluster"
      "namespace" = kubernetes_namespace.kafka.metadata[0].name
    }
    "spec" = {
      "kafka" = {
        "replicas" = 3
        "listeners" = [
          {
            "name" = "plain"
            "port" = 9092
            "type" = "internal"
            "tls"  = false
          },
          {
            "name" = "tls"
            "port" = 9093
            "type" = "internal"
            "tls"  = true
          }
        ]
        "storage" = {
          "type" = "ephemeral"
        }
        "config" = {
          "auto.create.topics.enable"                = "true"
          "offsets.topic.replication.factor"         = 3
          "transaction.state.log.replication.factor" = 3
          "transaction.state.log.min.isr"            = 2
          "default.replication.factor"               = 3
          "min.insync.replicas"                      = 2
          "log.message.format.version"               = "3.1"
        }
      }
      "zookeeper" = {
        "replicas" = 3
        "storage" = {
          "type" = "ephemeral"
        }
      }
      "entityOperator" = {
        "topicOperator" = {}
        "userOperator"  = {}
      }
    }
  }
}
