FROM ruby:alpine

RUN apk update && \
    apk add build-base rsync openssh && \
    gem install bundler

ADD images /blog/images
ADD pages /blog/pages
ADD posts /blog/posts
ADD css /blog/css
ADD js /blog/js
ADD source /blog/source
ADD Gemfile Gemfile.lock /blog/

WORKDIR /blog

RUN bundle install && \
    mkdir -p /blog/cache && apk add docker

EXPOSE 4567

ENTRYPOINT ["sh", "-c", "bundle exec weaver"]
