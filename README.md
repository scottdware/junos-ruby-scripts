## junos-ruby-scripts

A collection of Ruby scripts to interact with Junos devices. Please make sure that you have the following
gems installed:

- netconf
- highline
- colorized

### Script list & overview

- `ipsec-info.rb <user@host>`
	- This script will query an SRX and get all of the IPsec VPN tunnel information. Example:

	<pre><code>199.199.199.199 => IKE Phase 1 Status: UP
        Per-flow tunnel information:

        Tunnel Index:           2
        Identifier:             5b41dc1c
        Encryption:             ESP:3des/sha1
        Direction:              &lt; inbound
        Lifetime/Remaining:     3206/unlim

        Tunnel Index:           2
        Identifier:             97974ccd
        Encryption:             ESP:3des/sha1
        Direction:              &gt; outbound
        Lifetime/Remaining:     3206/unlim</code></pre>