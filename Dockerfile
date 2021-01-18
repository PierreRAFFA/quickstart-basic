####################################
# Application Stage
####################################
FROM php:7.4-fpm as app-stage

# Copy composer.lock and composer.json
COPY composer.lock composer.json /var/www/

# Set working directory
WORKDIR /var/www

# Install dependencies
RUN apt-get update && apt-get install -y \
    zip \
    unzip \
    git

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install extensions
RUN docker-php-ext-install pdo_mysql

# Install composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy existing application directory contents
COPY . /var/www

# Copy existing application directory permissions
COPY --chown=www-data:www-data . /var/www

# Install dependencies
RUN composer install

USER www-data


####################################
# nginx Stage
####################################
FROM nginx:1.17-alpine AS nginx-stage

# Nginx only needs to have the files in 'public/'. The other php files to only exist in the php image
COPY infrastructure/nginx/conf.d/app.conf /etc/nginx/conf.d/default.conf
COPY public /var/www/public