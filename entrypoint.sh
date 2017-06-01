#!/bin/sh
set -e

# remove trailing / if any.
SELF_URL_PATH=${SELF_URL_PATH/%\//}

# extract the root path from SELF_URL_PATH (i.e http://domain.tld/<root_path>).
ROOT_PATH=${SELF_URL_PATH/#http*\:\/\/*\//}
if [ "${ROOT_PATH}" == "${SELF_URL_PATH}" ]; then
    # no root path in SELF_URL_PATH.
    mkdir -p /var/tmp
    ln -sf "/var/www" "/var/tmp/www"
else
    mkdir -p /var/tmp/www
    ln -sf "/var/www" "/var/tmp/www/${ROOT_PATH}"
fi

COUNTER=0
until nc -v -z -w3 $DB_HOST $DB_PORT; do
    echo -n "Checking for open database port - "
    if [ $COUNTER -ge 9 ]; then
      echo "Database seems not ready yet. Stop trying after $COUNTER retries."
      break
    fi
    echo "Database seems not ready yet."
    sleep 3
    let COUNTER=COUNTER+1
done

if [ $COUNTER -gt 0 ]; then
  sleep 5
fi

php /configure.php
exec supervisord -c /etc/supervisor/conf.d/supervisord.conf
