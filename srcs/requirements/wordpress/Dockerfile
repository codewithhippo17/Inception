FROM alpine:3.19

# Install PHP-FPM, necessary extensions for WordPress, and CLI tools
RUN apk update && apk add --no-cache \
    php82 php82-fpm php82-mysqli php82-curl \
    php82-json php82-mbstring php82-xml php82-zip \
    php82-phar php82-iconv mariadb-client curl wget tar

# Install WP-CLI for automated WordPress configuration
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Copy custom PHP-FPM pool configuration
COPY conf/www.conf /etc/php82/php-fpm.d/www.conf

# Copy and set up the entrypoint script
COPY tools/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Subject requirement: volumes will be mounted here
WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
# Subject requirement: Do not use daemon hacks. -F forces foreground.
CMD ["php-fpm82", "-F"]