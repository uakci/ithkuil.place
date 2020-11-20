FROM alpine:latest
EXPOSE 80
COPY src/packages.sh /src/
RUN /src/packages.sh
COPY src /src/
COPY www/ LICENSE /www/
RUN /src/make.sh
COPY src/nginx.conf /etc/nginx/conf.d/default.conf
ENTRYPOINT ["nginx", "-g", "pid /var/run/nginx.pid; daemon off; master_process on;"]
