#!/usr/bin/env ruby

require 'json'
require 'net/http'
require 'tempfile'

def rtmp_download(uri, out_base)
    out = "#{out_base}.mp4"
    host = nil
    path = nil
    
    if uri =~ /(.*)\/(\w+:.*)/
        host = $1
        path = $2
    else
        raise "Could not parse uri: #{uri}"
    end

    tmp_file = nil
    Tempfile.open('rtmpdump', './') do |f|
        tmp_file = f.path
    end

    cmd = "rtmpdump -r \"#{host}\" -y \"#{path}\" -o \"#{tmp_file}\""
    code = system("rtmpdump -r \"#{host}\" -y \"#{path}\" -o \"#{tmp_file}\"")

    if( code )
        system("ffmpeg -i #{tmp_file} -vcodec copy -acodec copy #{out}")
        File.delete(tmp_file)
    else
        puts "Command #{cmd} failed"
        File.delete(tmp_file)
    end
end

def mms_download(uri, out_base)
    out = "#{out_base}.wmv"

    tmp_file = nil
    Tempfile.open('rtmpdump', './') do |f|
        tmp_file = f.path
    end

    cmd = "mplayer \"#{uri}\" -dumpstream -dumpfile #{tmp_file}"
    system("mplayer \"#{uri}\" -dumpstream -dumpfile #{tmp_file}")

    if( code )
        File.rename(tmp_file, out)
    else
        puts "Command #{cmd} failed"
        File.delete(tmp_file)
    end

end

def download_file(file_name)
    out = nil
    if file_name =~ /(.*)\.json/
        out = "#{$1}"
    else
        puts "Only json files are supported, skipping: #{file_name}"
        return
    end

    if File.exists?( "#{out}.mp4" )
        puts "Skipping #{file_name} as #{out}.mp4 allready exists"
        return
    end

    if File.exists?( "#{out}.flv" )
        puts "Skipping #{file_name} as #{out}.flv allready exists"
        return
    end

    if File.exists?( "#{out}.wmv" )
        puts "Skipping #{file_name} as #{out}.wmv allready exists"
        return
    end
    
    jfile = File.read(file_name)
    descriptor = JSON.parse(jfile)
    
    resource_req = Net::HTTP.get_response(URI.parse(descriptor['videoResourceUrl']))
    resource = JSON.parse(resource_req.body)
    
    bitrate = 0
    r_link = nil
    
    resource['links'].each  do |link|
        if link['bitrateKbps'].to_i > bitrate
            r_link = link
            bitrate = link['bitrateKbps']
        end
    end
    
    uri = r_link['uri']

    if uri =~ /^rtmp:\/\//
        rtmp_download(uri, out)
    elsif uri =~ /^mms:\/\//
        mms_download(uri, out)
    else
        raise "unknown protocol in uri: #{uri}"
    end
end

ARGV.each do |f|
    download_file(f)
end

