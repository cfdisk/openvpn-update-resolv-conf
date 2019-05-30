OpenVPN Update resolvconf für busybox (Enigma2 und Co.)
-------------------------------------------------------

### Original Projekt ist hier:
https://github.com/alfredopalhares/openvpn-update-resolv-conf

### Änderungen
- bashism rediziert. Skript auch unter busybox lauffähig
- Option im IPv6 zu deaktivieren 

### Funktionsweise:
- Nach erfolgreichem Tunnel-Aufbau werden die DNS Server eures Anbieters über einen DHCP artigen Mechanismus ausgelesen und dann in der Box als beforzugte DNS Server konfiguriert. Oftmals (nicht immer) handelt es sich dabei um eine oder zwei Adresse(n) die mit 10.X.X.X beginnen.
Euer ursprünglicher DNS wird ans Ende der Liste gesetzt.
- Um Routing-Leaks zu vermeiden, wird IPv6 während aktivem Tunnel deaktiviert
- Sobald openVPN beendet wird, wird der Ursprungszustand wiederhergestellt (DNS und IPv6)

### Anleitung:
1) mit Telnet/SSH auf der Box anmelden

2) Evtl. fehlende Pakete installieren:
```
opkg install resolvconf
```

3) Script installieren:
```
cd /etc/openvpn; rm -f ./update-resolv-conf-BJ ; wget https://raw.githubusercontent.com/cfdisk/openvpn-update-resolv-conf/master/update-resolv-conf.sh -O ./update-resolv-conf-BJ; chmod +x update-resolv-conf-BJ
```

4) OpenVPN Konfiguration anpassen, folgende Zeilen hinzufügen, bzw. abändern, sofern schon vorhanden:
```
script-security 2
up /etc/openvpn/update-resolv-conf-BJ
down /etc/openvpn/update-resolv-conf-BJ
```

5) VPN Starten und dann DNS checken mit
```
cat /etc/resolv.conf
```

Hier sollte jetzt mindestens ein Eintrag vorhanden sein, der in etwas so aussieht (IP ist oft 10.x.x.x, ):
```
nameserver 10.X.X.X
```
