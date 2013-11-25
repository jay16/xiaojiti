require 'rubygems'
require 'middleman/rack'

ENV['RACK_ENV'] = "development"
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
Bundler.require(:default, ENV['RACK_ENV'])

run Middleman.server
