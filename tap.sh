#!/bin/sh

# Crea interfaccia di rete tap0
tunctl -g netdev -t tap0
ifconfig tap0 10.0.8.77
ifconfig tap0 netmask 255.255.255.252
ifconfig tap0 broadcast 10.0.8.79
ifconfig tap0 up

# Crea regole di firewalling (cambiare *wlan0* con il nome della propria scheda di rete)
iptables -t nat -F
iptables -t nat -X
iptables -F
iptables -X
iptables -t nat -A POSTROUTING -o wlp4s0 -j MASQUERADE
iptables -A FORWARD -i tap0 -j ACCEPT

# Abilita il forwarding su host locale 
sysctl -w net.ipv4.ip_forward=1

# Aggiungo la rotta verso il tap0
route add -net 10.0.0.0/20 gw 10.0.8.78 dev tap0
