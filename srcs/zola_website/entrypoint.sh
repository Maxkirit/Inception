#!/bin/sh
set -e

cd /project
zola build --base-url $ZOLA_URL --output-dir /tmp/zola_output --force
cp /tmp/zola_output/* /data/.
rm -rf /tmp/zola_output