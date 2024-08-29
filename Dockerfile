FROM ruby:3.3-slim

ENV TZ=Asia/Shanghai

ADD . /app
WORKDIR /app

RUN apt update -y \
  && apt install -y build-essential \
  && bundle install \
  && apt remove -y build-essential

CMD [ "bundle", "exec", "jekyll", "serve", "-l", "-H", "0.0.0.0" ]
