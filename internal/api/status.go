package api

import (
	"github.com/0xAFz/storm/internal/service"
	statusv1 "github.com/0xAFz/storm/protobuf/status/v1"
)

type StatusServer struct {
	statusv1.UnimplementedStatusServer
	statusService *service.StatusService
}

func NewStatusServer(
	statusService *service.StatusService,
) *StatusServer {
	return &StatusServer{
		statusService: statusService,
	}
}
