#!/bin/sh
set -e

cd /project
zola build --base-url "$ZOLA_URL" --output-dir "$ZOLA_DIR" --force
# cp -r /tmp/zola_output/* /data/
# rm -rf /tmp/zola_output