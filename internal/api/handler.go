package api

import (
	"context"

	"github.com/0xAFz/storm/internal/entity"
	statusv1 "github.com/0xAFz/storm/protobuf/status/v1"
)

func (s *StatusServer) UpdateStatus(ctx context.Context, req *statusv1.UpdateStatusRequest) (*statusv1.UpdateStatusResponse, error) {
	u := entity.User{
		UserID: req.GetUserId(),
		Status: req.GetStatus(),
	}

	if err := s.statusService.UpdateUserStatus(u); err != nil {
		return nil, err
	}

	return &statusv1.UpdateStatusResponse{
		Message: "ok",
	}, nil
}
