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
    ---
    apiVersion: kafka.strimzi.io/v1beta2
    kind: Kafka
    metadata:
      name: kafka-cluster
      namespace: kafka
    spec:
      kafka:
        replicas: 3
        listeners:
          - name: plain
            port: 9092
            type: internal
            tls: false
          - name: tls
            port: 9093
            type: internal
            tls: true
        storage:
          type: ephemeral
        config:
          auto.create.topics.enable: "true"
          offsets.topic.replication.factor: 3
          transaction.state.log.replication.factor: 3
          transaction.state.log.min.isr: 2
          default.replication.factor: 3
          min.insync.replicas: 2
          log.message.format.version: "3.1"
      zookeeper:
        replicas: 3
        storage:
          type: ephemeral
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
