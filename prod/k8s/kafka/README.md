Here are the steps to deploy a production-grade Kafka cluster using the Strimzi Helm chart on Kubernetes:

1. **Install Helm**: If you haven't already, install Helm - the Kubernetes package manager. This will allow you to easily deploy the Strimzi Kafka Operator.

    1. Install the Helm CLI:
    ```
    curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    ```

    2. Verify the Helm installation:
    ```
    helm version
    ```

2. **Add Strimzi Helm Repository**: Add the Strimzi Helm repository to your local Helm configuration:
   ```
   helm repo add strimzi https://strimzi.io/charts/
   helm repo update
   ```

3. **Create Namespace**: Create a namespace for your Kafka cluster, e.g. `kafka`:
   ```
   kubectl create namespace kafka
   ```

4. **Deploy Strimzi Operator**: Install the Strimzi Operator, which will manage the deployment of your Kafka cluster:
   ```
   helm install strimzi strimzi/strimzi-kafka-operator --namespace kafka
   ```

5. **Deploy Kafka Cluster**: Create a Kafka cluster using the Strimzi Operator. Here's an example Kafka cluster configuration:
   ```yaml
   apiVersion: kafka.strimzi.io/v1beta2
   kind: Kafka
   metadata:
     name: kafka-cluster
     namespace: kafka
   spec:
     kafka:
       version: 3.1.0
       replicas: 3
       listeners:
         - name: plain
           port: 9092
           type: internal
         - name: tls
           port: 9093
           type: internal
       config:
         offsets.topic.replication.factor: 3
         transaction.state.log.replication.factor: 3
         transaction.state.log.min.isr: 2
         log.message.format.version: "3.1"
     zookeeper:
       replicas: 3
     entityOperator:
       topicOperator: {}
       userOperator: {}
   ```
   Save this as `kafka-cluster.yml` and deploy it:
   ```
   kubectl apply -f kafka-cluster.yml -n kafka
   ```

6. **Verify Deployment**: Monitor the deployment until all the Kafka and Zookeeper pods are running:
   ```
   kubectl get pods -n kafka
   ```

This will deploy a highly available Kafka cluster with 3 brokers and 3 Zookeeper nodes. The cluster is accessible both internally (within the Kubernetes cluster) and externally (via a load balancer).

The Strimzi Helm chart is a recommended and widely-used option for deploying production-grade Kafka on Kubernetes. It provides features like automatic topic management, user management, and other operational capabilities out-of-the-box.

## Automate deployment with Terraform
Absolutely, you can automate the deployment of a Kafka cluster with Strimzi on Kubernetes using Terraform. Here's an example of how you can do it:

1. **Install Terraform**: Make sure you have Terraform installed on your machine.

2. **Create a Terraform configuration file**: Create a new file, e.g., `main.tf`, and add the following content:

```hcl
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

# Deploy Strimzi Operator
resource "helm_release" "strimzi_operator" {
  name       = "strimzi"
  repository = "https://strimzi.io/charts/"
  chart      = "strimzi-kafka-operator"
  namespace  = "kafka"
}

# Deploy Kafka cluster
resource "kubernetes_namespace" "kafka" {
  metadata {
    name = "kafka"
  }
}

resource "kubernetes_manifest" "kafka_cluster" {
  manifest = yamldecode(<<-EOF
  apiVersion: kafka.strimzi.io/v1beta2
  kind: Kafka
  metadata:
    name: my-cluster
    namespace: kafka
  spec:
    kafka:
      version: 3.1.0
      replicas: 3
      listeners:
        - name: plain
          port: 9092
          type: internal
        - name: tls
          port: 9093
          type: internal
        - name: external
          port: 9094
          type: loadbalancer
      config:
        offsets.topic.replication.factor: 3
        transaction.state.log.replication.factor: 3
        transaction.state.log.min.isr: 2
        log.message.format.version: "3.1"
    zookeeper:
      replicas: 3
    entityOperator:
      topicOperator: {}
      userOperator: {}
  EOF
  )
}
```

3. **Initialize Terraform**: Run `terraform init` to initialize the Terraform working directory.

4. **Apply the Terraform configuration**: Run `terraform apply` to deploy the Kafka cluster with Strimzi on your Kubernetes cluster.

This Terraform configuration will:
1. Deploy the Strimzi Kafka Operator using the Helm provider.
2. Create a new namespace called "kafka".
3. Deploy the Kafka cluster with the specified configuration using the Kubernetes provider.

The Terraform configuration ensures that the Kafka cluster is deployed in a highly available manner, with 3 Kafka brokers and 3 Zookeeper nodes. It also configures the various Kafka settings, such as replication factors and log message format version.

By using Terraform, you can easily automate the deployment and management of your Kafka cluster on Kubernetes. This can be especially useful for setting up consistent, reproducible environments across different environments (e.g., development, staging, production).
