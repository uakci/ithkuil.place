FROM alpine:latest
ENTRYPOINT ["nginx"]
EXPOSE 80
RUN apk add --no-cache nginx
ADD target/ /
