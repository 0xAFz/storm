# Storm

### **Project Overview**

**Storm** is a **microservice** for managing user status updates using an **event-driven** architecture. The service is built with **Go** and utilizes **gRPC** for interface communication and **Kafka** for event streaming.

This service is designed to be lightweight, scalable, and production-ready, utilizing **Kubernetes** as its orchestration layer. This documentation includes:
- Local development setup.
- Production deployment approaches:
  1. **End-to-End Automation** (one command).
  2. **Manual Steps with Automation**.

---

## **Table of Contents**
1. [Prerequisites](#prerequisites)
2. [Running Locally](#running-locally)
3. [Project Architecture](#project-architecture)
4. [Production Deployment](#production-deployment)
   - [End-to-End Automation](#end-to-end-automation)
   - [Manual Steps](#manual-steps)

---

## **Prerequisites**

### **Tools and Versions**
To run or deploy the project, ensure you have the following installed:

#### Development:
| **Tool**             | **Version**   | **Purpose**                              |
|----------------------|---------------|------------------------------------------|
| Go                   | 1.22.7+       | Building and running the service.        |
| Docker + Compose     | 27.1.1+       | Managing dependencies locally.           |
| Protobuf             | 28.3+         | Generating gRPC code from `.proto` files.|

#### Production:
| **Tool**             | **Version**   | **Purpose**                              |
|----------------------|---------------|------------------------------------------|
| Terraform            | v1.9.6+       | Automating resource provisioning.        |
| Ansible              | 2.17.1+       | Setting up Kubernetes clusters.          |
| Kubectl              | v1.31.2+      | Managing Kubernetes clusters.            |
| Python3 + pip        | 3.12.4+       | Running auxiliary scripts.               |
| Bash                 | Latest        | Executing automation scripts.            |

---

## **Running Locally**

### **Steps to Get Started**

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/0xAFz/storm.git
   cd storm
   ```

2. **Start Dependencies (Kafka)**:
   ```bash
   docker compose up -d
   ```

3. **Set Up Environment Variables**:
   ```bash
   cp .env.example .env
   vim .env
   ```
   Update the values in `.env` as needed (e.g., Kafka broker addresses, service ports).

4. **Generate gRPC Code**:
   Run the following command to compile the `.proto` files into Go code:
   ```bash
   make proto
   ```

5. **Run the Application**:
   ```bash
   make run
   # or
   go run main.go
   ```

6. **Test the Service**:
   Use `grpcurl` to test the service:
   ```bash
   grpcurl -plaintext localhost:50051 list
   ```

---

## **Project Architecture**

### **Logical Architecture**

1. **Serivce sends a status update** → Received via **gRPC interface**.
2. A Kafka event is published to a specified topic.

### **Key Components**

| **Component** | **Description**                                                                 |
|---------------|---------------------------------------------------------------------------------|
| gRPC Service  | Handles incoming user status updates.                                           |
| Kafka         | Stores and forwards events for consumers.                                       |
| Configurations| Managed via `.env` files for simplicity.                                        |
| Kubernetes    | Ensures the service is scalable and fault-tolerant in production.               |

---

## **Production Deployment**

Production deployment supports **two approaches**: **fully automated** or **manual with automation**.

---

### **End-to-End Automation**

This approach automates everything from VM provisioning to Kubernetes resource deployment.

#### **Steps**
1. **Navigate to Production Directory**:
   ```bash
   cd prod/
   ```

2. **Setup Environment Variables**:
   ```bash
   cp .env.example .env
   vim .env

   cp terraform/services/storm/.env.example terraform/services/storm/.env
   vim terraform/services/storm/.env
   ```

   Update the values for:
   - OpenStack credentials (for Terraform).
   - Cloudflare credentials (for DNS management).
   - Gitlab repo credentials (for Container registery).
   - Kubernetes configurations.

3. **Setup Ansible Variables**:
   ```bash
   vim ansible/inventory/group_vars/...
   ```
   Replace placeholders with actual values

4. **Run the Deployment Script**:
   ```bash
   ./deploy.sh up
   ```
5. **Clean up all resources**
   ```bash
   ./deploy.sh down
   ```

#### **What Happens**:
1. **Terraform** provisions VMs using OpenStack.
2. A Python script generates an Ansible inventory.
3. A Python script add DNS records on Cloudflare.
4. **Ansible**:
   - Installs Kubernetes (K3s).
   - Configures the cluster (e.g., ingress nginx, cert-manager).
5. **Terraform** deploys:
   - **Kafka Cluster**: A highly available Kafka setup.
   - **Storm Microservice**: Configurations, deployment, service, and ingress.

---

### **Manual Steps**

This approach allows more flexibility and supports different cloud providers.

#### **Steps**
1. **Manually Create VMs**:
   Create VMs in your preferred cloud provider (ensure **DNS** records `(e.g., A storm.domain.tld 192.168.1.100)` are configured).

2. **Generate Ansible Inventory**:
   Update the inventory file with your server details:
   ```bash
   vim ansible/inventory/hosts.yml
   ```
3. **Setup Ansible Variables**:
   ```bash
   vim ansible/inventory/group_vars/...
   ```
   Replace placeholders with actual values
4. **Run Ansible Playbook**:
   Install Kubernetes on your nodes:
   ```bash
   ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/cluster.yml
   ```
   ### **Deploying with YAML manifests**
   1. **Set Config for Kubectl**:
      The ansible generates kube config in your local: `~/.kube/storm/config`
      ```bash
      export KUBECONFIG=~/.kube/storm/config
      ```
   2. **Deploy Kafka**:
      Use the Strimzi operator:
      ```bash
      # deploy strimzi opreator using helm
      helm repo add strimzi https://strimzi.io/charts/
      helm repo update

      # create a namespace for kafka
      kubectl create namespace kafka

      # apply kafka manifest
      kubectl apply -f k8s/kafka/kafka-cluster.yml
      ```

   3. **Deploy Storm Microservice**:
      Apply resources:
      ```bash
      kubectl apply -f k8s/storm/storm.yml
      ```

   ### **Deploying with Terraform**
   1. **Deploy Kafka**:
      ```bash
         terraform chdir=terraform/services/kafka init
         terraform chdir=terraform/services/kafka apply
      ```
   2. **Deploy Storm Microservice**
      ```bash
         terraform chdir=terraform/services/storm init
         terraform chdir=terraform/services/storm apply
      ```
---

## **5. Testing in Production**

1. **Verify Kafka is Running**:
   ```bash
   kubectl get po -n kafka
   ```

2. **Check Storm Service**:
   Ensure the service is running:
   ```bash
   kubectl get po -n storm
   ```

3. **Test Service Endpoints**:
   - List gRPC methods:
     ```bash
     grpcurl storm.domain.tld list
     ```
   - Send a request:
     ```bash
     grpcurl -d '{"user_id": 1234, "status": true}' storm.domain.tld status.v1.Status/UpdateStatus
     ```

4. **Expected Response**:
   ```json
   {
       "message": "ok"
   }
   ```
