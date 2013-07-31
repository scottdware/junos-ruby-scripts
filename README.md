## junos-ruby-scripts

A collection of Ruby scripts to interact with Junos devices. Please make sure that you have the following
gems installed:

- netconf
- highline
- colorize

If you are running this script on Windows, then you will need to install the following gem:

- win32console

This can be done by issuing `gem install <gem>` on the cli.

### Script list & overview

#### ipsec-info.rb

Usage: `ipsec-info.rb -u <username> -h <host> -p`

This script will query an SRX and get all of the IPsec VPN tunnel information. Example output:

	Total Active Tunnels: 1
    
    1.1.1.1 => IKE Phase 1 Status: UP
        Per-flow tunnel information (1 tunnel):

        Tunnel Index:           2
        Identifier:             5b41dc1c
        Encryption:             ESP:3des/sha1
        Direction:              < inbound
        Lifetime/Remaining:     3206/unlim

        Tunnel Index:           2
        Identifier:             97974ccd
        Encryption:             ESP:3des/sha1
        Direction:              > outbound
        Lifetime/Remaining:     3206/unlim

    2.2.2.2 => IKE Phase 1 Status: DOWN
        Per-flow tunnel information (0 tunnels):

        No active tunnels for this IP. VPN is down!
        
If a connection times out, or you entered in the wrong credentials, you will get an error message:
    
`ERROR: Connection timed out!` or `ERROR: Authentication failed!`

#### config.rb

Usage: `config.rb -u <username> -d <device file> -c <config file> [-p <password>]`

This script is used to configure a given list of devices with the configuration file that was
specified. The `-p <password>` option on the command line is optional, but insecure. If you
omit the `-p` flag, then you will be prompted for your password and it will not be displayed.

* For the list of devices, just place them in a text file, one on each line.
* For the configuration, use `set` commands and place them on each line in your file.