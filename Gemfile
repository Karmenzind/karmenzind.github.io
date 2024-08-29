# frozen_string_literal: true

source "https://rubygems.org"

gem "jekyll-theme-chirpy", "~> 7.1"

gem "html-proofer", "~> 5.0", group: :test

group :jekyll_plugins do
  gem 'jekyll-spaceship'
end

platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

gem "wdm", "~> 0.1.1", :platforms => [:mingw, :x64_mingw, :mswin]

# XXX (k): <2024-08-29 17:12> not sure if necessary
gem "rake"
gem "http_parser.rb"
if RUBY_PLATFORM =~ /linux-musl/
  gem "jekyll-sass-converter"
end
