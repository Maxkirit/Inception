#!/bin/sh
set -e

cd /project
zola build --base-url $ZOLA_URL --output-dir /tmp/zola_output --force
mv /tmp/zola_output /data