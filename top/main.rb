#!/usr/bin/env ruby
#

require 'optparse'
require 'open3'
load "alfred_feedback.rb"

def parse_opt()
  options = {:sort => 'r'}

  optparse = OptionParser.new do |opts|
    opts.on("--sort [TYPE]", [:memory, :cpu, :auto],
    "sort processes by (memory, cpu, auto)") do |t|
      if t.eql?(:memory)
        options[:sort] = 'm'
      elsif t.eql?(:cpu)
        options[:sort] = 'r'
      end
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




options = parse_opt()

c = %Q{ps -a#{options[:sort]}cwwwxo 'pid=pid command=command %mem=mem %cpu=cpu state=state'}
stdin, stdout, stderr = Open3.popen3(c)

processes = []
commands = []
stdout.readlines.slice(1..13).each do |entry|
  columns = entry.split
  commands << columns[1]
  processes << {
    :line    => entry      ,
    :pid     => columns[0] ,
    :command => columns[1] ,
    :memory  => columns[2] ,
    :cpu     => columns[3] ,
    :state   => columns[4] ,
  }
end



feedback = Feedback.new

max_len = commands.max_by {|c| c.length}.length

processes.each do |process|
  feedback.add_item({
    :title    => process[:command]                                                                                               ,
    :arg      => process[:pid]                                                                                                   ,
    :subtitle => "#{process[:pid].ljust(max_len)}	#{process[:cpu].ljust(6)}	#{process[:memory].ljust(6)} #{process[:state]}"
  })
end

puts feedback.to_xml


# Reference:
# ----------
#
# -m      Sort by memory usage, instead of the combination of controlling
#         terminal and process ID.
#
# -r      Sort by current CPU usage, instead of the combination of control-
#         ling terminal and process ID.

# state     The state is given by a sequence of characters, for example,
#           ``RWNA''.  The first character indicates the run state of the
#           process:

#           I       Marks a process that is idle (sleeping for longer than
#                   about 20 seconds).
#           R       Marks a runnable process.
#           S       Marks a process that is sleeping for less than about 20
#                   seconds.
#           T       Marks a stopped process.
#           U       Marks a process in uninterruptible wait.
#           Z       Marks a dead process (a ``zombie'').

#           Additional characters after these, if any, indicate additional
#           state information:

#           +       The process is in the foreground process group of its
#                   control terminal.
#           <       The process has raised CPU scheduling priority.
#           >       The process has specified a soft limit on memory
#                   requirements and is currently exceeding that limit;
#                   such a process is (necessarily) not swapped.
#           A       the process has asked for random page replacement
#                   (VA_ANOM, from vadvise(2), for example, lisp(1) in a
#                   garbage collect).
#           E       The process is trying to exit.
#           L       The process has pages locked in core (for example, for
#                   raw I/O).
#           N       The process has reduced CPU scheduling priority (see
#                   setpriority(2)).
#           S       The process has asked for FIFO page replacement
#                   (VA_SEQL, from vadvise(2), for example, a large image
#                   processing program using virtual memory to sequentially
#                   address voluminous data).
#           s       The process is a session leader.
#           V       The process is suspended during a vfork(2).
#           W       The process is swapped out.
#           X       The process is being traced or debugged.
