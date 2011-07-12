require 'rubygems'
require 'phidgets-ffi'

Phidgets::Manager.new do |manager|
  puts manager.devices.inspect

  manager.on_attach do |device_ptr|
    puts "Attaching #{device_ptr}"
  end

  manager.on_detach do |device_ptr|
    puts "Detaching #{device_ptr}"
  end
  
  puts "You have 20 seconds to plug/unplug USB devices and watch the callbacks execute"
  sleep 20
end
