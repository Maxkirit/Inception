#!/bin/sh
set -e

cd /project
mkdir -p /tmp/zola_output
zola build --base-url "$ZOLA_URL" --output-dir /tmp/zola_output --force
cp -r /tmp/zola_output/. $ZOLA_DIR
rm -rf /tmp/zola_output