# Only include subnets from this array, probably never have to touch unless you already know what you're doing
:local RFC1918 {"10.0.0.0/8";"172.16.0.0/12";"192.168.0.0/16" }
# We only generate hairpins for subnets below /30
:local subnetsbelow 255.255.255.252

# No touchy touchy below here unless you're h4xxorm0n1338l33txxXx
:local netarray [:toarray ""]
:local count 0

/ip firewall mangle remove [find where comment="Autogenerated Hairpin NAT"]
foreach i in=[/ip address find] do={
     :set count [$count + 1]
    :local curnet [/ip address get $i]
    
    :local inRFC1918 $false

    foreach j in=$RFC1918 do={
        :if (($curnet->"network") in $j) do={ :set inRFC1918 true }
    }

    :if ([:typeof [:find $netarray ($curnet->"network") -1]] = "nil" && ($curnet->"netmask") < $subnetsbelow && $inRFC1918) do={
        :set $netarray ($netarray, ($curnet->"network"))

        /ip firewall mangle add \
        chain=forward \
        connection-state=new \
        connection-nat-state=dstnat \
        src-address="$($curnet->"network")/$($curnet->"netmask")" \
        dst-address="$($curnet->"network")/$($curnet->"netmask")" \
        action=mark-connection \
        new-connection-mark=HAIRPIN \
        comment="Autogenerated Hairpin NAT"
    }
}

/ip firewall nat remove [find where comment="Autogenerated Hairpin NAT"]
/ip firewall nat add action=masquerade chain=srcnat comment="Autogenerated Hairpin NAT" connection-mark=HAIRPIN ipsec-policy=out,none place-before=0
