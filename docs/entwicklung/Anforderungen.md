# Elektro: Anforderungen und Entscheide

Angelegt 19.11.2026. Hier steht, was der Auftraggeber verlangt hat (mit Datum, möglichst im Wortlaut) und was
entschieden wurde. Keine Arbeitsprotokolle, keine Pfade zu fremden Rechnern.

## Auftrag

- <Datum>: «<Wortlaut>»

## Was es zeigen und können muss

| Nr. | Anforderung | Stand |
|---|---|---|
| 1 | <…> | offen |

## Freigabe des Konzepts

- <Datum>: Konzept `docs/konzept/Elektro - Konzept.html` gezeigt. Antwort: «<Wortlaut>». Änderungen: <…>

## Entscheide

| Datum | Entscheid | Grund |
|---|---|---|
| <…> | <…> | <…> |

## Offen

- <…>

## Freigabe und Bau (19.11.2026)

Version 0.1.0 gebaut und im Simulator getestet (schlanker Weg auf Wunsch des Autors: Lua, Simulatortest, Update-Test;
Anleitung, Paket und Ansagen folgen später).

### Freigabe und Entscheide
- 19.11.2026: Konzept freigegeben.
- Werkschwellen wie im Konzept, Abweichung von bauplan.md Regel 9 (Werk 0 = aus) auf Wunsch des Autors.
- 480 × 320: sechs Felder mit gekürzten Titeln. SG: nur Ansage (Akku %, Flugzeit), kein Vario-Ton.
- Zellen: Fall 1 nur Gesamtspannung (Zelle Ø = Gesamt ÷ Zellenzahl), Fall 2 Zellensensor (tiefste Zelle, Δ).
  Zellenzahl «automatisch» ohne Zellensensor: keine Schätzung, Hinweis «Zellenzahl einstellen» (wie Motoren Lua 1.5.0).
- So viel wie möglich konfigurierbar (Menütabelle im Konzept).
- Name «Elektro», Schlüssel `elektro`, Skriptordner `elektro`, Repo `elektro-lua`.
- Kopfzeile wie Heli RF; rechts Senderakku wie Heli RF (statt Flugakku im Konzeptbild).

### Offen
Sprachdateien (Liste liegt bei der Koordination), unabhängige Prüfung,
Test am echten Sender (Schalter-Vorgabe SF↑/SG↓, Sensorsuche, Ton), Speicher (rund 133 KB, mehr als Heli RF).
