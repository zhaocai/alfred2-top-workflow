#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# ============== = ===========================================================
# Description    : Alfred 2 Top Processes Workflow
# Author         : Zhao Cai <caizhaoff@gmail.com>
# HomePage       : https://github.com/zhaocai/alfred2-top-workflow
# Date Created   : Sun 10 Mar 2013 09:59:48 PM EDT
# Last Modified  : Sat 30 Mar 2013 11:39:10 PM EDT
# Tag            : [ ruby, alfred, workflow ]
# Copyright      : © 2013 by Zhao Cai,
#                  Released under current GPL license.
# ============== = ===========================================================

($LOAD_PATH << File.expand_path("..", __FILE__)).uniq!

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8

require "bundle/bundler/setup"
require "alfred"

require 'open3'

require 'mixlib/shellout'


# (#
# Configuration                                                           [[[1
# #)


# Ignore mds because its cpu usgae spikes the moment alfred calls the workflow
$ignored_processes = ['Alfred 2', 'mds']

$vague_commands = [
  'ruby' , 'java'   , 'zsh'  , 'bash', 'python', 'perl',
  'rsync', 'macruby', 'ctags', 'vim', 'Vim', 'MacVim', 'ag', 'node', 'aria2c'
]

$top_symbol = '🔝'

$main_states = {
  'I' => ':idle',
  'R' => ':runnable',
  'S' => ':sleep',
  'T' => ':stopped',
  'U' => ':uninterruptible',
  'Z' => ':zombie',
  '?' => ':unknown'
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





# (#
# Helper Functions                                                        [[[1
# #)

def interpret_command(vague_command_list, process, opts = {})
  command = process[:command]
  command_basename = File.basename command

  if vague_command_list.include?(command_basename) || opts[:use_command_line]
    c = %Q{ps -awwwxo 'command' #{process[:pid]}}
    _stdin, stdout, _stderr = Open3.popen3(c)
    if command_line = stdout.readlines.map(&:chomp)[1]
      if opts[:use_command_line]
        return command_line
      else
        return %Q{#{command_basename}#{command_line.sub(/^#{Regexp.escape(command)}/, '')}}
      end
    else
      return command_basename
    end
  else
    return command_basename
  end
end

def interpret_state(state)
  if state.empty?
    return ""
  end

  m = ""

  states = state.chars.to_a

  m = $main_states[states.shift]
  a = []
  states.each { |c|
    a.push($additional_states[c])
  }

  if a.empty?
    return m
  else
    return "#{m}: #{a.join(',')}"
  end
end


class Integer
    def to_human
      units = ['', 'K', 'M', 'G', 'T', 'P']

      size, unit = units.reduce(self.to_f) do |(fsize, _), utype|
        fsize > 512 ? [fsize / 1024, utype] : (break [fsize, utype])
      end

      "#{size > 9 || size.modulo(1) < 0.1 ? '%d' : '%.1f'}%s" % [size, unit]
    end
end



# (#
# Top Processes                                                           [[[1
# #)



def ps_list(type, ignored)

  type2opt = {:memory => 'm', :cpu => 'r'}

  c = %Q{ps -a#{type2opt[type]}wwwxo 'pid nice %cpu %mem state comm'}
  _stdin, stdout, _stderr = Open3.popen3(c)
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

    process[:icon] = {:type => "fileicon", :name => process[:command]}
    m = process[:command].match(/(.*\.app\/).*/)
    process[:icon][:name] = m[1] if m

    process[:command] = interpret_command($vague_commands, process)
    process[:title] = "#{process[:rank]}: #{process[:command]}"

    # Ignore this script
    unless process[:title].include?(__FILE__) or ignored.include?(File.basename(process[:command]))
      processes[process[:pid]] = process
    end

    process[:subtitle] = "cpu: #{process[:cpu].rjust(6)}%,  "              \
                          "memory: #{process[:memory].rjust(6)}%,  "       \
                          "nice:#{process[:nice].rjust(4)},  "             \
                          "state:(#{process[:pid].center(8)}) #{process[:state]}"

    i += 1
  end
  return processes
end

def iotop(ignored)
  sample_interval = 2

  iosnoop_command = %q{./sudo.sh ./bin/iosnoop.d 2>/dev/null}
  iosnoop = Mixlib::ShellOut.new(iosnoop_command)
  iosnoop.timeout = sample_interval

  ps = {}
  begin
    iosnoop.run_command
  rescue Mixlib::ShellOut::CommandTimeout
    iosnoop.stdout.each_line do |line|
      columns = line.split('⟩').map(&:strip)

      pid     = columns[0].to_i
      type    = columns[1]
      size    = columns[2].to_i
      command = columns[3]

      if ps.has_key?(pid)
        p = ps[pid]
      else
        p = {
          :pid        => pid     ,
          :type       => :io     ,
          :command    => command ,
          :read_size  => 0       ,
          :write_size => 0       ,
        }
      end
      case type
      when 'R'
        p[:read_size] += size
      when 'W'
        p[:write_size] += size
      end

      ps[pid] = p
    end
  end

  return [] if ps.empty?
  ranks = {}
  i = 1
  ps.sort_by { |_, p| p[:read_size] + p[:write_size] }.reverse.each do |pair|
    ranks[pair[0]] = i
    i += 1
  end
  ps.each do |_, p|
    if p[:pid] > 0
      command_line = interpret_command($vague_commands, p, :use_command_line => true).to_s

      m = command_line.match(/(.*\.app\/).*/)
      p[:icon] = {:type => "fileicon", :name => m[1]} if m
    end

    p[:rank] = ranks[p[:pid]]
    p[:title] = "#{p[:rank]}: #{p[:command]}"
    p[:subtitle] = "Read: #{p[:read_size].to_human} ↔ Write: #{p[:write_size].to_human}"
  end

  return ps
end

def top_processes(sort_option)
  if sort_option == :auto
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
  elsif sort_option == :memory
    return ps_list(:memory, $ignored_processes)
  elsif sort_option == :cpu
    return ps_list(:cpu, $ignored_processes)
  elsif sort_option == :io
    return iotop($ignored_processes)
  end

end




# (#
# Feedback                                                                [[[1
# #)

def generate_feedback(alfred, processes, query)
  feedback = alfred.feedback

  processes.sort_by { |_, p| p[:rank] }.each do |pair|
    p = pair[1]
    if p[:icon]
      icon = p[:icon]
    else
      icon = {:type => "default", :name => "icon.png"}
      if p[:type].eql?(:auto)
        icon[:name] = "icon/process/auto.png"
      elsif p[:type].eql?(:memory)
        icon[:name] = "icon/process/memory.png"
      elsif p[:type].eql?(:cpu)
        icon[:name] = "icon/process/cpu.png"
      elsif p[:type].eql?(:io)
        icon[:name] = "icon/process/io.png"
      end
    end

    feedback.add_item({
      :title    => p[:title]         ,
      :subtitle => p[:subtitle]      ,
      :arg      => p[:pid]           ,
      :icon     => icon              ,
      :match?   => :all_title_match? ,
    })
  end

  puts feedback.to_alfred(query)
end


if __FILE__ == $PROGRAM_NAME
  if ['/h', '/help'].include? ARGV[0]
    exit 0
  end

  Alfred.with_friendly_error do |alfred|
    alfred.with_rescue_feedback = true

    sort_option = :auto
    if ['/m', '/mem', '/memory'].include? ARGV[0]
      sort_option = :memory
      ARGV.shift
    elsif ['/c', '/cpu'].include? ARGV[0]
      sort_option = :cpu
      ARGV.shift
    elsif ['/i', '/io'].include? ARGV[0]
      sort_option = :io
      ARGV.shift
    end
    processes = top_processes(sort_option)

    generate_feedback(alfred, processes, ARGV)
  end


end


# (#
# Modeline                                                                [[[1
# #)
# vim: set ft=ruby ts=2 sw=2 tw=78 fdm=marker fmr=[[[,]]] fdl=1 :
