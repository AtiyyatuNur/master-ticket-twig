# Stage 1: Build the application with Composer
FROM composer:2 as builder

WORKDIR /app

# Copy only composer files to leverage Docker cache
COPY composer.json composer.lock ./

# Install dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction --prefer-dist

# Copy the rest of the application source code
COPY . .

# ---

# Stage 2: Create the final, lean production image
FROM php:8.2-apache as final

# Enable Apache mod_rewrite for clean URLs
RUN a2enmod rewrite

# Set working directory
WORKDIR /var/www/

# Copy application files from the builder stage
COPY --from=builder /app .

# Set the document root to the 'public' directory
ENV APACHE_DOCUMENT_ROOT /var/www/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf

# Fix file permissions for Apache
RUN chown -R www-data:www-data /var/www

# Expose port 80 for Apache
EXPOSE 80

# Start Apache
CMD ["apache2-foreground"]
