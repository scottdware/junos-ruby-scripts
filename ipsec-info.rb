require 'net/netconf/jnpr'
require 'highline/import'
require 'colorize'

# Print out the usage if there is no argument given.
def usage()
    puts "Usage: ipsec-info.rb <user@host>\n"
	exit 0
end

# Get the username and host.
host = ARGV[0].split("@")[1]
user = ARGV[0].split("@")[0]

if host.nil? || user.nil?
	usage()
end

# Hide the password from being viewed on the cli.
pass = ask("Password: ") { |a| a.echo = false }

login = {
	:target	=> host,
	:username => user,
	:password => pass
}

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
		
		direction = { "<" => "inbound", ">" => "outbound" }
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
	end

	puts "\nTotal Active Tunnels: #{num_tunnels}\n\n"

	# Loop over each IP, and list the tunnel information for said IP.
	remote_hosts.each_pair do |ip, status|
		puts "#{ip} => IKE Phase 1 Status: #{status.colorize(:green)}" if status == "UP"
		puts "#{ip} => IKE Phase 1 Status: #{status.colorize(:red)}" if status == "DOWN"
		puts "\tPer-flow tunnel information:\n\n"

		ipsec_data.each_pair do |key, value|
			data = value.split(",")
			encr = data[1]
			traffic = data[2]
			life = data[3]
			spi = data[4]
			tindex = data[5]

			if data[0] == ip
				puts "\tTunnel Index:\t\t#{tindex}"
				puts "\tIdentifier:\t\t#{spi}"
				puts "\tEncryption:\t\t#{encr.colorize(:yellow)}"
				puts "\tDirection:\t\t#{traffic.colorize(:green)}" if traffic == "< inbound"
				puts "\tDirection:\t\t#{traffic.colorize(:cyan)}" if traffic == "> outbound"
				puts "\tLifetime/Remaining:\t#{life.colorize(:gray)}\n\n"
			end
		end

		puts "\n"
	end
end
