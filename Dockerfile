FROM alpine:latest
EXPOSE 80
RUN head -n1 /etc/apk/repositories | \
  sed 's#/[^/]*/main$#/edge/testing#' >> /etc/apk/repositories; \
  apk add nginx pandoc bash
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY . .
WORKDIR /src/
RUN /build.sh
RUN apk del pandoc bash
ENTRYPOINT ["nginx", "-g", "pid /var/run/nginx.pid; daemon off; master_process on;"]
