FROM golang:1.22.9-alpine3.20 AS builder

RUN apk add --no-cache protobuf

RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.34.2 && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.5.1

ENV PATH=$PATH:/go/bin

WORKDIR /app

COPY go.mod go.sum ./

RUN go mod download && go mod verify

COPY . .

RUN protoc --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative ./protobuf/status/v1/status.proto

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags "-w -s" -o storm

FROM alpine:3.20 AS prod

WORKDIR /app

COPY --from=builder /app/protobuf/status/v1 /app/protobuf/status/v1

COPY --from=builder /app/storm .

EXPOSE 50051

CMD [ "./storm" ]
