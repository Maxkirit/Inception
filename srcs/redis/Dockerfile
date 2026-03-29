FROM alpine:3.22

RUN apk update && apk add --no-cache redis

#Using redis user instead of root more secure as if vulnerabitly allows attacker to take control of container,
#no root privilege access to the container
RUN mkdir -p /var/lib/redis \
    && chown redis:redis /var/lib/redis

EXPOSE 6379

COPY ./redis.conf /etc/redis/redis.conf

HEALTHCHECK --interval=5s --timeout=3s --retries=5 --start-period=10s \
            CMD redis-cli ping || exit 1
            
#this directive removes root privileges so can't copy files everywhere at build time
#always do it as late as possible
USER redis

CMD [ "redis-server", "/etc/redis/redis.conf" ]