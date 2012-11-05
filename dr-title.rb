#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'tempfile'

def show(file_name)
    jfile = File.read(file_name)
    descriptor = JSON.parse(jfile)
    
    puts "#{file_name} #{descriptor['title']}"

end

ARGV.each do |f|
    show(f)
end

