# WunderWaffen — adattamento digitale (Godot 4)

Versione digitale per uso personale di **WunderWaffen** di Walter Obert (edizione italiana 2025, Oliphante /
Ares Games). Componenti, illustrazioni e regole © dei rispettivi autori: le immagini vengono dalle scansioni
della copia fisica e non vanno distribuite pubblicamente.

**Gioca nel browser:** https://tannoiser2.github.io/WunderWaffen/

## Avvio
1. Apri Godot 4 (testato su 4.7) → *Importa* → seleziona `project.godot`.
2. Premi **F5**. F11 alterna schermo intero e finestra.

## Cosa c'è
- **Quattro fazioni** (Germania, Unione Sovietica, Stati Uniti, Regno Unito), ognuna Umana o IA. Con più persone
  allo stesso dispositivo, prima di ogni turno compare la schermata "tocca a…", perché si vedono i retri delle pedine.
- **Partita a due** (variante del regolamento): giocatore A con Regno Unito e Unione Sovietica, giocatore B con
  Stati Uniti e Germania; vince chi ha il punteggio più alto con la sua fazione più debole.
- **Regole complete del regolamento 2025**: pedine a doppia faccia (due per sé, una girata a un'altra fazione),
  scelta alla cieca della riserva, territori con caselle a simbolo, eliminazioni (≥ per gli Alleati, > per il
  tedesco), maggioranze e spareggi in Politica, Fortezze, territori condivisi con la Politica, Conferenza,
  tracciati Morale, Politica, Eventi (18 caselle con le loro due opzioni) e Ricerca, le 24 carte Ricerca con tutti
  gli effetti, le 24 tessere Territorio, le due parti (con la scelta delle 12 pedine), Berlino e il punteggio finale.
- **Preparazione storica** delle tessere (pag. 18-19) oppure tessere a caso; carte Ricerca iniziali del tedesco
  attivabili dal menu.
- **IA** su tre livelli. Prova ogni mossa del turno su una copia della partita e la valuta con una stima del
  punteggio finale (PV, territori, Morale e Politica, Ricerca e carte, presenza sul tabellone, Berlino),
  giocando per vincere contro l'avversario più pericoloso.
- **Tabellone** ricomposto dalle 10 scansioni della mappa (la striscia centrale mancante è stata ricostruita),
  con zoom (rotella), spostamento (trascinamento) e schede dei territori passando il mouse.
- **Regole in breve**, diario della partita e consiglio dell'IA durante il proprio turno.

## Gioco online
Dal menu, **GIOCA ONLINE** (anche dalla versione web). Usa lo stesso progetto Firebase degli altri giochi
(Realtime Database, piano gratuito), con le stanze sotto `wunderwaffen/rooms`.

- **Chi crea la stanza** sceglie prima nel menu le fazioni e il livello dell'IA: le fazioni su UMANO diventano i
  posti per gli amici (la prima è la sua). Scrive il nome, preme *Crea una stanza* e comunica il codice di 4
  lettere. Quando ci sono tutti preme *Inizia online*: i posti liberi li gioca l'IA.
- **Gli amici** scrivono il nome e il codice e premono *Entra*.
- Ogni decisione è una mossa numerata nel database (`acts/0`, `acts/1`, …). Tutti i dispositivi fanno girare lo
  stesso motore con lo stesso seme e applicano le stesse mosse, quindi la partita è identica ovunque. Le fazioni
  IA le gioca il dispositivo di chi ha creato la stanza.
- **Se cade la linea** si rientra con lo stesso codice e *Entra*. Se un giocatore tace per un minuto, al suo posto
  gioca l'IA finché non rientra.

**Configurazione Firebase.** Le regole sono in `firebase/database.rules.json`: comprendono quelle degli altri
giochi più la sezione `wunderwaffen` (c'è anche la sezione generica `$game`). Se non sono già pubblicate vanno
incollate nella console di Firebase (Realtime Database → Regole) al posto delle precedenti; senza questo
passaggio la creazione della stanza risponde "Permission denied".

**Prove senza Firebase.** `tests/firebase_mock.py` è un finto Firebase locale. Con `WW_DB_URL`, `WW_AUTH_URL` e
`WW_REFRESH_URL` che puntano lì, `tests/online_play.gd` fa giocare una partita intera a due istanze.

## Prove
```
godot --headless --path . -s res://tests/check.gd                   # compila tutti gli script
godot --headless --path . -s res://tests/sim.gd -- 6 1              # 6 partite IA contro IA, livello normale
godot --headless --path . -s res://tests/sim.gd -- 4 2 due          # partita a due, livello difficile
xvfb-run godot --path . -s res://tests/shot.gd -- game 5 /tmp/g.png 3   # screenshot (umano = Regno Unito)
xvfb-run godot --path . -s res://tests/ui_auto.gd -- 4 3 /tmp/shots     # tutta una partita passando dai pannelli
```

## Struttura
- `scripts/data/ww_data.gd` — territori (caselle, confini, posizioni sul tabellone), pedine (fronte, retro e
  destinatario), tracciati Eventi, tessere, carte Ricerca. Le parti geometriche sono generate da `tools/gen_data.py`.
- `scripts/core/engine.gd` — motore delle regole (stato in un unico dizionario, copiabile per l'IA).
- `scripts/core/ai.gd` — giocatore artificiale.
- `scripts/net/` — Firebase (REST) e sessione online in lockstep.
- `scripts/ui/` — menu, tabellone, schermata di gioco, regole.
- `assets/` — tabellone, pedine e segnalini, tessere, carte, caselle degli Eventi, font (Nunito, Oswald,
  Special Elite, Black Ops One; licenze OFL e Apache nella cartella).
- `ludoteca/` — scheda e copertina per la pagina della ludoteca.
