docker run -it --rm \
    --volume="$PWD:/srv/jekyll" \
    -p 0.0.0.0:4000:4000 jekyll/jekyll \
    jekyll serve
