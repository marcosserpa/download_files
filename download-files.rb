#!/usr/bin/env ruby

# Ruby script to download .wav files from individual URLs via HTTP/HTTPS/FTP specified in an external file.
# Author: Marcos Serpa (base code from Tobias Preuss)
# License: Creative Commons Attribution-ShareAlike 3.0 Unported

require 'net/http'
require 'net/ftp'
require 'uri'
require 'date'


# Saves the sources of the .wav files into sources.txt
def save_sources(letter)
  url = URI.parse("http://www.elearnspanishlanguage.com/pronunciation/audiodictionary-#{letter}.html")

  # Saves the HTML content
  response = Net::HTTP.start(url.host, url.port) { |http| http.get("/pronunciation/audiodictionary-#{letter}.html") }

  open("sources.txt", "w") { |file|
    response.body.lines.each do |line|
      word = ""
      word = /(?<=\/sounds\/)\w+(?=.wav)/.match(line).to_s

      if word.eql?("") == false
        resp = "http://www.elearnspanishlanguage.com/sounds/#{word}.wav #{word}.wav\n"
        file << resp
      end
    end
  }

  puts "All sources with the letter #{letter} writed in sources.txt!!"
end

def create_directory(dirname, letter)
  unless Dir.exists?("Downloads (#{dirname}) - Letter #{letter}")
    Dir.mkdir("Downloads (#{dirname}) - Letter #{letter}")
  else
    puts "Skipping creating directory 'Downloads (#{dirname}) - Letter #{letter}'. It already exists."
  end

  "Downloads (#{dirname}) - Letter #{letter}"
end

def read_uris_from_file(file)
  uris = Array.new

  File.open(file).each do |line|
    line = line.strip

    next if line == nil || line.length == 0

    parts = line.split(' ')
    pair = Hash[ [:resource, :filename].zip(parts) ]
    uris.push(pair)
  end

  uris
end

# Decides the download method by the protocol
def download_resource(resource, filename)
  uri = URI.parse(resource)

  case uri.scheme.downcase
  when /http|https/
    http_download_uri(uri, filename)
  when /ftp/
    ftp_download_uri(uri, filename)
  else
    puts "Unsupported URI protocol in " + resource + "."
  end
end

def http_download_uri(uri, filename)
  puts "Starting HTTP download for: " + uri.to_s

  http_object = Net::HTTP.new(uri.host, uri.port)
  http_object.use_ssl = true if uri.scheme == 'https'

  begin
    http_object.start do |http|
      request = Net::HTTP::Get.new uri.request_uri

      http.read_timeout = 500

      http.request(request) do |response|
        open(filename, 'w') do |io|
          response.read_body do |chunk|
            io.write chunk
          end
        end
      end
    end
  rescue Exception => e
    puts "=> Exception: '#{e}'. Skipping download."

    return
  end

  puts "Stored download as " + filename + "."
end

def ftp_download_uri(uri, filename)
  puts "Starting FTP download for: " + uri.to_s + "."

  dirname = File.dirname(uri.path)
  basename = File.basename(uri.path)

  begin
    Net::FTP.open(uri.host) do |ftp|
      ftp.login
      ftp.chdir(dirname)
      ftp.getbinaryfile(basename)
    end
  rescue Exception => e
    puts "=> Exception: '#{e}'. Skipping download."

    return
  end

  puts "Stored download as " + filename + "."
end

def download_resources(pairs)
  pairs.each do |pair|
    filename = pair[:filename].to_s
    resource = pair[:resource].to_s

    unless File.exists?(filename)
      download_resource(resource, filename)
    else
      puts "Skipping download for " + filename + ". It already exists."
    end
  end
end


def main
  ('a'..'z').each do |letter|
    save_sources(letter)

    sources_file = ARGV.first
    uris = read_uris_from_file(sources_file)

    home_directory = Dir.pwd
    target_dir_name = Date.today.strftime('%y%m%d')
    directory_name = create_directory(target_dir_name, letter)
    Dir.chdir(directory_name)
    puts "Changed directory: " + Dir.pwd

    download_resources(uris)

    puts "All words with the letter #{letter} downloaded"

    Dir.chdir(home_directory)
    puts "Back to #{home_directory} directory"

    puts
  end
end


if __FILE__ == $0
  usage = <<-EOU

  usage: type 'ruby #{File.basename($0)} sources.txt' where 'sources.txt' is the file with
    de URIs of the files to be accessed and downloaded

    The file sources.txt should contain at least an URL and the target file name. Like this:

    http://www.domain.com/file target_file_name
    ftp://www.domain.com/file target_file_name

    EOU

  abort usage if ARGV.length != 1

  main
end
