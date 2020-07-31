FROM alpine:latest
RUN apk add nodejs npm nginx

COPY variable/ dirty/
WORKDIR /dirty
RUN npm install && npm start
WORKDIR /
RUN test "$(ls dirty/output/)" && mv dirty/output/* clean/; rm -r dirty

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY static/ LICENSE clean/

ENTRYPOINT ["nginx", "-g", "pid /var/run/nginx.pid; daemon off; master_process on;"]
