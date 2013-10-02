#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
($LOAD_PATH << File.expand_path("..", __FILE__)).uniq!

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8

require "bundle/bundler/setup"
require "alfred"

def generate_feedback(alfred, query)
  fb = alfred.feedback

  devices = %x{/bin/df -H}.split("\n")

  devices.each do |device|
    next unless device.start_with? '/dev/'

    items = device.split
    size = items[1]
    used = items[2]
    free = items[3]
    percentage = items[4]
    mount_point = items[8..-1].join(" ")
    if mount_point.eql? '/'
      name = 'Root'
    else
      name = File.basename(mount_point)
    end
    fb.add_file_item(mount_point,
                     :title => "#{name}: #{free} free",
                     :subtitle =>"#{used} (#{percentage}) used of #{size} total")
  end

  puts fb.to_alfred(query)
end



if __FILE__ == $PROGRAM_NAME
  Alfred.with_friendly_error do |alfred|
    alfred.with_rescue_feedback = true
    generate_feedback(alfred, ARGV)
  end
end


