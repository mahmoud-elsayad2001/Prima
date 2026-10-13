# Prima – CMMS für Industrieanlagen

Progressive Web App für Wartung, Störungsmeldungen, Prüfprotokolle und Abnahmen.
React + Vite, Tailwind CSS, Lucide Icons, Supabase (Datenbank, Auth, Storage).

## Inbetriebnahme

```bash
npm install
npm run dev      # http://localhost:5173
npm run build    # Produktionsbuild in dist/
```

## Datenbank einrichten oder aktualisieren

`supabase/schema.sql` im Supabase **SQL-Editor** vollständig ausführen. Das Skript ist **idempotent**
(leere und bestehende Datenbank, beliebig oft, keine Datenlöschung). Fehlt das Update, blendet die App
oben einen gelben Hinweis ein. Optional `supabase/seed.sql` für Beispielstruktur samt Beispiel-Formblatt.

Zum Testen des Vier-Augen-Prinzips zwei Konten anlegen (eines *Technik*, eines *QM*).

## Vier-Augen-Prinzip: geplant und ungeplant

| | Geplante Aufträge (Wartung, Prüfprotokoll) | Ungeplante Aufträge (Störung, Reparatur) |
|---|---|---|
| Fertigmelden | Techniker schließt **direkt ab** → *Abgeschlossen* | → *Fertig zur Abnahme* |
| Zweite Person | nicht nötig | zwingend (Freigabe oder Beanstandung mit Notiz) |
| Folge | Ausführungsdatum wird gesetzt, nächstes Intervall beginnt | Archiv erst nach Freigabe |

Umgesetzt im Trigger `enforce_four_eyes`: Geplante Aufträge passieren die Prüfung automatisch (auch ein direkter
Wechsel auf „Fertig zur Abnahme“ wird zu „Abgeschlossen“). Bei Maschinenaufträgen wird `last_maintenance`
fortgeschrieben; die nächste Fälligkeit zeigt die Maschinenakte, der Folgeauftrag entsteht automatisch
14 Tage vor Fälligkeit. Altfälle (geplant, noch auf Abnahme wartend) schließt das Schema-Skript ab.

## Formblätter und Messmittelliste (nur Rolle QM)

**QM → Formblätter** (nur QM; Schreibrechte sind zusätzlich per Datenbank-Policy gesperrt).

1. **Spalten frei definieren** (z. B. Messmittel, Nr., Standort, Toleranz, Messbereich, Einheit).
   Genau zwei Spalten sind *Eingabe Techniker* (z. B. IST-Wert und Vergleichswert), alle anderen
   schreibgeschützte Stammdaten.
2. **Zeilen frei definieren**, auch per „Aus Excel einfügen“.
3. **Intervall** wählen (täglich bis jährlich, auch halbjährlich) und den Ort festlegen.
4. **Toleranz-Spalte** wählen für die automatische Bewertung.

**Automatische Erzeugung:** Zu Beginn jedes Intervalls (Quartalsanfang, Monatsanfang …) legt das System
ein offenes Prüfprotokoll an. Es erscheint unter *Aufträge → Geplante Wartungen*. Je Formblatt und
Intervall gibt es genau ein Protokoll.

**Eingabemaske des Technikers:** Stammdaten sind gesperrt (Oberfläche **und** Datenbank-Trigger), je Zeile
gibt es genau zwei Eingabefelder. Die Bewertung läuft bei jeder Eingabe:
Abweichung = IST-Wert − Vergleichswert, geprüft gegen die Toleranz. Erkannt werden `±0,02`, `0,02 mm`,
`±0,5 %` und `+0,1 / -0,2`. Abweichungen werden rot hervorgehoben, ungültige Eingaben gelb.
*Protokoll abschließen* speichert den Auftrag direkt als *Abgeschlossen*; danach ist das Protokoll
historisiert und nicht mehr änderbar. Ein CSV-Export ist je Protokoll möglich.

**Historisierung:** Beim Erzeugen werden Spalten und Zeilen in das Protokoll kopiert. Spätere Änderungen am
Formblatt verändern bestehende Protokolle nicht; nur noch nicht begonnene werden beim Speichern aktualisiert.

## Weitere Hinweise

* Reparaturzeit (Stoppuhr), Ausfallzeit und Grund der Störung: siehe Auftragsdetail.
* Fällige Wartungen und Protokolle werden beim Öffnen der App still im Hintergrund erzeugt
  (höchstens einmal pro Stunde, ohne Duplikate).
* Installation als App: über HTTPS (oder `localhost`) in Chrome/Edge über das Installationssymbol,
  auf Android über „App installieren“, auf iOS über „Teilen ➔ Zum Home-Bildschirm“.
