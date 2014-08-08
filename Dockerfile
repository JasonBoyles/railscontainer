FROM ubuntu:14.04
MAINTAINER Jason Boyles
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential \
    git-core curl libmysqlclient-dev libpq-dev bison openssl libreadline6  \
    libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev  \
    libsqlite3-0 libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev \
    autoconf libc6-dev ssl-cert subversion nodejs

RUN cd /tmp && \
    git clone https://github.com/sstephenson/ruby-build.git && \
    cd ruby-build && \
    ./install.sh && \
    /usr/local/bin/ruby-build 2.1.2 /usr/local/

RUN gem install bundler

RUN git clone https://github.com/JasonBoyles/rails-hartl.git && \
    cd rails-hartl && \
    bundle install

# clean this mess up to minimize image size

RUN DEBIAN_FRONTEND=noninteractive apt-get purge -y \
    libmysqlclient-dev \
    libpq-dev \
    libreadline6-dev \
    zlib1g-dev \
    libssl-dev \
    libyaml-dev \
    libsqlite3-dev \
    libxml2-dev \
    libxslt1-dev

RUN apt-get clean
RUN rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/*

RUN cd rails-hartl && \
    bundle exec rake assets:precompile

ADD unicorn.conf.rb /rails-hartl/config/unicorn.conf.rb
ADD database.yml /rails-hartl/config/database.yml

WORKDIR /rails-hartl

EXPOSE 8080

ENV RAILS_ENV production

ENTRYPOINT bundle exec rake db:migrate && bundle exec unicorn -c config/unicorn.conf.rb
