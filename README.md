# Storm

###  Project Overview
The User Status Microservice is responsible for managing the status of users within the system. It receives user status updates via a gRPC interface and publishes these updates as events to a Kafka message bus.

## Running the Project Locally

### Requirements
- Go v1.22.7 or higher
- Docker and Docker Compose
- Protocol Buffer Compiler (libprotoc) version 28.3

1. Start the required services (Kafka) using Docker Compose:
   ```
   docker compose up -d
   ```

2. Copy the example environment file and configure the necessary settings:
   ```
   cp .env.example .env
   vim .env
   ```

3. Generate the Protocol Buffer files:
   ```
   make proto
   ```

4. Run the application:
   ```
   make run
   # or
   go run main.go
   ```

## Note on Production Readiness
The current implementation of the User Status Microservice is not ready for production use, as the Kafka message bus is not configured for high availability (HA). Before deploying to production, you should ensure that the Kafka cluster is set up for HA to ensure reliable message delivery and processing.
