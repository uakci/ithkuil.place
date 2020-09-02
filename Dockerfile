aFROM alpine:latest
RUN apk add --no-cache nginx
EXPOSE 80
COPY /target/ /
ENTRYPOINT ["nginx", "-g", "pid /var/run/nginx.pid; daemon off; master_process on;"]
