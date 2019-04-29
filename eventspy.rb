#!/usr/bin/env ruby

WEBHOOK = 'https://discordapp.com/api/webhooks/nope/getYourOwn'
PATTERN = Regexp.new(/\[Server thread\/INFO\]: (?<player>\S+) (?<direction>joined|left) the game/)

require 'net/http'

def main(target_file)
  log = open_file(target_file)
  while true do
    until log.eof? do
      line = log.gets
      send_to_discord(PATTERN.match(line))
    end
    sleep 1
    log = get_latest_logfile(target_file, log)
  end
end

def send_to_discord(match)
  return if match.nil?
  message = "#{match[:player]} #{match[:direction]} the Minecraft server"
  puts message
  Net::HTTP.post_form(URI(WEBHOOK), 'content' => message)
end

def get_latest_logfile(target_file, old_log)
    begin
     new_log = open_file(target_file)
     if(new_log.stat.ino != old_log.stat.ino)
       old_log.close
       puts 'File changed; reopening...'
       return new_log
     else
       new_log.close
       return old_log
     end
    rescue Errno::ENOENT => e
      puts 'File not there, sneeping...'
      sleep 10
    end
    old_log
end

def open_file(target_file)
  log = File.new(target_file, 'r')
  log.advise(:sequential)
  log.seek(0, IO::SEEK_END)
  log
end

main "logs/latest.log"
