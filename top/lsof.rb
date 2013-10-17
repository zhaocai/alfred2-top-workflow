#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# ============== = ===========================================================
# Description    : Alfred 2 Top Processes Workflow
# Author         : Zhao Cai <caizhaoff@gmail.com>
# HomePage       : https://github.com/zhaocai/alfred2-top-workflow
# Version        : 0.1
# Date Created   : Sun 10 Mar 2013 09:59:48 PM EDT
# Last Modified  : Sat 30 Mar 2013 10:48:07 PM EDT
# Tag            : [ ruby, alfred, workflow ]
# Copyright      : © 2013 by Zhao Cai,
#                  Released under current GPL license.
# ============== = ===========================================================

($LOAD_PATH << File.expand_path("..", __FILE__)).uniq!

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
require "bundle/bundler/setup"
require "alfred"
require 'open3'

 
# OPTIMIZE: use pgrep for name based search
def valid_pid?(pid)
  return false if pid.nil?
  !pid.match(/[^0-9]/)
end

def generate_feedback(alfred, pid, with_query)
  fb = alfred.feedback

  files = []

  c = %Q{lsof -p #{pid}}
  stdin, stdout, stderr = Open3.popen3(c)
  lines = stdout.readlines.map(&:chomp)

  if lines.empty?
    # try sudo
    c = %Q{./sudo.sh #{c}}
    stdin, stdout, stderr = Open3.popen3(c)
    lines = stdout.readlines.map(&:chomp)
  end

  if lines.empty?
    puts alfred.rescue_feedback(:title => "Is #{pid} a valid PID? Or the process has been terminated.")
    return false
  end

  lines.shift

  lines.each do |entry|
    columns = entry.split
    f = columns[8..-1]
    if f
      file = f.join(" ")
      files << file if File.exist?(file)
    end
  end

  files.delete_if { |f|
    f.start_with?("/Applications/") or f.eql?('/') or f.eql?('/dev/null')
  }


  files.each do |f|
    fb.add_file_item(f)
  end

  puts fb.to_alfred(with_query)
end

if __FILE__ == $PROGRAM_NAME
  Alfred.with_friendly_error do |alfred|

    alfred.with_rescue_feedback = true

    pid = ARGV[0]
    ARGV.shift

    unless valid_pid?(pid)
      puts alfred.rescue_feedback(:title => "Invalid PID: #{pid}")
      exit(-1)
    end

    generate_feedback(alfred, pid, ARGV)
  end
end



