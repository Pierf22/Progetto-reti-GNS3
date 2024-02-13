#Flush
iptables -F
#Cancella tutte le catene
iptables -X

#Policy di default
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

#Sottocatene
iptables -N GreenToAll
iptables -N AllToGreen
iptables -N InetToDmz
iptables -N DmzToInet

#permette di connettersi a Snatted solo se si passa per il DNAT
iptables -A FORWARD -m conntrack --ctstate DNAT -d 10.0.6.1   -o eth2   -p tcp --dport 21 -j ACCEPT
iptables -A FORWARD  -d 10.0.6.1 -j DROP

#Collegamento alla catena Forward
iptables -A FORWARD -s 10.0.8.0/26 -i eth1 -j GreenToAll
iptables -A FORWARD -d 10.0.8.0/26 -j AllToGreen
iptables -A FORWARD -s 10.0.8.76/30 -i eth0 -o eth2 -j InetToDmz
iptables -A FORWARD -d 10.0.8.76/30 -i eth2 -o eth0 -j DmzToInet

#Applichiamo le regole
iptables -A GreenToAll -j ACCEPT
iptables -A AllToGreen -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A InetToDmz -j ACCEPT
iptables -A DmzToInet -m state --state ESTABLISHED,RELATED -j ACCEPT

#Abilitare SSH
iptables -A INPUT -p tcp --dport 22 -s 10.0.8.76/30 -i eth0 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -d 10.0.8.76/30 -o eth0 -j ACCEPT

#Natting
#PortForwarding della porta 25 su 10.0.4.1
iptables -t nat -A PREROUTING -p tcp  --dport 25 -j DNAT --to 10.0.4.1:25
#Portforwarding della porta 21 su 10.0.6.1
iptables -t nat -A PREROUTING -p tcp --dport 21 -j DNAT --to 10.0.6.1:21
#Portforwarding della porta 53 verso router di area DMZ
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to 10.0.8.66:80

#Abilitare il passaggio di ssh da F2
iptables -A FORWARD -p tcp --dport 22 -i eth0 -o eth2 -d 10.0.8.70 -j ACCEPT
iptables -A FORWARD -p tcp --sport 22 -i eth2 -o eth0 -s 10.0.8.70 -m state --state ESTABLISHED,RELATED  -j ACCEPT
