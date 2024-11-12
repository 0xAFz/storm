package config

import (
	"github.com/spf13/viper"
)

type Config struct {
	GrpcServerAddr string
	BrokerList     []string
}

var AppConfig *Config

func LoadConfig() {
	viper.SetConfigFile(".env")
	viper.ReadInConfig()
	viper.AutomaticEnv()
	AppConfig = &Config{
		BrokerList:     viper.GetStringSlice("KAFKA_BROKER_LIST"),
		GrpcServerAddr: viper.GetString("GRPC_SERVER_ADDR"),
	}
}
