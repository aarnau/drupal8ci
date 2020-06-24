FROM drupal:8.8-apache

RUN apt-get update && apt-get install -y \
  apt-transport-https \
  gnupg-agent \
  software-properties-common \
  git \
  imagemagick \
  libmagickwand-dev \
  mariadb-client \
  rsync \
  sudo \
  unzip \
  vim \
  wget \
  && docker-php-ext-install bcmath \
  && docker-php-ext-install mysqli \
  && docker-php-ext-install pdo \
  && docker-php-ext-install pdo_mysql


# Setup docker
RUN echo "deb https://download.docker.com/linux/debian stretch stable" | tee /etc/apt/sources.list.d/docker.list
RUN wget --quiet --output-document - https://download.docker.com/linux/debian/gpg  | apt-key add -
RUN apt-get update
RUN apt-get install -y docker-ce
RUN usermod -aG docker $(whoami)
RUN service docker start


# Remove the memory limit for the CLI only.
RUN echo 'memory_limit = -1' > /usr/local/etc/php/php-cli.ini

# Remove the vanilla Drupal project that comes with this image.
RUN rm -rf ..?* .[!.]* *

# Change docroot since we use Composer Drupal project.
RUN sed -ri -e 's!/var/www/html!/var/www/html/web!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www!/var/www/html/web!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Install composer.
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Put a turbo on composer.
RUN composer global require hirak/prestissimo

# Install XDebug.
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# Install Robo CI.
RUN wget https://robo.li/robo.phar
RUN chmod +x robo.phar && mv robo.phar /usr/local/bin/robo

# Install Dockerize.
ENV DOCKERIZE_VERSION v0.6.0
RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

# Install ImageMagic to take screenshots.
RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Install Chrome browser.
RUN apt-get install --yes gnupg2 apt-transport-https
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
RUN sh -c 'echo "deb https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
RUN apt-get update
RUN apt-get install --yes google-chrome-unstable

# Install Cypress
