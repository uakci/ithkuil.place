FROM alpine:latest
EXPOSE 80
RUN apk add nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY . .
WORKDIR /src/
RUN /build.sh
ENTRYPOINT ["nginx", "-g", "pid /var/run/nginx.pid; daemon off; master_process on;"]
