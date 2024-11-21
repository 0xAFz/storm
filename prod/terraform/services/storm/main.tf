terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.33.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/storm/config"
  config_context = "default"
}

resource "kubernetes_manifest" "kafka_cluster" {
  manifest = {
    "apiVersion" = "kafka.strimzi.io/v1beta2"
    "kind"       = "Kafka"
    "metadata" = {
      "name"      = "kafka-cluster"
      "namespace" = "kafka"
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
    GRPC_SERVER_ADDR  = var.grpc_server_addr
    KAFKA_BROKER_LIST = var.kafka_broker_list
  }
}

resource "kubernetes_secret" "gitlab_registry_secret" {
  metadata {
    name      = "gitlab-registry-secret"
    namespace = kubernetes_namespace.storm.metadata[0].name
  }

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "https://registry.gitlab.com" = {
          username = var.CI_REGISTRY_USER
          password = var.CI_REGISTRY_PASSWORD
          email    = var.CI_REGISTRY_EMAIL
        }
      }
    })
  }

  type = "kubernetes.io/dockerconfigjson"
}

resource "kubernetes_deployment" "storm_deployment" {
  depends_on = [ kubernetes_manifest.kafka_cluster ]
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
          image = var.image_tag
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
        image_pull_secrets {
          name = kubernetes_secret.gitlab_registry_secret.metadata[0].name
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
      name        = "grpc"
      protocol    = "TCP"
      port        = 8088
      target_port = 50051
    }
    type = "ClusterIP"
  }
}

# resource "kubernetes_manifest" "storm_certificate" {
#   manifest = {
#     "apiVersion" = "cert-manager.io/v1"
#     "kind"       = "Certificate"
#     "metadata" = {
#       "name"      = "storm-tls"
#       "namespace" = kubernetes_namespace.storm.metadata[0].name
#     }
#     "spec" = {
#       "secretName"  = "storm-tls"
#       "duration"    = "2160h0m0s" # 90 days
#       "renewBefore" = "360h0m0s"  # 15 days
#       "commonName"  = var.SUBDOMAIN
#       "dnsNames"    = [var.SUBDOMAIN]
#       "issuerRef" = {
#         "name"  = "le-staging"
#         "kind"  = "ClusterIssuer"
#         "group" = "cert-manager.io"
#       }
#     }
#   }
# }

# resource "kubernetes_manifest" "storm_ingressroute" {
#   manifest = {
#     "apiVersion" = "traefik.containo.us/v1alpha1"
#     "kind"       = "IngressRoute"
#     "metadata" = {
#       "name"      = "storm-ingress"
#       "namespace" = kubernetes_namespace.storm.metadata[0].name
#       annotations = {
#         "traefik.ingress.kubernetes.io/service.serversscheme" = "h2c"
#       }
#     }
#     "spec" = {
#       "entryPoints" = ["websecure"]
#       "routes" = [
#         {
#           "match" = "Host(`${var.SUBDOMAIN}`)"
#           "kind"  = "Rule"
#           "services" = [
#             {
#               "name"           = kubernetes_service.storm_service.metadata[0].name
#               "namespace"      = kubernetes_namespace.storm.metadata[0].name
#               "port"           = 8088
#               "scheme"         = "h2c"
#               "passHostHeader" = true

#             }
#           ]
#           # "middlewares" = [
#           #   {
#           #     "name"      = "storm-https-redirect"
#           #     "namespace" = kubernetes_namespace.storm.metadata[0].name
#           #   }
#           # ]
#         }
#       ]
#       "tls" = {
#         "secretName" = "storm-tls"
#       }
#     }
#   }
# }

resource "kubernetes_ingress_v1" "storm-ingress" {
  metadata {
    name      = "storm-ingress"
    namespace = kubernetes_namespace.storm.metadata[0].name

    annotations = {
      "cert-manager.io/cluster-issuer" : "le-staging"
      "nginx.ingress.kubernetes.io/ssl-redirect" : "false"
      "nginx.ingress.kubernetes.io/backend-protocol" : "GRPC"
    }
  }

  spec {
    ingress_class_name = "nginx"
    tls {
      hosts       = [var.SUBDOMAIN]
      secret_name = "storm-tls"
    }
    rule {
      host = var.SUBDOMAIN
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.storm_service.metadata[0].name
              port {
                number = 8088
              }
            }
          }
        }
      }
    }
  }
}
