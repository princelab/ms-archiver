require 'rubygems'
require 'bundler'

TESTFILE = File.dirname(__FILE__) + '/tfiles'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'bacon'
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'archiver'
require 'mount_mapper'
require 'eksigent'


Bacon.summary_on_exit
