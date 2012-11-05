#!/usr/bin/env ruby

require 'date'
require 'json'
require 'net/http'

def format_data(time)
    begin
        o = DateTime.parse(time)
        return "%04d-%02d-%02d" % [o.year, o.month, o.day]
    rescue
        return "0000-00-00"
    end
end

def get_file_name( json )
    serie = json['programSerieSlug']
    date = format_data(json['broadcastTime'])
    id = json['id']

    return "#{serie}_#{date}_ID#{id}.json"
end

def walk_dir dir
    list = []
    Dir.glob("#{dir}/*").each do |f|
        if File.file?(f) and File.extname(f) == ".json"
            list << f
        elsif File.directory?(f)
            list.concat walk_dir(f)
        end
    end

    return list
end

def delete_empty_folders dir
    Dir.glob("#{dir}/*").each do |f|
        if File.directory?(f)
            _l =  delete_empty_folders f
            if _l == 0
                Dir.rmdir f
            end
        end
    end

    return Dir.glob("#{dir}/*").length
end

puts "Updating index"
index_req = Net::HTTP.get_response(URI.parse("http://www.dr.dk/nu/api/videos/all"))

File.open("dr_index.json", 'w') do |f|
    f.write(index_req.body)
end

index = JSON.parse(index_req.body)

#file = File.open("dr_index.json", "rb")
#index = JSON.parse(file.read)

existing_element = walk_dir "dr"

if( not File.directory?("dr") )
    Dir.mkdir("dr")
end

cnt = 0
added_elements = []
index.each do |x|
    serie = x['programSerieSlug']
    serie_path = "dr/#{serie}"

    if (not File.directory?(serie_path))
        Dir.mkdir(serie_path)
    end

    path = "dr/#{serie}/#{get_file_name( x )}"
    added_elements << path

    File.open(path, 'w') do |f|
        f.write(JSON.generate(x))
    end

end

new_elements = added_elements - existing_element
del_elements = existing_element - added_elements

del_elements.each do |x|
    File.delete(x)
end

delete_empty_folders "dr"
