terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.33.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/kube/storm/k3s.yaml"
  config_context = "default"
}

resource "kubernetes_namespace" "storm" {
  metadata {
    name = "storm"
  }
}

resource "kubernetes_config_map" "storm_config" {
  metadata {
    name      = "storm-config"
    namespace = kubernetes_namespace.storm.metadata[0].name
  }

  data = {
    GRPC_SERVER_ADDR  = ":50051"
    KAFKA_BROKER_LIST = "kafka-cluster-kafka-0.kafka.svc.cluster.local:9092,kafka-cluster-kafka-1.kafka.svc.cluster.local:9092,kafka-cluster-kafka-2.kafka.svc.cluster.local:9092"
  }
}
