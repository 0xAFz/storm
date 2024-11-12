package main

import (
	"context"
	"log"
	"time"

	statusv1 "github.com/0xAFz/storm/protobuf/status/v1"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func main() {
	conn, err := grpc.NewClient("127.0.0.1:50051", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("did not connect: %v", err)
	}
	defer conn.Close()

	statusServer := statusv1.NewStatusClient(conn)

	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	r, err := statusServer.UpdateStatus(ctx, &statusv1.UpdateStatusRequest{UserId: 2910, Status: false})
	if err != nil {
		log.Fatalf("failed to update user status: %v", err)
	}
	log.Printf("user status updated: %s", r.GetMessage())
}
