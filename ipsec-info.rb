require 'net/netconf/jnpr'
require 'highline/import'
require 'colorize'
require 'optparse'

begin
  if RUBY_PLATFORM =~ /(i386-mingw32|win32)/
    require 'win32console'
  end
rescue LoadError => e
  puts "ERROR: #{e}:"
  puts "Please make sure that you install win32console via 'gem install win32console'"
  exit
end

# Print out the usage if there is no argument given.
def usage()
  puts "Usage: ipsec-info.rb -u <username> -h <host> -p\n"
  exit
end

options = {}

OptionParser.new do |opts|
  opts.on("-u", "--username [username]", "Username") do |u|
    options[:username] = u
  end
  
  opts.on("-h", "--hostname [hostname]", "Host") do |h|
    options[:hostname] = h
  end
  
  opts.on("-p", "--password [password]", "Password") do |p|
    password = ask("Password: ") { |e| e.echo = false }
    options[:password] = password
  end
end.parse!

if !options[:username] || !options[:hostname] || !options[:password] || options.size < 3
  usage()
end

login = {
  :target => options[:hostname],
  :username => options[:username],
  :password => options[:password]
}

begin
  # Connect to our host given the credentials above.
  Netconf::SSH.new(login) do |dev|
    # Get our IKE data
    ike_info = dev.rpc.get_ike_security_associations_information

    # Get our IPsec data
    ipsec_info = dev.rpc.get_security_associations_information

    # Total number of active tunnels
    num_tunnels = ipsec_info.xpath('//total-active-tunnels').text
    remote_hosts = {}
    ipsec_data = {}
    tunnel_list = []

    # Get the remote IP and phase 1 status, and assign them to a hash table.
    ike_info.xpath('//ike-security-associations').each do |ike|
      ike_remote = ike.xpath('ike-sa-remote-address').text
      ike_state = ike.xpath('ike-sa-state').text
      ike_exch_type = ike.xpath('ike-sa-exchange-type').text
      remote_hosts[ike_remote] = ike_state
    end

    # Get all of our IPsec info for each tunnel and put it in a hash table.
    ipsec_info.xpath('//ipsec-security-associations').each do |ipsec|
      ipsec_remote = ipsec.xpath('sa-remote-gateway').text
      ipsec_dir = ipsec.xpath('sa-direction').text
      ipsec_prot = ipsec.xpath('sa-protocol').text
      ipsec_esp = ipsec.xpath('sa-esp-encryption-algorithm').text
      ipsec_hmac = ipsec.xpath('sa-hmac-algorithm').text
      ipsec_spi = ipsec.xpath('sa-spi').text
      ipsec_hard_lifetime = ipsec.xpath('sa-hard-lifetime').text
      ipsec_lifesize_remain = ipsec.xpath('sa-lifesize-remaining').text
      ipsec_ti = ipsec.xpath('sa-tunnel-index').text
        
      direction = { '<' => 'inbound', '>' => 'outbound' }
      data = ipsec_remote + "," +
             ipsec_prot + 
             ipsec_esp +
             ipsec_hmac + "," +
             ipsec_dir + " " +
             direction[ipsec_dir] + "," +
             ipsec_hard_lifetime +
             ipsec_lifesize_remain.strip() + "," +
             ipsec_spi + "," +
             ipsec_ti

      ipsec_data[ipsec_spi] = data
      tunnel_list << ipsec_remote
    end

    puts "\nTotal Active Tunnels: #{num_tunnels}\n\n"

      # Loop over each IP, and list the tunnel information for said IP.
      remote_hosts.each_pair do |ip, status|
        count = 0
        tunnel_list.each do |tunnel|
          count += 1 if tunnel == ip
        end 
        tcount = (count / 2) == 1 ? "tunnel" : "tunnels"
        scolor = status == "UP" ? :green : :red
        
        puts "#{ip} => IKE Phase 1 Status: #{status.colorize(scolor)}"
        puts "\tPer-flow tunnel information (#{count / 2} #{tcount}):\n\n"
        
        if status == "DOWN"
          puts "\tNo active tunnels for this IP. VPN is down!".colorize(:yellow)
        end

        ipsec_data.each_pair do |key, info|
          data = info.split(",")
          encr = data[1]
          traffic = data[2]
          life = data[3]
          spi = data[4]
          tindex = data[5]
          tcolor = traffic == "< inbound" ? :green : :cyan

          if data[0] == ip
            puts "\tTunnel Index:\t\t#{tindex}"
            puts "\tIdentifier:\t\t#{spi}"
            puts "\tEncryption:\t\t#{encr.colorize(:yellow)}"
            puts "\tDirection:\t\t#{traffic.colorize(tcolor)}"
            puts "\tLifetime/Remaining:\t#{life.colorize(:gray)}\n\n"
          end
        end

        puts "\n"
      end
  end
rescue Net::SSH::AuthenticationFailed
  puts "\nERROR".colorize(:magenta) + ": Authentication failed!\n\n"
rescue Net::SSH::ConnectionTimeout
  puts "\nERROR".colorize(:magenta) + ": Connection timed out!\n\n"
rescue Errno::ETIMEDOUT
  puts "\nERROR".colorize(:magenta) + ": Connection timed out!\n\n"
end
