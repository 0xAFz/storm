package cmd

import (
	"context"
	"net"
	"os"
	"os/signal"
	"syscall"

	"github.com/0xAFz/storm/internal/api"
	"github.com/0xAFz/storm/internal/config"
	"github.com/0xAFz/storm/internal/producer"
	"github.com/0xAFz/storm/internal/service"
	statusv1 "github.com/0xAFz/storm/protobuf/status/v1"
	"github.com/rs/zerolog/log"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
)

func Serve() {
	config.LoadConfig()

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	producer, err := producer.NewKafkaProducer(config.AppConfig.BrokerList)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to connect kafka broker")
	}

	statusService := service.NewStatusService(producer)

	grpcStatusServer := api.NewStatusServer(statusService)

	server := grpc.NewServer()
	statusv1.RegisterStatusServer(server, grpcStatusServer)

	reflection.Register(server)

	listen, err := net.Listen("tcp", config.AppConfig.GrpcServerAddr)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to listen tcp server")
	}

	go func() {
		if err := server.Serve(listen); err != nil {
			log.Fatal().Err(err).Msg("failed to serve grpc server")
		}
	}()

	log.Info().Msg("grpc server is up and running")
	<-ctx.Done()
	log.Info().Msg("shutting down grpc server")
	server.GracefulStop()
}
