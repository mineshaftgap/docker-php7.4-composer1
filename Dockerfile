FROM php:7.4-fpm-alpine AS builder

ENV BUILDDATE 202107040603

RUN STARTTIME=$(date "+%s")                                                                      && \
echo "################## [$(date)] Building Interim ##################"                          && \
echo "################## [$(date)] Add Packages ##################"                              && \
apk add --no-cache mysql-client binutils                                                         && \
apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing gnu-libiconv     && \
echo "################## [$(date)] Install PHP Extensions ##################"                    && \
FILE=/install-php-extensions                                                                     && \
URL=https://github.com/mlocati/docker-php-extension-installer/releases/latest/download$FILE      && \
EXT="@composer-1 gd gettext igbinary mcrypt memcached mysqli opcache"                            && \
EXT="$EXT pdo_mysql pdo_pgsql pgsql redis soap sockets xdebug zip"                               && \
curl -L $URL > $FILE                                                                             && \
sh $FILE $EXT                                                                                    && \
echo "################## [$(date)] Make PHP user ##################"                             && \
adduser -h /usr/local/drush -s /bin/sh -D -H -u 1971 php                                         && \
echo "################## [$(date)] Clean up container/put on a diet ##################"          && \
find /bin /lib /sbin /usr/bin /usr/lib /usr/sbin /usr/local/bin /usr/local/lib /usr/local/sbin      \
  -type f -exec strip -v {} \;                                                                   && \
cd /usr/bin                                                                                      && \
rm -vrf $FILE /var/cache/apk/* /var/cache/distfiles/*                                               \
  mysql_waitpid mysqlimport mysqlshow mysqladmin mysqlcheck mysqldump myisam_ftdump                 \
  $DRUSHDIR/composer.* $DRUSHCMDS/.composer /usr/src/php.tar.xz /usr/local/include/php           && \
cd /usr/local/bin                                                                                && \
rm -rfv docker-* pear* phar* pecl phpdbg phpize php-config                                       && \
apk del libc-utils musl-utils xz                                                                 && \
echo "################## [$(date)] Done ##################"                                      && \
echo "################## Elapsed: $(expr $(date "+%s") - $STARTTIME) seconds ##################"

FROM scratch
LABEL IF Fulcrum "fulcrum@ifsight.net"
COPY --from=builder / /
ADD healthcheck.sh /healthcheck.sh
