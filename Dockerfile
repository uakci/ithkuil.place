FROM alpine:edge AS static
RUN rm -rf /root/
COPY LICENSE /root/
RUN sed -i '${p;s/community/testing/}' /etc/apk/repositories
RUN apk add --no-cache bash file git pandoc sed yq zip
COPY src/ /
RUN bash /all.sh

FROM caddy:alpine AS webserver
COPY --from=static /root /www
COPY src/Caddyfile /etc/caddy/Caddyfile
RUN caddy validate -config /etc/caddy/Caddyfile
EXPOSE 80
