FROM alpine:3.22

RUN apk update && apk add --no-cache redis

#this creates a non root user to start redis with.
#More secure as if vulnerabitly allows attacker to take control of container,
#no root privilege access to the container
RUN adduser -S -D -H -s /sbin/nologin redis \
    && mkdir -p /var/lib/redis \
    && chown redis:redis /var/lib/redis

USER redis

EXPOSE 6379

COPY ./redis.conf /etc/redis/redis.conf

HEALTHCHECK --interval=5s --timeout=3s --retries=5 --start-period=10s \
            CMD redis-cli ping || exit 1

CMD [ "redis-server", "/etc/redis/redis.conf" ]