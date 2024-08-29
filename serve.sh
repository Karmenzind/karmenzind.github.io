# docker run -it --rm \
#     --volume="$PWD:/srv/jekyll" \
#     -p 0.0.0.0:4000:4000 jekyll/jekyll:minimal \
#     jekyll serve

case $1 in
--build)
  docker build -t blog .
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
