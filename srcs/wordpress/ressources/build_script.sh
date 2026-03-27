#!/bin/sh

echo "in build_script.sh"
#creates the wp exec instead of calling php wp-cli.phar each time
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
