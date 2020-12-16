FROM alpine:latest
ENTRYPOINT ["nginx", "-g", "pid /var/run/nginx.pid; daemon off; master_process on;"]
EXPOSE 80
RUN apk add --no-cache nginx
ADD target/ /
