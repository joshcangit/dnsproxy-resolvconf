#!/usr/bin/env ruby
require 'yaml'

if ARGV.length < 1; exit 0 end

yaml_file = File.path("/etc/adguard/dnsproxy.yml")
yaml = YAML.load(File.read(yaml_file))
listen_addrs = yaml["listen-addrs"]
conf = (listen_addrs.each { |x| x.prepend("nameserver ") })|["options edns0"]

resolv_file = File.path("/etc/resolvconf/resolv.conf.d/head")
resolv = File.readlines(resolv_file).each { |x| x.chomp! }

def resolv_conf (filepath, array, mode)
  File.write(filepath, array.join($/), mode: "#{mode}")
  system("resolvconf", "-u")
end

dnsproxy = File.join(__dir__, "dnsproxy")
case "#{ARGV[0]}"
when /^start$/
  new_conf = conf - resolv
  if new_conf.length > 0
    resolv_conf resolv_file, new_conf, 'a'
    system(dnsproxy, "--config-path=#{yaml_file}")
  end
when /^stop$/
  new_conf = resolv - conf
  if new_conf != resolv
    system("killall", "-9", dnsproxy)
    if (new_conf.last).nil?
    elsif !(new_conf.last).empty?; new_conf.last << $/ end
    resolv_conf resolv_file, new_conf, 'w'
  end
end
