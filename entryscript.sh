#!/bin/sh
set -e
role=${CONTAINER_ROLE:-app}
path=${CONTAINER_PATH:-'/var/www'}
echo ${role}
if [ "$role" = "queue" ]; then
    echo "Running the horizon..."
    cd $path
    php artisan horizon
elif [ "$role" = "scheduler" ]; then
    echo "Running the scheduler..."
    cd $path
    while [ true ]
    do
      php artisan schedule:run --verbose --no-interaction &
      sleep 60
    done
elif [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi
exec "$@"
