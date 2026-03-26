#!/bin/sh

#create conditions to if file /usr/local/bin/wp exists. If it doesnt exit, do the install. else, dont reinstall on top in volume
if [ ! -f "wp-cli.phar" ]; then
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
#creates the wp exec instead of calling php wp-cli.phar each time
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
fi
