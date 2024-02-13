#Flush
iptables -F
#Cancellare le catene
iptables -X

#Policy di default
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

#Creazione delle sottocatene
iptables -N GreenToAll
iptables -N AllToGreen
iptables -N DmzToRed
iptables -N AllToDmz

#permette di connettersi a SNatted solo se si passa per il DNAT
iptables -A FORWARD -m conntrack --ctstate DNAT -d 10.0.6.1 -o eth0 -i eth1 -p tcp --dport 21 -j ACCEPT
iptables -A FORWARD -d 10.0.6.1 -j DROP

#Connessione delle sottocatene
iptables -A FORWARD -s 10.0.8.0/26 -i eth0 -j GreenToAll
iptables -A FORWARD -d 10.0.8.0/26 -o eth0 -j AllToGreen
iptables -A FORWARD -s 10.0.4.0/22 -d 10.0.0.0/22 -i eth0 -o eth1 -j DmzToRed
iptables -A FORWARD -d 10.0.4.0/22 -o eth0 -j AllToDmz

#Applicare regole alle sottocatene
iptables -A GreenToAll -j ACCEPT
iptables -A AllToGreen -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A DmzToRed -j ACCEPT
iptables -A AllToDmz -j ACCEPT


#Abilitare SSH
iptables -A INPUT -p tcp --dport 22 -s 10.0.8.76/30 -i eth0 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -d 10.0.8.76/30 -o eth0 -j ACCEPT
iptables -A FORWARD -p tcp --dport 22  -d 10.0.8.74 -o eth1 -i eth0 -j ACCEPT
iptables -A FORWARD -p tcp --sport 22 -s 10.0.8.74 -oeth0 -i eth1 -m state --state ESTABLISHED,RELATED -j ACCEPT

#Natting
#PortForwarding della porta 25 su 10.0.4.1
iptables -t nat -A PREROUTING -p tcp --dport 25 -j DNAT --to 10.0.4.1:25
#Portforwarding della porta 21 su 10.0.6.1
iptables -t nat -A PREROUTING -p tcp --dport 21 -j DNAT --to 10.0.6.1:21
#Portforwarding della porta 53 verso router di area DMZ
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to 10.0.8.66:80
