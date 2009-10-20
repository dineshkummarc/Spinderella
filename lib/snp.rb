lib_path = File.dirname(__FILE__)
$LOAD_PATH.unshift(lib_path) unless $LOAD_PATH.include?(lib_path)
require 'perennial'
require 'eventmachine'
require 'yajl'
require 'digest/sha2'

# Salt N Pepper!
# Push it - Push it real good!
module SNP
  include Perennial
  
  VERSION = "0.0.1"
  
  manifest do |m, l|
    Settings.root = __FILE__.to_pathname.dirname.dirname
    l.register_controller :server, 'SNP::Server'
  end
  
  has_library :connection, :server, :publisher, :user, :channel
  
end