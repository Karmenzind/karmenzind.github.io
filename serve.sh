case $1 in
--build)
  docker build -t blog .
  ;;
--test)
  docker run -it \
    --rm \
    -v $PWD:/app \
    blog \
    bundle exec htmlproofer _site \
    --disable-external \
    --ignore-urls "/^http:\/\/127.0.0.1/,/^http:\/\/0.0.0.0/,/^http:\/\/localhost/"
  ;;
*)
  docker run -it \
    --name=xxx \
    --rm \
    -v $PWD:/app \
    -p 4000:4000 \
    blog
  ;;
esac
