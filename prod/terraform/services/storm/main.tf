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

resource "kubernetes_deployment" "storm_deployment" {
  metadata {
    name      = "storm"
    namespace = kubernetes_namespace.storm.metadata[0].name
    labels = {
      "app.kubernetes.io/name"    = "storm"
      "app.kubernetes.io/part-of" = "storm"
      "app.kubernetes.io/env"     = "prod"
    }
  }

  spec {
    replicas = 3
    selector {
      match_labels = {
        "app.kubernetes.io/name"    = "storm"
        "app.kubernetes.io/part-of" = "storm"
        "app.kubernetes.io/env"     = "prod"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name"    = "storm"
          "app.kubernetes.io/part-of" = "storm"
          "app.kubernetes.io/env"     = "prod"
        }
      }
      spec {
        security_context {
          fs_group    = 2000
          run_as_user = 1000
        }

        container {
          name  = "storm"
          image = "gitlab.com/0xAFz/storm:latest"
          port {
            container_port = 50051
          }
          resources {
            requests = {
              "memory" = "256Mi"
              "cpu"    = "500m"
            }
            limits = {
              "memory" = "512Mi"
              "cpu"    = "2"
            }
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.storm_config.metadata[0].name
            }
          }
          security_context {
            run_as_user = 1000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "storm_service" {
  metadata {
    name      = "storm-service"
    namespace = kubernetes_namespace.storm.metadata[0].name
  }
  spec {
    selector = {
      "app.kubernetes.io/name"    = "storm"
      "app.kubernetes.io/part-of" = "storm"
      "app.kubernetes.io/env"     = "prod"
    }
    port {
      protocol    = "TCP"
      port        = 8088
      target_port = 50051
    }
    type = "ClusterIP"
  }
}

resource "kubernetes_manifest" "storm_https_redirect" {
  manifest = {
    "apiVersion" = "traefik.containo.us/v1alpha1"
    "kind"       = "Middleware"
    "metadata" = {
      "name"      = "storm-https-redirect"
      "namespace" = kubernetes_namespace.storm.metadata[0].name
    }
    "spec" = {
      "redirectScheme" = {
        "scheme"    = "https"
        "permanent" = true
      }
    }
  }
}

resource "kubernetes_manifest" "storm_ingressroute" {
  manifest = {
    "apiVersion" = "traefik.containo.us/v1alpha1"
    "kind"       = "IngressRoute"
    "metadata" = {
      "name"      = "storm-ingress"
      "namespace" = kubernetes_namespace.storm.metadata[0].name
    }
    "spec" = {
      "entryPoints" = ["websecure"]
      "routes" = [
        {
          "match" = "Host(`storm.zirakcloud.ir`)"
          "kind"  = "Rule"
          "services" = [
            {
              "name"           = kubernetes_service.storm_service.metadata[0].name
              "namespace"      = kubernetes_namespace.storm.metadata[0].name
              "scheme"         = "h2c"
              "passHostHeader" = true
              "port"           = 8088
            }
          ]
          "middlewares" = [
            {
              "name" = "storm-https-redirect"
            }
          ]
        }
      ]
      "tls" = {
        "certResolver" = "le-staging"
        "secretName"   = "storm-tls"
      }
    }
  }
}
