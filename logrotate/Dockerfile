FROM alpine:latest

RUN apk add --no-cache logrotate dcron docker

COPY /logrotate/nginx_logs.conf /etc/logrotate.d/nginx_logs.conf

RUN echo "0 0 * * * /usr/sbin/logrotate -f /etc/logrotate.conf" > /etc/crontabs/root

CMD ["sh", "-c", "crond -f && tail -f /dev/null"]
