OpenVPN Update resolvconf für busybox (Enigma2 und Co.)
-------------------------------------------------------

### Original Projekt ist hier:
https://github.com/alfredopalhares/openvpn-update-resolv-conf

### Änderungen
- bashism entfernt. Skript auch unter busybox lauffähig
- Option um IPv6 zu deaktivieren (Default: ON)

### Funktionsweise:
- Nach erfolgreichem Tunnel-Aufbau werden die DNS Server des VPN Anbieters ausgelesen und dann auf der Box als bevorzugte DNS Server konfiguriert. Oftmals (nicht immer) handelt es sich dabei um eine oder zwei Adresse(n) die mit 10.X.X.X beginnen.
Der ursprünglicher DNS Server wird ans Ende der Liste gesetzt.
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

Hier sollte jetzt mindestens ein Eintrag vorhanden sein, der in etwas so aussieht:
```
nameserver 10.X.X.X
```

