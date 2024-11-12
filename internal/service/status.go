package service

import (
	"encoding/json"
	"fmt"
	"strconv"

	"github.com/0xAFz/storm/internal/entity"
	"github.com/0xAFz/storm/internal/producer"
	"github.com/rs/zerolog/log"
)

type StatusService struct {
	producer *producer.KafkaAsyncProducer
}

func NewStatusService(producer *producer.KafkaAsyncProducer) *StatusService {
	return &StatusService{
		producer: producer,
	}
}

func (s *StatusService) UpdateUserStatus(user entity.User) error {
	u, err := json.Marshal(user)
	if err != nil {
		log.Err(err).Msg("failed to serialize data to json")
		return fmt.Errorf("failed to serialize data to json: %w", err)
	}

	if err := s.producer.ProduceMessage("status-events", strconv.FormatInt(user.UserID, 10), string(u)); err != nil {
		log.Err(err).Msg("failed to produce message to kafka")
		return fmt.Errorf("failed to produce message to kafka: %w", err)
	}

	return nil
}
