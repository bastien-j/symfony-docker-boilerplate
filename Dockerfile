FROM php:8-apache-bullseye

ENV APACHE_DOCUMENT_ROOT /app

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}/public!g' /etc/apache2/sites-available/*.conf \
  && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}/public!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf \
  && echo 'deb [trusted=yes] https://repo.symfony.com/apt/ /' | tee /etc/apt/sources.list.d/symfony-cli.list \
  && apt-get update \
  && apt-get install -yq --no-install-recommends \
    apt-utils \
    git \
		libicu-dev \
		libpq-dev \
		libzip-dev \
    locales \
    symfony-cli \
    unzip \
  && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen \
  && echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen \
  && locale-gen

# Copy the composer binary from the official composer image
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Use the default development configuration
RUN cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

RUN docker-php-ext-configure intl \
  && docker-php-ext-configure zip

RUN docker-php-ext-install -j$(nproc) intl pdo_pgsql pgsql zip

RUN pecl install apcu && docker-php-ext-enable apcu opcache

RUN a2enmod rewrite

WORKDIR ${APACHE_DOCUMENT_ROOT}
