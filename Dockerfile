FROM alpine:latest
EXPOSE 80
COPY src/nginx.conf /etc/nginx/conf.d/default.conf
COPY src /src/
COPY www/ LICENSE /www/
RUN apk add --no-cache bash && bash /src/make.sh
ENTRYPOINT ["nginx", "-g", "pid /var/run/nginx.pid; daemon off; master_process on;"]
