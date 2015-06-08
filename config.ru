require 'rubygems'
require 'sinatra'
require File.expand_path '../dns.rb', __FILE__

run Sinatra::Application
