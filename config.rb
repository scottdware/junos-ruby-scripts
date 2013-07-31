require 'net/netconf/jnpr'
require 'highline/import'
require 'optparse'
require 'ostruct'

# Print out the usage if there is no argument given.
def usage()
  puts "\nUsage: #{File.basename($0)}"
  puts "\t-d --device\t\t\tList of devices to configure (file)."
  puts "\t-c --config\t\t\tConfiguration file to commit."
  puts "\t-u --username\t\t\tSSH username."
  puts "\t-p --password\t\t\t(Optional) SSH password."
  puts "\t-h --help\t\t\tDisplay the usage.\n\n"
  puts "* If you have spaces in the path to your file(s), please enclose them in quotes \"\".\n\n"
  exit
end

options = OpenStruct.new

OptionParser.new do |opts|
  opts.on("-d", "--devices devices", "List of devices to configure (file).") do |d|
    options.devices = d
  end
  
  opts.on("-c", "--config config", "Configuration file to commit.") do |c|
    options.config = c
  end

  opts.on("-u", "--username username", "SSH username.") do |u|
    options.username = u
  end
  
  opts.on("-p", "--password [password]", "SSH password.") do |p|
    options.password = p
  end
  
  opts.on("-h", "--help [help]", "Display the usage.") do |h|
    options.help = h
  end
end.parse!

if !options.devices || !options.config || !options.username || options.help
  usage()
end

if !options.password
  password = ask("Password: ") { |e| e.echo = false }
  options.password = password
end

begin
  hosts = File.readlines(options.devices)
  config = File.readlines(options.config)
rescue Errno::ENOENT
  puts "\nERROR"
  puts "|-- Could not open one or more files for reading. Check to see if they exist or if the path is incorrect.\n\n"
end

puts "\nConfiguring #{hosts.count} host(s)...\n\n"
hosts.each do |host|
  login = {
    :target => host.chomp,
    :username => options.username,
    :password => options.password
  }
  
  begin
    # Connect to our host given the credentials above.
    Netconf::SSH.new(login) do |dev|
      begin
        cfg_lines = []
        config.each { |line| cfg_lines << line.chomp }
        chg = dev.rpc.lock_configuration
        chg = dev.rpc.load_configuration(cfg_lines, :format => "set")
        
        rpc = dev.rpc.check_configuration
        rpc = dev.rpc.commit_configuration
        rpc = dev.rpc.unlock_configuration
      rescue Netconf::LockError => e
        puts "#{host}"
        puts "|-- ERROR (Lock)"
        puts "\t|-- #{e.message}.\n\n"
      rescue Netconf::EditError => e
        puts "#{host}"
        puts "|-- ERROR (Edit)"
        puts "\t|-- #{e.message}.\n\n"
      rescue Netconf::ValidateError => e
        puts "#{host}"
        puts "|-- ERROR (Validate)"
        puts "\t|-- #{e.message}.\n\n"
      rescue Netconf::CommitError => e
        puts "#{host}"
        puts "|-- ERROR (Commit)"
        puts "\t|-- #{e.message}.\n\n"
      rescue Netconf::RpcError => e
        puts "#{host}"
        puts "|-- ERROR (General RPC)"
        puts "\t|-- #{e.message}.\n\n"
      else
        puts "#{host}"
        puts "|-- SUCCESS"
        puts "\t|-- Configuration successfully updated.\n\n"
      end
    end
  rescue SocketError
    puts "#{host}"
    puts "|-- ERROR"
    puts "\t|-- Check to see if the hostname is incorrect, or if the host exists!\n\n"
  rescue Net::SSH::AuthenticationFailed
    puts "#{host}"
    puts "|-- ERROR"
    puts "\t|-- Authentication failure!\n\n"
  rescue Net::SSH::ConnectionTimeout
    puts "#{host}"
    puts "|-- ERROR"
    puts "\t|-- Connection timed out!\n\n"
  rescue Errno::ETIMEDOUT
    puts "#{host}"
    puts "|-- ERROR"
    puts "\t|-- Connection timed out!\n\n"
  end
end