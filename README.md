## junos-ruby-scripts

A collection of Ruby scripts to interact with Junos devices. Please make sure that you have the following
gems installed:

- netconf
- highline
- colorize

This can be done by issuing `gem install <gem>` on the cli.

### Script list & overview

#### ipsec-info.rb

Usage: `ipsec-info.rb <user@host>`

This script will query an SRX and get all of the IPsec VPN tunnel information. Example output:

	<pre><code>Total Active Tunnels: 1
    
    1.1.1.1 => IKE Phase 1 Status: UP
        Per-flow tunnel information (1 tunnel):

        Tunnel Index:           2
        Identifier:             5b41dc1c
        Encryption:             ESP:3des/sha1
        Direction:              &lt; inbound
        Lifetime/Remaining:     3206/unlim

        Tunnel Index:           2
        Identifier:             97974ccd
        Encryption:             ESP:3des/sha1
        Direction:              &gt; outbound
        Lifetime/Remaining:     3206/unlim

    2.2.2.2 => IKE Phase 1 Status: DOWN
        Per-flow tunnel information (0 tunnels):

        No active tunnels for this IP. VPN is down!</code></pre>
        
    - If a connection times out, or you entered in the wrong credentials, you will get an error message:
    
    `ERROR: Connection timed out!` or `ERROR: Authentication failed!`
