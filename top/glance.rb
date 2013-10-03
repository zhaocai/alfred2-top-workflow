#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
($LOAD_PATH << File.expand_path("..", __FILE__)).uniq!

require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8

require "bundle/bundler/setup"
require "alfred"
require 'plist'
require 'awesome_print'
require 'yaml'


def percentage_sign(percent, use_sign = :emoji)
  if use_sign.eql? :emoji
    full = '🔴'
    empty = '⚪'
  elsif use_sign.eql? :plain
    full = '●'
    empty = '○'
  elsif use_sign.eql? :fruit
    signs = ["🍎", "🍎", "🍎", "🍊", "🍊", "🍊", "🍏" , "🍏", "🍏", "🍏", "🍏"]
    mark = percent / 10
    return signs[0...mark].join
  end
  mark = percent / 10
  sign = ''
  mark.times { |_| sign += full }
  (10 - mark).times { |_| sign += empty }
  sign
end

def generate_fan_temp_feedback(alfred, query)
  return if query[1].eql? '⟩'

  feedback = alfred.feedback
  profiler = %x{./bin/fans_tempsMonitor}.split("\n")

  right_fan_speed = profiler[0].split[-1][0...-3].to_i
  left_fan_speed  = profiler[1].split[-1][0...-3].to_i
  cpu_temperature = profiler[2].split[-1][0..-3].to_i
  gpu_temperature = profiler[7].split[-1][0..-3].to_i

  fan_speed = (left_fan_speed + right_fan_speed) / 2

  if fan_speed < 3000
    icon = {:type => "default", :name => "icon/fan/green.png"}
    title = "Fan Speed: Normal"
  elsif fan_speed < 4500
    icon = {:type => "default", :name => "icon/fan/blue.png"}
    title = "Fan Speed: Fast"
  else
    icon = {:type => "default", :name => "icon/fan/red.png"}
    title = "Fan Speed: Driving Crazy!"
  end
  feedback.add_item(:subtitle => "L: #{left_fan_speed} / R: #{right_fan_speed} RPM",
                    :title => title,
                    :icon => icon)
  icon = {:type => "default", :name => "icon/temperature/GPU.png"}
  feedback.add_item(:subtitle => "CPU: #{cpu_temperature}° C / GPU: #{gpu_temperature}° C",
                    :title => "CPU/GPU Temperature",
                    :icon => icon)

end
def generate_storage_feedback(alfred, query)
  return if query[1].eql? '⟩'

  feedback = alfred.feedback
  devices = %x{/bin/df -H}.split("\n")

  devices.each do |device|
    next unless device.start_with? '/dev/'

    items = device.split
    size = items[1]
    used = items[2]
    free = items[3]
    percent = items[4][0...-1].to_i
    mount_point = items[8..-1].join(" ")
    if mount_point.eql? '/'
      name = 'Root'
    else
      name = File.basename(mount_point)
    end
    feedback.add_file_item(mount_point,
                     :title => "#{name}: #{free} free",
                     :subtitle =>"#{percent}%, #{used} used of #{size} total")
  end
end


def generate_bluetooth_battery_feedback(alfred, query)
  return if query[1].eql? '⟩'

  feedback = alfred.feedback

  bluetooth_device_keys = ["BNBMouseDevice", "AppleBluetoothHIDKeyboard", "BNBTrackpadDevice"]

  bluetooth_device_keys.each do |key|
    devices = Plist.parse_xml %x{ioreg -l -n #{key} -r -a}
    next if devices.nil? || devices.empty?

    devices.each do |device|
      name = device["Product"]
      serial = device["SerialNumber"]
      percent = device["BatteryPercent"].to_i
      icon = {:type => "default", :name => "icon/bluetooth/#{key}.png"}
      feedback.add_item(:subtitle => "#{percentage_sign(percent)} #{percent}%",
                        :title => "#{name}",
                        :uid => "#{key}: #{serial}",
                        :icon => icon)
    end
  end

end

def generate_battery_feedback(alfred, query)

  detailed_feedback = false
  if query[1].eql? '⟩'
    if query[0].eql? "Battery"
      detailed_feedback = true
    else
      return
    end
  end


  devices = Plist.parse_xml %x{ioreg -l -n AppleSmartBattery -r -a}
  return if devices.nil? || devices.empty?
  feedback = alfred.feedback

  devices.each do |device|
    current_capacity = device["CurrentCapacity"]
    max_capacity     = device["MaxCapacity"]
    design_capacity  = device['DesignCapacity']
    temperature      = device['Temperature'].to_f / 100
    charging         = device['IsCharging']
    serial           = device['BatterySerialNumber']
    cycle_count      = device['CycleCount']
    fully_charged    = device['FullyCharged']
    is_external      = device['ExternalConnected']
    time_to_full     = device['AvgTimeToFull']
    time_to_empty    = device['AvgTimeToEmpty']
    manufacture_date = device['ManufactureDate']


    day = manufacture_date & 31
    month = (manufacture_date >> 5 ) & 15
    year = 1980 + (manufacture_date >> 9)

    manufacture_date = Date.new(year, month, day)
    # month as unit
    age = (Date.today - manufacture_date).to_f / 30

    health           = max_capacity * 100 / design_capacity
    percent           = current_capacity * 100 / max_capacity

    status_info = 'Draining'
    if charging
      status_info = 'Charging'
    elsif fully_charged
      status_info = 'Fully Charged'
    end

    if percent > 80
      icon_name = 'full'
    elsif percent > 50
      icon_name = 'medium'
    elsif percent > 10
      icon_name = 'low'
    else
      icon_name = 'critical'
    end

    time_info = 'Charging'

    if charging
      time_info = "#{time_to_full} until Full"
    else
      if fully_charged
        if is_external
          time_info = 'On AC Power'
          icon_name = 'power'
        else
          time_info = "#{time_to_empty} Left"
        end
      end
    end

    icon = {:type => "default", :name => "icon/battery/#{icon_name}.png"}

    battery_item = {
      :title        => "Battery: #{status_info}"                 ,
      :subtitle     => "#{percentage_sign(percent)} #{percent}%" ,
      :uid          => "Battery: #{serial}"                      ,
      :valid        => 'no'                                      ,
      :autocomplete => 'Battery ⟩ '                              ,
      :icon         => icon                                      ,
    }

    if detailed_feedback
      battery_item[:valid] = 'yes'

      feedback.add_item(battery_item)

      feedback.add_item(
        :title => "#{time_info}",
        :subtitle => 'Time Left',
        :icon => {:type => "default", :name => "icon/battery/clock.png"}
      )
      feedback.add_item(
        :title => "#{temperature}° C",
        :subtitle => 'Temperature',
        :icon => {:type => "default", :name => "icon/battery/temp.png"}
      )
      feedback.add_item(
        :title => "#{cycle_count}",
        :subtitle => 'Charge Cycles Completed',
        :icon => {:type => "default", :name => "icon/battery/cycles.png"}
      )
      feedback.add_item(
        :title => "#{health}%",
        :subtitle => 'Health',
        :icon => {:type => "default", :name => "icon/battery/health.png"}
      )
      feedback.add_item(
        :title => "#{serial}",
        :subtitle => 'Serial Number',
        :match? => :all_title_match?,
        :icon => {:type => "default", :name => "icon/battery/serial.png"}
      )
      feedback.add_item(
        :title => "#{age} monthes",
        :subtitle => 'Age',
        :icon => {:type => "default", :name => "icon/battery/age.png"}
      )
    else
      feedback.add_item(battery_item)
    end
  end

end

def generate_feedback(alfred, query)
  generate_battery_feedback(alfred, query)
  generate_fan_temp_feedback(alfred,query)
  generate_bluetooth_battery_feedback(alfred, query)
  generate_storage_feedback(alfred, query)

  if query[1].eql? '⟩'
    query.shift 2
  end
  puts alfred.feedback.to_alfred(query)
end



if __FILE__ == $PROGRAM_NAME
  Alfred.with_friendly_error do |alfred|
    alfred.with_rescue_feedback = true
    generate_feedback(alfred, ARGV)
  end
end

