FROM php:8.2-fpm

# Set working directory
WORKDIR /var/www

# Install dependensi sistem yang diperlukan
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    libzip-dev \
    libcurl4-openssl-dev \
    pkg-config \
    libssl-dev

# Bersihkan cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Install ekstensi PHP yang umum untuk Laravel
# Catatan: mbstring sudah ada di base image php:8.2, jadi tidak perlu di-install ulang
RUN docker-php-ext-install pdo_mysql bcmath gd zip pcntl

# Install ekstensi MongoDB via PECL
RUN pecl channel-update pecl.php.net \
    && pecl install mongodb \
    && docker-php-ext-enable mongodb

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Salin project
COPY . /var/www

# Permission
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]