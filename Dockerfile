FROM centos:7

# 作成者情報
MAINTAINER toshi <toshi@toshi.click>

ENV HTTPD_VERSION=2.4.33 \
    APR_VERSION=1.6.3 \
    APR_UTIL_VERSION=1.6.1 \
    PHP_VERSION=7.2.3

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





