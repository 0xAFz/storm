resource "kubernetes_namespace" "storm" {
  metadata {
    name = "storm"
  }
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
  depends_on = [kubernetes_manifest.kafka_cluster]
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
    replicas                  = 3
    progress_deadline_seconds = 600
    min_ready_seconds         = 5
    revision_history_limit    = 5
    strategy {
      type = "RollingUpdate"
      rolling_update {
        max_surge       = "25%"
        max_unavailable = 1
      }
    }
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

          liveness_probe {
            grpc {
              port = 50051
            }
            initial_delay_seconds = 5
            period_seconds        = 10
          }
          readiness_probe {
            grpc {
              port = 50051
            }
            initial_delay_seconds = 5
            period_seconds        = 10
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
      hosts       = [var.domain]
      secret_name = "storm-tls"
    }
    rule {
      host = var.domain
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

resource "kubernetes_horizontal_pod_autoscaler_v2" "storm_hpa" {
  metadata {
    name      = "storm-hpa"
    namespace = kubernetes_namespace.storm.metadata[0].name
  }
  spec {
    min_replicas = 3
    max_replicas = 20
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.storm_deployment.metadata[0].name
    }
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = 80
        }
      }
    }
  }
}
