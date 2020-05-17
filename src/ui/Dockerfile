FROM ruby:2.2-alpine

ENV APP_HOME /app
RUN mkdir $APP_HOME

WORKDIR $APP_HOME
ADD Gemfile* $APP_HOME/
ADD . $APP_HOME

# https://gist.github.com/mniehe/25b45e8397e189f4b95cce31a192d2a4
RUN apk add --no-cache --virtual build-dependencies build-base \
    && gem install bundler -v "1.17.2" \
    && bundle install \
    && apk del build-dependencies

ENV POST_SERVICE_HOST post
ENV POST_SERVICE_PORT 5000
ENV COMMENT_SERVICE_HOST comment
ENV COMMENT_SERVICE_PORT 9292

CMD ["puma"]
