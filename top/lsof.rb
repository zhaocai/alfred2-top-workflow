#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
# ============== = ===========================================================
# Description    : Alfred 2 Top Processes Workflow
# Author         : Zhao Cai <caizhaoff@gmail.com>
# HomePage       : https://github.com/zhaocai/alfred2-top-workflow
# Version        : 0.1
# Date Created   : Sun 10 Mar 2013 09:59:48 PM EDT
# Last Modified  : Sat 23 Mar 2013 05:23:51 AM EDT
# Tag            : [ ruby, alfred, workflow ]
# Copyright      : © 2013 by Zhao Cai,
#                  Released under current GPL license.
# ============== = ===========================================================

($LOAD_PATH << File.expand_path("..", __FILE__)).uniq!

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8
require "bundle/bundler/setup"
require "alfred"
require 'open3'



def generate_feedback(alfred, pids)
  fb = alfred.feedback
  files = []
  pids.each { |p|
    c = %Q{ lsof -p #{p}}
    stdin, stdout, stderr = Open3.popen3(c)

    stdout.readlines.slice(1..-1).map(&:chomp).each do |entry|
      columns = entry.split
      f = columns[8..-1]
      if f
        file = f.join(" ")
        files << file if File.exist?(file)
      end

    end

  }

  files.each do |f|
    fb.add_file_item(f)
  end

  puts fb.to_xml
end


if __FILE__ == $PROGRAM_NAME
  Alfred.with_friendly_error do |alfred|
    generate_feedback(alfred, ARGV)
  end
end



