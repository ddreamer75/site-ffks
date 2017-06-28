Freifunk Kassel
----------------

Beta [Gluon](https://github.com/freifunk-gluon/)-Konfiguration für das Freifunk-Netz in Kassel. Wir arbeiten mit Gluon 2016.2.

## Building
[![build status](https://gitlab.com/freifunkks/site-ffks/badges/beta/build.svg)](https://gitlab.com/freifunkks/site-ffks/commits/beta)

Wir arbeiten an einer CI-Lösung für Firmware-Builds auf [GitLab](https://gitlab.com/freifunkks/site-ffks).

Um die firmware beispielhaft für den TP-link WR841N lokal zu bauen musst du einfach die folgenden befehle ausführen: 
```
git clone https://github.com/freifunkks/site-ffks
cd site-ffks
make GLUON_TARGET=ar71xx-generic
```
