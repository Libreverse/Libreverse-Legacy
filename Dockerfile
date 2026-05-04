# syntax=docker/dockerfile:1

# Use phusion/passenger-full as base image for a smaller image.
FROM phusion/passenger-ruby34:latest

# Better optimisation flags
ENV CFLAGS="-O3 -march=x86-64-v3 -pipe -flto -fno-fast-math"
ENV CXXFLAGS="-O3 -march=x86-64-v3 -pipe -flto -fno-fast-math"
ENV LDFLAGS="-flto -Wl,-O3 -Wl,-Bsymbolic-functions -Wl,--as-needed"
ENV RUBYOPT="--yjit --yjit-exec-mem-size=2 --yjit-mem-size=3 --yjit-call-threshold=1 --yjit-cold-threshold=1000000 --yjit-code-gc"

# Install mimalloc for improved memory management (with dev headers for optimization)
# Also install and configure ModSecurity (with OWASP CRS) for WAF protection
RUN set -eux; \
        rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock || true; \
        apt-get update; \
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            build-essential cmake git \
            libsnappy-dev libtool automake autoconf \
            libmodsecurity3 libnginx-mod-http-modsecurity modsecurity-crs \
            shared-mime-info coreutils imagemagick unzip \
            libnginx-mod-http-ndk libnginx-mod-http-lua lua5.1 lua-cjson luarocks gettext-base sudo \
        ; \
        # Install the correct mimalloc runtime shared library for this Ubuntu release
        if apt-cache show libmimalloc3 >/dev/null 2>&1; then \
            DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libmimalloc3; \
        elif apt-cache show libmimalloc2.1 >/dev/null 2>&1; then \
            DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libmimalloc2.1; \
        else \
            DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libmimalloc2.0; \
        fi; \
        mkdir -p /etc/modsecurity; \
        ln -sf /usr/share/modsecurity-crs/rules /etc/modsecurity/rules || true; \
        (ln -sf /usr/share/nginx/modules-available/mod-http-modsecurity.conf /etc/nginx/modules-enabled/50-mod-http-modsecurity.conf || true); \
    # Prepare TLS directory for user-provided certs
    mkdir -p /etc/nginx/ssl; \
    chmod 700 /etc/nginx/ssl; \
    rm -rf /var/lib/apt/lists/*

# Provide consolidated main include for ModSecurity rules (copied later before Nginx reload)
COPY docker/modsecurity/modsecurity.conf /etc/modsecurity/modsecurity.conf
COPY docker/modsecurity-main.conf /etc/modsecurity/main.conf
COPY docker/modsecurity-overrides_pre.conf /etc/modsecurity/overrides_pre.conf
COPY docker/modsecurity-overrides.conf /etc/modsecurity/overrides.conf
# Use the CRS setup template to ensure tx.crs_setup_version is set
# Try common package locations, fall back to upstream if missing
RUN set -eux; \
        if [ -f /usr/share/modsecurity-crs/crs-setup.conf.example ]; then \
            cp /usr/share/modsecurity-crs/crs-setup.conf.example /etc/modsecurity/crs-setup.conf; \
        elif [ -f /usr/share/doc/modsecurity-crs/examples/crs-setup.conf.example.gz ]; then \
            zcat /usr/share/doc/modsecurity-crs/examples/crs-setup.conf.example.gz > /etc/modsecurity/crs-setup.conf; \
        elif [ -f /usr/share/doc/modsecurity-crs/examples/crs-setup.conf.example ]; then \
            cp /usr/share/doc/modsecurity-crs/examples/crs-setup.conf.example /etc/modsecurity/crs-setup.conf; \
        else \
            curl -fsSL https://raw.githubusercontent.com/coreruleset/coreruleset/v3.3.5/crs-setup.conf.example -o /etc/modsecurity/crs-setup.conf; \
        fi
# Fetch full upstream unicode.mapping (rather than storing a local stub)
RUN curl -fsSL https://raw.githubusercontent.com/SpiderLabs/ModSecurity/v3/master/unicode.mapping -o /etc/modsecurity/unicode.mapping

# Set correct environment variables.
ENV HOME=/root

# Enable Nginx and Passenger
RUN rm -f /etc/service/nginx/down

# Set working directory for app
WORKDIR /home/app/webapp

## Copy Gemfile and Gemfile.lock first for efficient caching
COPY Gemfile Gemfile.lock ./

## Copy .gitmodules and initialize submodules, then copy vendored gem
COPY .gitmodules ./
COPY vendor/gems/google_robotstxt_parser ./vendor/gems/google_robotstxt_parser

## Populate google/robotstxt and abseil-cpp sources without requiring a git repo context
RUN set -eux; \
        # Clone robotstxt at pinned commit if sources are missing
        if [ ! -f vendor/gems/google_robotstxt_parser/ext/robotstxt/robotstxt/robots.cc ]; then \
            rm -rf vendor/gems/google_robotstxt_parser/ext/robotstxt/robotstxt; \
            git clone https://github.com/google/robotstxt vendor/gems/google_robotstxt_parser/ext/robotstxt/robotstxt; \
            git -C vendor/gems/google_robotstxt_parser/ext/robotstxt/robotstxt checkout 86d5836ba2d5a0b6b938ab49501be0e09d9c276c; \
            rm -rf vendor/gems/google_robotstxt_parser/ext/robotstxt/robotstxt/.git; \
        fi; \
        # Clone abseil-cpp at LTS tag 20250127.1 if sources are missing
        if [ ! -f vendor/gems/google_robotstxt_parser/ext/robotstxt/abseil-cpp/CMakeLists.txt ]; then \
            rm -rf vendor/gems/google_robotstxt_parser/ext/robotstxt/abseil-cpp; \
            git clone --branch 20250127.1 --depth 1 https://github.com/abseil/abseil-cpp vendor/gems/google_robotstxt_parser/ext/robotstxt/abseil-cpp; \
            rm -rf vendor/gems/google_robotstxt_parser/ext/robotstxt/abseil-cpp/.git; \
        fi

## Install production gems (exclude development & test groups) with verbose logs
## and verify the vendored gem is present and loadable
RUN bash -lc 'RUBY_VER=$(ls -1 /usr/local/rvm/rubies/ | grep "^ruby-3\\.4" | sort -V | tail -1) \
    && rvm --default use "$RUBY_VER" \
    && bundle config set without "development test" \
    && bundle install --jobs=$(nproc) --retry 3 --verbose \
    && bundle info google_robotstxt_parser \
    && ruby -e "require \"bundler/setup\"; require \"google_robotstxt_parser\"; puts(\"Robotstxt loaded: #{!!defined?(Robotstxt)}\")"'

# Copy package.json and bun.lock for JS dependencies
COPY package.json bun.lock ./

# Install Bun (for JS package management and build only)
ENV BUN_INSTALL=/usr/local/bun
ENV PATH=/usr/local/bun/bin:$PATH
RUN curl -fsSL https://bun.sh/install | bash -s -- "bun-v1.2.5"

# Copy the rest of the application code (including vendor/)
COPY . .

# Ensure correct ownership for the app user (before bun install, so node_modules is not affected)
RUN chown -R app:app /home/app/webapp

# Now install JS dependencies (vendor/javascript/p2p should exist)
RUN bun install --frozen-lockfile

# Precompile Rails bootsnap cache
RUN bash -lc 'RUBY_VER=$(ls -1 /usr/local/rvm/rubies/ | grep "^ruby-3\\.4" | sort -V | tail -1) \
    && rvm --default use "$RUBY_VER" \
    && bundle exec bootsnap precompile app/ lib/'

# Precompile assets with vite (using bun)
# vite-plugin-erb shells out to Ruby for .js.erb files (e.g. Thredded),
# so RVM + Bundler must be on the PATH.
RUN bash -lc 'RUBY_VER=$(ls -1 /usr/local/rvm/rubies/ | grep "^ruby-3\\.4" | sort -V | tail -1) \
    && rvm use "$RUBY_VER" \
    && RUBYOPT="-rbundler/setup" SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production VITE_RUBY_MODE=production \
       bun run build \
    && rm -rf public/vite-dev public/vite-test'

# Compile Shakapacker (webpack) packs — required by javascript_pack_tag in layouts.
# This populates public/packs/manifest.json; must run after bun install.
RUN bash -lc 'RUBY_VER=$(ls -1 /usr/local/rvm/rubies/ | grep "^ruby-3\\.4" | sort -V | tail -1) \
    && rvm use "$RUBY_VER" \
    && RUBYOPT="-rbundler/setup" SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production \
       bundle exec rails shakapacker:compile'

# Remove default Nginx site and add custom config for Rails app
RUN rm /etc/nginx/sites-enabled/default
RUN mkdir -p /etc/nginx/conf.d /etc/nginx/main.d
COPY docker/webapp.conf /etc/nginx/sites-enabled/webapp.conf
COPY docker/passenger.conf /etc/nginx/passenger.conf
# Add Libreverse HTTP context customizations without replacing base nginx.conf
COPY docker/nginx-libreverse.conf /etc/nginx/conf.d/20-libreverse.conf
RUN printf '%s\n' \
    '# Send Passenger logs to container stderr so they are captured by the orchestrator' \
    'passenger_log_file /dev/stderr;' \
    > /etc/nginx/conf.d/10-passenger-base.conf
    
# Create temp directories for NGINX and Passenger buffering
RUN mkdir -p /home/app/webapp/tmp/nginx_body /home/app/webapp/tmp/passenger /home/app/webapp/tmp/modsec \
    && chown -R app:app /home/app/webapp/tmp \
    && chmod -R 750 /home/app/webapp/tmp

# Install CrowdSec (LAPI + agent) from official repo and NGINX bouncer Lua component
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl ca-certificates; \
    # Prevent systemctl/postinst failures in non-systemd container
    ln -sf /bin/true /usr/bin/systemctl; \
    printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d; chmod +x /usr/sbin/policy-rc.d; \
    curl -fsSL https://install.crowdsec.net | bash; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends crowdsec; \
    mkdir -p /etc/crowdsec/acquis.d; \
    touch /etc/crowdsec/acquis.yaml; \
    # Disable agent; run LAPI only and explicitly enable API server
    printf 'crowdsec_service:\n  enable: false\napi:\n  server:\n    enable: true\n    listen_uri: 127.0.0.1:8080\n' > /etc/crowdsec/config.yaml.local; \
    mkdir -p /etc/crowdsec/bouncers; \
    curl -fsSL -o /tmp/crowdsec-nginx-bouncer.tgz https://github.com/crowdsecurity/cs-nginx-bouncer/releases/download/v1.1.3/crowdsec-nginx-bouncer.tgz; \
    tar -xzf /tmp/crowdsec-nginx-bouncer.tgz -C /tmp; \
    cd /tmp/crowdsec-nginx-bouncer-*; \
    ./install.sh; \
    rm -rf /tmp/crowdsec-nginx-bouncer* /var/lib/apt/lists/*

# Provide a minimal deny-only config for the Lua bouncer
COPY docker/crowdsec-nginx-bouncer.conf /etc/crowdsec/bouncers/crowdsec-nginx-bouncer.conf

# Create runit service for Solid Queue worker process
RUN mkdir -p /etc/service/worker
COPY docker/worker.sh /etc/service/worker/run
RUN chmod +x /etc/service/worker/run

# Create runit service for CrowdSec LAPI/agent
RUN mkdir -p /etc/service/crowdsec
COPY docker/crowdsec-run.sh /etc/service/crowdsec/run
RUN chmod +x /etc/service/crowdsec/run

# Create runit service for gRPC server (standalone)
RUN mkdir -p /etc/service/grpc
COPY docker/grpc-run.sh /etc/service/grpc/run
RUN chmod +x /etc/service/grpc/run

# Add a one-shot runit service to wait for LAPI and then bootstrap the bouncer
RUN mkdir -p /etc/service/crowdsec-bootstrap
COPY docker/wait-for-lapi.sh /etc/service/crowdsec-bootstrap/run
RUN chmod +x /etc/service/crowdsec-bootstrap/run

# Ensure bootstrap helper is executable
RUN chmod +x /home/app/webapp/docker/crowdsec-bootstrap.sh || true

# Clean up APT when done
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add entrypoint script to launch app with mimalloc and run migrations, then exec my_init
COPY docker/entrypoint-with-mimalloc.sh /usr/local/bin/entrypoint-with-mimalloc.sh
RUN chmod +x /usr/local/bin/entrypoint-with-mimalloc.sh

# Create log directory and ensure proper permissions for volume mounting
RUN mkdir -p /home/app/webapp/log && \
    chown -R app:app /home/app/webapp/log && \
    chmod -R 755 /home/app/webapp/log

# Use baseimage-docker's init process, but override to use mimalloc for app
ENV DISABLE_AGENT=true

# Non-sensitive runtime defaults (baked into the image)
ENV RAILS_ENV=production \
    RACK_ENV=production \
    BUNDLE_GEMFILE=/home/app/webapp/Gemfile \
    GRPC_HOST=127.0.0.1 \
    GRPC_ALLOW_INSECURE=true
CMD ["/usr/local/bin/entrypoint-with-mimalloc.sh"]

# Expose application ports (HTTP and gRPC)
EXPOSE 3000

# Create volume for logs to make them accessible from host
VOLUME ["/home/app/webapp/log"]
