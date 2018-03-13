FROM ruby:2.5.0-alpine3.7

LABEL maintainer="https://github.com/tootsuite/mastodon" \
      description="Your self-hosted, globally interconnected microblogging community"

ARG UID=991
ARG GID=991

ENV RAILS_SERVE_STATIC_FILES=true \
    RAILS_ENV=production NODE_ENV=production

ARG LIBICONV_VERSION=1.15
ARG LIBICONV_DOWNLOAD_SHA256=ccf536620a45458d26ba83887a983b96827001e92a13847b45e4925cc8913178

EXPOSE 3000 4000

WORKDIR /mastodon

RUN apk -U upgrade \
 && apk add -t build-dependencies \
    build-base \
    icu-dev \
    libidn-dev \
    libressl \
    libtool \
    postgresql-dev \
    protobuf-dev \
    python \
 && apk add \
    ca-certificates \
    ffmpeg \
    file \
    icu-libs \
    imagemagick \
    libidn \
    libpq \
    nodejs \
    openssl \
    protobuf \
    tini \
    tzdata \
    yarn \
 && update-ca-certificates \
 && mkdir -p /tmp/src \
 && wget -O libiconv.tar.gz "https://ftp.gnu.org/pub/gnu/libiconv/libiconv-$LIBICONV_VERSION.tar.gz" \
 && echo "$LIBICONV_DOWNLOAD_SHA256 *libiconv.tar.gz" | sha256sum -c - \
 && tar -xzf libiconv.tar.gz -C /tmp/src \
 && rm libiconv.tar.gz \
 && cd /tmp/src/libiconv-$LIBICONV_VERSION \
 && ./configure CFLAGS="-O2 -march=native" --prefix=/usr/local \
 && make -j$(getconf _NPROCESSORS_ONLN)\
 && make install \
 && wget -O optipng.tar.gz "http://jaist.dl.sourceforge.net/project/optipng/OptiPNG/optipng-0.7.6/optipng-0.7.6.tar.gz" \
 && mkdir -p /tmp/src \
 && tar -xzf optipng.tar.gz -C /tmp/src \
 && rm optipng.tar.gz \
 && cd /tmp/src/optipng-0.7.6 \
 && ./configure --prefix=/usr/local \
 && make -j$(getconf _NPROCESSORS_ONLY)\
 && make install \
 && wget -O mozjpeg.tar.gz "https://github.com/mozilla/mozjpeg/releases/download/v3.2/mozjpeg-3.2-release-source.tar.gz" \
 && mkdir -p /tmp/src \
 && tar -xzf mozjpeg.tar.gz -C /tmp/src \
 && rm mozjpeg.tar.gz \
 && cd /tmp/src/mozjpeg \
 && ./configure CFLAGS="-O2 -march=native" --without-simd --prefix=/usr/local \
 && make -j$(getconf _NPROCESSORS_ONLY)\
 && make install \
 && libtool --finish /usr/local/bin \
 && cd /mastodon \
 && rm -rf /tmp/* /var/cache/apk/*

COPY Gemfile Gemfile.lock package.json yarn.lock .yarnclean /mastodon/

RUN bundle config build.nokogiri --with-iconv-lib=/usr/local/lib --with-iconv-include=/usr/local/include \
 && bundle install -j$(getconf _NPROCESSORS_ONLN) --deployment --without test development \
 && yarn --pure-lockfile \
 && yarn cache clean

RUN cd /mastodon/vendor/bundle/ruby/2.5.0/gems/paperclip-compression-0.3.16/bin/linux/x64/ \
 && mv optipng optipng_bak \
 && ln -s /usr/local/bin/optipng . \
 && cd /mastodon/vendor/bundle/ruby/2.5.0//gems/paperclip-compression-0.3.16/bin/linux/x64/ \
 && mv jpegtran jpegtran_bak \
 && ln -s /usr/local/bin/jpegtran . \
 && cd /mastodon

RUN addgroup -g ${GID} mastodon && adduser -h /mastodon -s /bin/sh -D -G mastodon -u ${UID} mastodon \
 && mkdir -p /mastodon/public/system /mastodon/public/assets /mastodon/public/packs \
 && chown -R mastodon:mastodon /mastodon/public

COPY . /mastodon

RUN chown -R mastodon:mastodon /mastodon

VOLUME /mastodon/public/system /mastodon/public/assets /mastodon/public/packs

USER mastodon

ENTRYPOINT ["/sbin/tini", "--"]
