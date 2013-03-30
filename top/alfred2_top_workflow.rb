#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# ============== = ===========================================================
# Description    : Alfred 2 Top Processes Workflow
# Author         : Zhao Cai <caizhaoff@gmail.com>
# HomePage       : https://github.com/zhaocai/alfred2-top-workflow
# Version        : 0.1
# Date Created   : Sun 10 Mar 2013 09:59:48 PM EDT
# Last Modified  : Fri 29 Mar 2013 09:58:24 PM EDT
# Tag            : [ ruby, alfred, workflow ]
# Copyright      : © 2013 by Zhao Cai,
#                  Released under current GPL license.
# ============== = ===========================================================
($LOAD_PATH << File.expand_path("..", __FILE__)).uniq!

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8

require "bundle/bundler/setup"
require "alfred"

require 'optparse'
require 'open3'

# (#
# Configuration                                                           [[[1
# #)


# Ignore mds because its cpu usgae spikes the moment alfred calls the workflow
$ignored_processes = ['Alfred 2', 'mds']

$vague_commands = ['ruby', 'java', 'zsh', 'bash', 'python', 'perl', ]

$top_symbol = '🔝'

$main_states = {
    'I' => ':idle',
    'R' => ':runnable',
    'S' => ':sleep',
    'T' => ':stopped',
    'U' => ':uninterruptible',
    'Z' => ':zombie'
}
$additional_states = {
    '+' => 'foreground',
    '<' => 'raised priority',
    '>' => 'soft limit on memory',
    'A' => 'random page replacement',
    'E' => 'trying to exit',
    'L' => 'page locked',
    'N' => 'reduced priority',
    'S' => 'FIO page replacement',
    's' => 'session leader',
    'V' => 'suspended',
    'W' => 'swapped out',
    'X' => 'being traced or debugged'
}

def parse_opt()
  options = {:sort => :auto}

  optparse = OptionParser.new do |opts|
    opts.on("--sort [TYPE]", [:auto, :memory, :cpu],
            "sort processes by (memory, cpu, auto)") do |t|
      options[:sort] = t
    end

    # opts.on('-n', "--n [N]", OptionParser::DecimalInteger,
    #         "list top N processes") do |t|
    #   options[:num] = t
    # end

    opts.on('-h', '--help', 'Help Message') do
      puts opts
      exit
    end
  end

  # parse and check mandatory options
  begin
    optparse.parse!
    mandatory = []
    missing = mandatory.select{ |param| options[param].nil? }
    if not missing.empty?
      puts "Missing options: #{missing.join(', ')}"
      puts optparse
      exit
    end
  rescue OptionParser::InvalidOption, OptionParser::MissingArgument
    puts $!.to_s
    puts optparse
    exit
  end

  return options
end


# (#
# Helper Functions                                                        [[[1
# #)

def interpret_command(vague_command_list, process)
  if vague_command_list.include?(process[:command])
    c = %Q{ps -awwwxo 'command' #{process[:pid]}}
    stdin, stdout, stderr = Open3.popen3(c)
    return stdout.readlines.map(&:chomp)[1]
  else
    return process[:command]
  end
end

def interpret_state(state)
  if state.empty?
    return ""
  end

  m = ""

  states = state.chars.to_a

  m = $main_states[states[0]]

  a = []
  if states.size > 1
    states[1..-1].each { |c|
      a.insert($additional_states[c])
    }
  end

  if a.empty?
    return m
  else
    return "#{m} (#{a.join(',')})"
  end
end


# (#
# Top Processes                                                           [[[1
# #)



def ps_list(type, ignored)

  type2opt = {:memory => 'm', :cpu => 'r'}

  c = %Q{ps -a#{type2opt[type]}cwwwxo 'pid nice %cpu %mem state command'}
  stdin, stdout, stderr = Open3.popen3(c)
  lines = stdout.readlines.map(&:chomp)
  lines.shift

  processes = {}
  i = 1
  lines.each do |entry|
    columns = entry.split

    process = {
      :line    => entry      ,
      :type    => type       ,
      :rank    => i          ,
      :pid     => columns[0] ,
      :nice    => columns[1] ,
      :cpu     => columns[2] ,
      :memory  => columns[3] ,
      :state   => interpret_state(columns[4]) ,
      :command => columns[5..-1].join(" ")    ,
    }
    process[:command] = interpret_command($vague_commands, process)
    process[:title] = "#{process[:rank]}: #{process[:command]}"

    # Ignore this script
    unless process[:title].include?(__FILE__) or ignored.include?(process[:command])
      processes[process[:pid]] = process
    end

    i += 1
  end
  return processes
end



def top_processes(options)
  if options[:sort] == :auto
    psm = ps_list(:memory, $ignored_processes)
    psc = ps_list(:cpu, $ignored_processes)

    processes = {}
    psc.each_pair do |id, p|
      m = psm[id]
      if m
        p[:type] = :auto
        p[:title] =  "#{p[:rank]}/#{m[:rank]}: #{p[:command]}"
      end
      processes[id] = p
    end
    return processes
  elsif options[:sort] == :memory
    return ps_list(:memory, $ignored_processes)
  elsif options[:sort] == :cpu
    return ps_list(:cpu, $ignored_processes)
  end

end




# (#
# Feedback                                                                [[[1
# #)

def generate_feedback(alfred, processes, query)
  time = Time.now.to_s

  feedback = alfred.feedback

  processes.sort_by { |_, p| p[:rank] }.each do |pair|
    p = pair[1]
    icon = {:type => "default", :name => "icon.png"}
    if p[:type].eql?(:auto)
      icon[:name] = "auto.png"
    elsif p[:type].eql?(:memory)
      icon[:name] = "memory.png"
    elsif p[:type].eql?(:cpu)
      icon[:name] = "cpu.png"
    end

    feedback.add_item({
      :uid   => "#{p[:title]} #{time}" ,
      :title => p[:title] ,
      :arg   => p[:pid] ,
      :icon  => icon ,
      :subtitle => "cpu: #{p[:cpu].rjust(6)}%,  memory: #{p[:memory].rjust(6)}%,  nice:#{p[:nice].rjust(4)},  state: |#{p[:pid].rjust(6)}| #{p[:state].ljust(15)}"
    })
  end

  puts feedback.to_alfred(query)
end


# overwrite default query matcher
module Alfred
  class Feedback::Item
    def match?(query)
      all_title_match?(query)
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  Alfred.with_friendly_error do |alfred|
    alfred.with_rescue_feedback = true

    options = parse_opt()
    processes = top_processes(options)

    generate_feedback(alfred, processes, ARGV)
  end


end


# (#
# Modeline                                                                [[[1
# #)
# vim: set ft=ruby ts=2 sw=2 tw=78 fdm=marker fmr=[[[,]]] fdl=1 :
