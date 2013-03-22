#!/usr/bin/env ruby
# ============== = ===========================================================
# Description    : Alfred 2 Top Processes Workflow
# Author         : Zhao Cai <caizhaoff@gmail.com>
# HomePage       : https://github.com/zhaocai/alfred2-top-workflow
# Version        : 0.1
# Date Created   : Sun 10 Mar 2013 09:59:48 PM EDT
# Last Modified  : Fri 22 Mar 2013 03:42:11 PM EDT
# Tag            : [ ruby, alfred, workflow ]
# Copyright      : © 2013 by Zhao Cai,
#                  Released under current GPL license.
# ============== = ===========================================================


require 'optparse'
require 'open3'
load "alfred_feedback.rb"

# Ignore mds because its cpu usgae spikes the moment alfred calls the workflow
$ignored_processes = ['Alfred 2', 'mds']

$vague_commands = ['ruby', 'java', 'zsh', 'bash', 'python', 'perl', ]

def parse_opt()
  options = {:sort => :auto, :num => 13}

  optparse = OptionParser.new do |opts|
    opts.on("--sort [TYPE]", [:auto, :memory, :cpu],
            "sort processes by (memory, cpu, auto)") do |t|
      options[:sort] = t
    end

    opts.on('-n', "--n [N]", OptionParser::DecimalInteger,
            "list top N processes") do |t|
      options[:num] = t
    end

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



def ps_list(type, ignored, n=13)

  type2opt = {:memory => 'm', :cpu => 'r'}

  c = %Q{ps -a#{type2opt[type]}cwwwxo 'pid %cpu %mem state command'}
  stdin, stdout, stderr = Open3.popen3(c)

  processes = []
  i = 1
  stdout.readlines.slice(1..n).map(&:chomp).each do |entry|
    columns = entry.split

    process = {
      :line    => entry      ,
      :type    => type       ,
      :rank    => i          ,
      :pid     => columns[0] ,
      :cpu     => columns[1] ,
      :memory  => columns[2] ,
      :state   => columns[3] ,
      :command => columns[4..-1].join(" ") ,
    }
    process[:title] = interpret_command($vague_commands, process)

    # Ignore this script
    unless process[:title].include?(__FILE__)
      processes << process
    end

    i += 1
  end

  processes.delete_if {|p| ignored.include?(p[:command]) }
end

def generate_feedback(processes)

  feedback = Feedback.new
  processes.each do |p|
    icon = {:type => "default", :name => "icon.png"}
    if p[:type].eql?(:memory)
      icon[:name] = "memory.png"
    elsif p[:type].eql?(:cpu)
      icon[:name] = "cpu.png"
    end
    feedback.add_item({
      :title => p[:title] ,
      :arg   => p[:pid] ,
      :icon  => icon ,
      :subtitle => "cpu: #{p[:cpu].rjust(6)}%,  memory: #{p[:memory].rjust(6)}%,  state: #{interpret_state(p[:state]).rjust(6)}"
    })
  end

  puts feedback.to_xml
end

def interpret_command(vague_command_list, process)
  if vague_command_list.include?(process[:command])
    c = %Q{ps -awwwxo 'command' #{process[:pid]}}
    stdin, stdout, stderr = Open3.popen3(c)
    return "#{process[:rank]}: #{stdout.readlines.map(&:chomp)[1]}"
  else
    return "#{process[:rank]}: #{process[:command]}"
  end
end

def interpret_state(state)
  if state.empty?
    return ""
  end

  main_states = {
    'I' => 'idle',
    'R' => 'runnable',
    'S' => 'sleep',
    'U' => 'uninterruptible',
    'Z' => 'zombie'
  }
  additional_states = {
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

  m = main_states[state.slice(0..0)]
  a = []
  if state.size > 1
    state[1..-1].each_char { |c|
      a.insert(additional_states[c])
    }
  end

  if a.empty?
    return m
  else
    return "#{m} (#{a.join(',')})"
  end
end



if __FILE__ == $PROGRAM_NAME

  options = parse_opt()

  processes = []

  if options[:sort] == :auto
    psm = ps_list(:memory, $ignored_processes, options[:num])
    psc = ps_list(:cpu, $ignored_processes, options[:num])
    
    until psm.empty? and psc.empty?
        processes << psm.shift(2) << psc.shift(2)
    end
    processes.flatten!.compact!
  elsif options[:sort] == :memory
    processes = ps_list(:memory, $ignored_processes, options[:num])
  elsif options[:sort] == :cpu
    processes += ps_list(:cpu, $ignored_processes, options[:num])
  end

  unless ARGV.empty?
    query = ARGV.join(" ")
    processes.delete_if {|p| !p[:title].include?(query) }
  end

  generate_feedback(processes)

end


