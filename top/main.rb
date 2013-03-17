#!/usr/bin/env ruby
#

require 'optparse'
require 'open3'
load "alfred_feedback.rb"

ignored_processes = ['Alfred 2', 'mds']

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

    processes << {
      :line    => entry      ,
      :type    => type       ,
      :rank    => i          ,
      :pid     => columns[0] ,
      :cpu     => columns[1] ,
      :memory  => columns[2] ,
      :state   => columns[3] ,
      :command => columns[4..-1].join(" ") ,
    }
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
      :title    => "#{p[:rank]}: #{p[:command]}"                                                        ,
      :arg      => p[:pid]                                                                              ,
      :icon     => icon                                                                                 ,
      :subtitle => "CPU: #{p[:cpu].ljust(10)} MEM: #{p[:memory].ljust(10)} STAT: #{p[:state].ljust(8)}"
    })
  end

  puts feedback.to_xml
end

if __FILE__ == $PROGRAM_NAME

  options = parse_opt()

  processes = []

  if options[:sort] == :auto
    psm = ps_list(:memory, ignored_processes, options[:num])
    psc = ps_list(:cpu, ignored_processes, options[:num])
    processes = psm[0..2] + psc [0..2] + psm[3..-1].zip(psc[3..-1]).flatten.compact
  elsif options[:sort] == :memory
    processes = ps_list(:memory, ignored_processes, options[:num])
  elsif options[:sort] == :cpu
    processes += ps_list(:cpu, ignored_processes, options[:num])
  end

  unless ARGV.empty?
    query = ARGV.join(" ")
    processes.delete_if {|p| !p[:command].include?(query) }
  end

  generate_feedback(processes)

end

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
