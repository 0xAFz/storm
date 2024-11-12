run:
	go run main.go
build:
	go build -ldflags "-w -s" -o storm main.go
fmt:
	go fmt .
proto:
	protoc --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative protobuf/status/v1/status.proto