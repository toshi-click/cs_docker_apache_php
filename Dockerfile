FROM centos:7

ENV HTTPD_VERSION=2.4.48 \
    APR_VERSION=1.7.0 \
    APR_UTIL_VERSION=1.6.1 \
    PHP_VERSION=8.0.7 \
    LIBZIP_VERSION=1.7.3 \
    PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig

# Apacheのグループとユーザ作成
RUN groupadd -g 500 apache
RUN useradd -u 500 -g apache apache

# EPELを導入しておく + yum update + editor install
RUN echo "include_only=.jp" >> /etc/yum/pluginconf.d/fastestmirror.conf && \
    yum -q clean all && \
    yum -y -q install epel-release && \
    yum -y -q update && \
    rm -f /etc/rpm/macros.image-language-conf && \
    sed -i '/^override_install_langs=/d' /etc/yum.conf && \
    yum reinstall -y -q glibc-common && \
    yum -y -q groupinstall "Development Tools" && \
    yum install -y -q vim kbd ibus-kkc vlgothic-* && \
    yum -q clean all

# set locale
ENV LANG="ja_JP.UTF-8" \
    LANGUAGE="ja_JP:ja" \
    LC_ALL="ja_JP.UTF-8"

RUN localedef -f UTF-8 -i ja_JP ja_JP.UTF-8 && \
    echo 'LANG="ja_JP.UTF-8"' >  /etc/locale.conf && \
    echo 'ZONE="Asia/Tokyo"' > /etc/sysconfig/clock && \
    unlink /etc/localtime && \
    ln -s /usr/share/zoneinfo/Japan /etc/localtime

# apache base setting + 必要パッケージインストール
# + 便利ツール入れておく
RUN yum install -y -q pcre \
    pcre-devel \
    make \
    cmake3 \
    openssl \
    openssl-devel \
    wget \
    git \
    expat-devel \
    re2c \
    php-devel \
    zip \
    unzip \
    libxml2 \
    libxml2-devel \
    openssl \
    openssl-devel \
    libjpeg \
    libjpeg-devel \
    libpng \
    libpng-devel \
    curl \
    curl-devel \
    libmcrypt \
    libmcrypt-devel \
    libjpeg-devel \
    libpng10-devel \
    libXpm-devel \
    freetype \
    freetype-devel \
    php-pgsql \
    postgresql-devel \
    php-mysql \
    mariadb-server \
    gcc && \
    yum -q clean all && \
    mkdir -p /usr/local/src/apache

WORKDIR /usr/local/src/apache
RUN wget -nv -q http://ftp.tsukuba.wide.ad.jp/software/apache//httpd/httpd-${HTTPD_VERSION}.tar.gz && \
    wget -nv -q http://ftp.riken.jp/net/apache//apr/apr-${APR_VERSION}.tar.gz && \
    wget -nv -q http://ftp.riken.jp/net/apache//apr/apr-util-${APR_UTIL_VERSION}.tar.gz && \
    tar xzf httpd-${HTTPD_VERSION}.tar.gz && \
    rm -fr httpd-${HTTPD_VERSION}.tar.gz && \
    tar xzf apr-${APR_VERSION}.tar.gz && \
    rm -fr apr-${APR_VERSION}.tar.gz && \
    tar xzf apr-util-${APR_UTIL_VERSION}.tar.gz && \
    rm -fr apr-util-${APR_UTIL_VERSION}.tar.gz && \
    mkdir -p /usr/local/httpd

WORKDIR /usr/local/src/apache/apr-${APR_VERSION}
RUN ./configure \
    --silent \
    --prefix=/usr/local/apr-${APR_VERSION} && \
    make --silent && \
    make install --silent && \
    rm -fr /usr/local/src/apache/apr-${APR_VERSION}

WORKDIR /usr/local/src/apache/apr-util-${APR_UTIL_VERSION}
RUN ./configure \
    --silent \
    --prefix=/usr/local/apr-util-${APR_UTIL_VERSION} \
    --with-apr=/usr/local/apr-${APR_VERSION} && \
    make --silent && \
    make install --silent && \
    rm -fr /usr/local/src/apache/apr-util-${APR_UTIL_VERSION}

WORKDIR /usr/local/src/apache/httpd-${HTTPD_VERSION}/
RUN ./configure \
    --silent \
    --prefix=/usr/local/httpd \
    --with-apr=/usr/local/apr-${APR_VERSION} \
    --with-apr-util=/usr/local/apr-util-${APR_UTIL_VERSION} \
    --enable-so \
    --enable-proxy \
    --enable-rewrite \
    --with-mpm=prefork \
    --enable-ssl && \
    make --silent && \
    make install --silent && \
    echo "application/x-httpd-php php html" >> /usr/local/httpd/conf/mime.types && \
    chown -R apache:apache /usr/local/apr-${APR_VERSION} && \
    chown -R apache:apache /usr/local/apr-util-${APR_UTIL_VERSION} && \
    chown -R apache:apache /usr/local/httpd && \
    rm -fr /usr/local/src/apache/httpd-${HTTPD_VERSION}

WORKDIR  /usr/local/src/
RUN wget https://libzip.org/download/libzip-${LIBZIP_VERSION}.tar.gz \
    && tar xzf libzip-${LIBZIP_VERSION}.tar.gz \
    && rm -fr libzip-${LIBZIP_VERSION}.tar.gz \
    && cd libzip-${LIBZIP_VERSION} \
    && cmake3 . \
    && make install

# PHP
RUN yum install -y -q sqlite-devel \
    oniguruma-devel && \
    yum -q clean all

WORKDIR  /usr/local/src/
RUN curl -SL https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz -o php-${PHP_VERSION}.tar.gz && \
    tar xzf php-${PHP_VERSION}.tar.gz && \
    rm -fr php-${PHP_VERSION}.tar.gz

# PHPインストール
WORKDIR /usr/local/src/php-${PHP_VERSION}
RUN ./configure \
    --silent \
    --enable-bcmath \
    --enable-cli \
    --enable-exif \
    --enable-gd \
    --enable-gd-jis-conv \
    --enable-mbregex \
    --enable-mbstring \
    --enable-soap \
    --enable-sockets \
    --with-apxs2=/usr/local/httpd/bin/apxs \
    --with-pgsql=/usr/local/src/php-${PHP_VERSION}/ext/pgsql \
    --with-mysqli=mysqlnd \
    --with-pdo-mysql=mysqlnd \
    --with-curl \
    --with-freetype \
    --with-jpeg \
    --with-libdir=lib64 \
    --with-libxml \
    --with-openssl \
    --with-pear \
    --with-xpm \
    --with-zip \
    --with-zlib
RUN make --silent && \
    make install --silent && \
    pecl install --nocompress mailparse && \
    pecl install redis && \
    pecl install zip && \
    rm -fr /usr/local/src/php-${PHP_VERSION}

# apacheのコマンドすぐ使いたいかもしれないからdir移動
WORKDIR /usr/local/httpd/bin

##############################################################################
# conf類は変わる可能性が高いから最後に書くこと！！
##############################################################################
# httpd.confの設置
ADD httpd.conf /usr/local/httpd/conf/httpd.conf
# httpd-vhostsの設置
ADD httpd-vhosts.conf /usr/local/httpd/conf/extra/httpd-vhosts.conf

# php設定ファイル設置
ADD php.ini /usr/local/lib/php.ini
# 実行時にコマンド実行
ADD run /usr/local/bin/run

RUN chmod +x /usr/local/bin/run

RUN mkdir -p /var/log/httpd

EXPOSE 80 443

ENTRYPOINT ["/usr/local/bin/run"]
