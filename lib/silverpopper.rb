# Silverpopper; the ruby silverpop api wrapper!
module Silverpopper
  class EmailNotInListError < RuntimeError; end
end

# dependencies
require 'builder'
require 'net/ftp'
require 'httparty'
require 'rexml/document'
require 'active_support/core_ext'

# core files
require 'common.rb'
require 'transfer_api.rb'
require 'transact_api.rb'
require 'xml_api.rb'
require 'client.rb'
