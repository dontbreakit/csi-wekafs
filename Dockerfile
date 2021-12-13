FROM golang:1.16.12-alpine3.15 as go-builder
# https://stackoverflow.com/questions/36279253/go-compiled-binary-wont-run-in-an-alpine-docker-container-on-ubuntu-host
RUN apk add --no-cache libc6-compat gcc
RUN apk add musl-dev
COPY go.mod /src/go.mod
COPY go.sum /src/go.sum
WORKDIR /src
RUN go mod download
ARG VERSION
RUN echo Building binaries version $VERSION
RUN echo Downloading required Go modules
ADD go.mod /src/go.mod
ADD go.sum /src/go.sum
ADD pkg /src/pkg
ADD cmd /src/cmd
#RUN go fmt ./... // this should be part of CI, not part of build
#RUN go vet ./...
#RUN go test ./...
RUN echo Building package
RUN CGO_ENABLED=0 GOOS="linux" GOARCH="amd64" go build -a -ldflags '-X main.version='$VERSION' -extldflags "-static"' -o "/bin/wekafsplugin" /src/cmd/*

FROM alpine:3.15
LABEL maintainers="Weka"
LABEL description="Weka CSI Driver"
# Add util-linux to get a new version of losetup.
RUN apk add util-linux
COPY --from=go-builder /bin/wekafsplugin /wekafsplugin
ARG binary=/bin/wekafsplugin
ENTRYPOINT ["/wekafsplugin"]
