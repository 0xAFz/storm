package producer

import (
	"github.com/rs/zerolog/log"

	"github.com/IBM/sarama"
)

type KafkaAsyncProducer struct {
	p sarama.AsyncProducer
}

func NewKafkaProducer(brokerList []string) (*KafkaAsyncProducer, error) {
	producerConfig := sarama.NewConfig()
	// producerConfig.Producer.Return.Successes = true

	asyncProducer, err := sarama.NewAsyncProducer(brokerList, producerConfig)
	if err != nil {
		return nil, err
	}

	return &KafkaAsyncProducer{
		p: asyncProducer,
	}, nil
}

func (p *KafkaAsyncProducer) ProduceMessage(topic, key, value string) error {
	msg := &sarama.ProducerMessage{
		Topic: topic,
		Key:   sarama.StringEncoder(key),
		Value: sarama.StringEncoder(value),
	}

	select {
	case p.p.Input() <- msg:
	case err := <-p.p.Errors():
		log.Err(err).Msg("failed to send message to kafka")
		return err
	}

	log.Info().Msg("event sent to kafka")
	return nil
}
