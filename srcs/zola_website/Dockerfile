FROM alpine:3.22

RUN apk update && apk add --no-cache zola

RUN mkdir /project
COPY --chmod=+x ./project/. /project/.
COPY --chmod=+x ./entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]