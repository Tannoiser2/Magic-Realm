# Super Magic Realm — lista di controllo regola per regola

Fonte: regolamento Super Magic Realm (sezioni 1-11) e i sei libretti degli scenari.
Verifica fatta sul codice (`reame.gd`, `combattimento.gd`, `arcano.gd`, `nativi.gd`, `viaggi.gd`, `ia.gd`, `main.gd`) e con i test automatici.

Legenda: **OK** = presente come da regolamento · **SEMPL.** = presente ma semplificata · **MANCA** = non presente · **N/A** = solo componenti fisici o note.

Data della verifica: 10 novembre 2026.

## 2 — Pezzi di gioco

| Regola | Stato | Note |
| --- | --- | --- |
| 2.1 Mappa: tessere, lato incantato, segnalini mappa, abitazioni | OK | 40 tessere generate; lato incantato con Incanto |
| 2.2 Mostri, nativi, viaggiatori | OK | dati originali; i nativi incantatori non lanciano magie (SEMPL.) |
| 2.3.3 Cavalli | OK | da scenario 5: cavalli dei nativi (Chart of Clans), carico, movimento, manovre |
| 2.3.4-2.3.5 Armi e armature | OK | |
| 2.3.6-2.3.7 Tesori | SEMPL. | 96 tesori su 152 con effetto in gioco; gli altri si vendono o valgono punti |
| 2.3.8 Incantesimi | SEMPL. | 59 su 83 si lanciano (17 aggiunti: incantesimi di luogo, rapporti con i nativi, scambi di tipo magico, comando di mostri); gli altri 24 si imparano soltanto |
| 2.3.9 Artefatti e libri degli incantesimi | OK | si leggono con la Ricerca (rune) |
| 2.4 Scheda di preparazione (guarnigioni, visitatori, tesori nei tesori) | SEMPL. | i «tesori nei tesori» sono ridotti a carte casuali nel sito |
| 2.5-2.6 Pezzi del personaggio, diario | OK | scheda personaggio e registro a schermo |

## 3 — Preparazione

| Regola | Stato | Note |
| --- | --- | --- |
| 3.1-3.2 Scheda e mappa | OK | mappa casuale valida (fiume, collegamenti) |
| 3.3 Scelta dei personaggi | OK | 24 personaggi |
| 3.4 Missioni | OK | scenario 1 pubbliche; dallo scenario 3 pubbliche e private |
| 3.5 Scelta degli incantesimi | SEMPL. | scelti in automatico tra i tipi del personaggio |
| 3.6 Partenza | OK | Locanda; scenario 2 altre abitazioni |
| 3.7-3.8 Segnalini mappa, abitazioni rivelate | OK | |

## 4 — Meccanica

| Regola | Stato | Note |
| --- | --- | --- |
| 4.1 Dadi | OK | due dadi, il più alto; tesori e abilità che lo modificano |
| 4.2 Segnalini azione (fatica, ferite, impegno negli incantesimi) | OK | |
| 4.3 Oggetti, carico e abbandono | OK | |
| 4.4 Carte tesoro | SEMPL. | vedi 2.3.7 |
| 4.5 Condividere informazioni e spiare | SEMPL. | si sbirciano i segnalini; niente scambio di informazioni fra giocatori |
| 4.6 Magia (colori, tipi, rituali) | SEMPL. | colori del giorno, delle tessere e dei segnalini; mancano trasformazioni e controllo |
| 4.7 Clan | MANCA | uccidere un nativo rende nemico solo il suo gruppo, non tutto il clan |
| 4.8 Viaggiatori | OK | scenario 6 |
| 4.9 Rapporti commerciali | OK | cinque livelli per personaggio |
| 4.10 Rigenerazione mensile | OK | mostri e, da questa versione, anche i nativi non ingaggiati |
| 4.11 Missioni | OK | |

## 5-7 — Giornata

| Regola | Stato | Note |
| --- | --- | --- |
| 5.1-5.3 Sequenza del giorno e del combattimento | OK | |
| 6.1 Avanzamento del giorno | OK | |
| 6.2 Alba degli uccelli: registrare le attività | OK | piano con carte e spiegazioni |
| 6.3 Sorgere del sole: tiro dei mostri, seguitori | SEMPL. | gli ingaggiati seguono sempre chi li paga, non si possono dividere |
| 7.1 Ordine di turno casuale | OK | |
| 7.2 Inizio fase | OK | |
| 7.3 Movimento e volo | OK | strade nascoste/segrete, grotte, volo |
| 7.4 Nascondersi | OK | |
| 7.5 Ricerca (tabelle) | OK | |
| 7.6 Commercio | OK | scenario 5 |
| 7.7 Ingaggio | SEMPL. | i capi ingaggiati non hanno turni propri |
| 7.8 Riposo | OK | |
| 7.9 Allerta | OK | |
| 7.10 Incanto (tessere e segnalini) | OK | |
| 7.11 Seguire | SEMPL. | da scenario 4 (prima solo Classico): segui un altro personaggio, ma non i capi ingaggiati |
| 7.12 Nascondiglio | OK | **nuovo**: da scenario 4, carta «Nascondiglio»; si riprende con Ricerca senza tiro |
| 7.13 Blocco a fine fase | OK | |
| 7.14 Missioni a fine fase | OK | |
| 7.15 Mostri che si aggirano | OK | |

## 8 — Sera e combattimento

| Regola | Stato | Note |
| --- | --- | --- |
| 8.1 Tramonto | OK | |
| 8.2 Battaglie con i nativi | OK | ostili/nemici tirano per attaccare |
| 8.3 Inizio round | OK | |
| 8.4 Adescare | OK | |
| 8.5 Assegnazione casuale | OK | |
| 8.6 Carica tra personaggi | OK | |
| 8.7 Schieramento | OK | |
| 8.8 Azioni (fuga, armi, incantesimi) | OK | |
| 8.9 Assegnazione dei bersagli | OK | incantesimi benevoli: SEMPL. |
| 8.10 Mischia (tabella dello scontro) | OK | plancia cliccabile |
| 8.11 Fatica e ferite | OK | |
| 8.12 Disimpegno | OK | |
| 8.13 Bottino (fama, notorietà, oro) | SEMPL. | manca la regola dei «rapporti rovinati» |
| 8.14 Fine combattimento | OK | |
| 8.15 Mezzanotte | SEMPL. | **nuovo**: le armi tornano non in allerta; pozioni non ancora implementate |
| 8.16 Rigenerazione di fine mese | OK | **nuovo**: anche i nativi |

## 9 — Fine partita

| Regola | Stato | Note |
| --- | --- | --- |
| 9.1 Morte e nuovo inizio | OK | **nuovo**: dallo scenario 3 si ricomincia alla Locanda il giorno dopo il successivo, con una nuova missione privata e (scenario 6) nuovi PV |
| 9.2 Ritirarsi dal gioco | SEMPL. | si può solo abbandonare la partita |
| 9.3 Vittoria e punteggio | OK | regole proprie di ogni scenario |
| 9.4 Chiarimenti sulle missioni | SEMPL. | |
| 9.5 Limite di tempo | OK | 56 giorni, 84 nello scenario 6 |
| Campagne (scenario 6) | MANCA | |

## 10 — Regole avanzate (tutte facoltative)

| Regola | Stato |
| --- | --- |
| 10.1 Ferite gravi | MANCA |
| 10.2 Taglie | MANCA |
| 10.3 Cavalli dispersi | MANCA |
| 10.4 Capi protetti | MANCA |
| 10.5 Nativi vaganti a tema | MANCA |
| 10.6 Valore affettivo | MANCA |
| 10.7 Credito | MANCA |
| 10.8 Missioni e compiti a terra | MANCA |
| 10.9 Equitazione | MANCA |
| 10.10 Raggruppamento | MANCA |
| 10.11 Vendita | MANCA |
| 10.12 Stagioni e meteo | MANCA |
| 10.13 Tattiche di sopravvivenza | MANCA |

## 11 — Regole opzionali

| Regola | Stato |
| --- | --- |
| 11.1 Attività in volo | SEMPL. (volo base presente) |
| 11.2 Abilità opzionali | MANCA |
| 11.3 Furto | MANCA |
| 11.4 Ingaggiare personaggi non usati | MANCA |
| 11.5-11.6 Sviluppo ed esteso | MANCA |
| 11.7 Combattere con due armi | MANCA |
| 11.8 Teste di drago | MANCA |
| 11.9 Incantesimi più facili da imparare | MANCA |
| 11.10 Gittata | MANCA |
| 11.11 Eventi | MANCA |
| 11.12 Commercio esteso | MANCA |
| 11.13 Messo alle strette | MANCA |

## Riepilogo

- Regole base (sezioni 2-9): 67 voci. OK 51, semplificate 14, mancanti 2 (clan, campagne).
- Regole avanzate e opzionali (sezioni 10-11): 25 voci, 24 mancanti e 1 semplificata. Non servono per i sei scenari.
- Lavori più importanti rimasti: incantesimi lanciabili (24 mancanti: trasformazioni, evocazioni, controllo di cavalli e personaggi, tabelle speciali), effetti dei tesori, capi ingaggiati con turni propri, clan, campagne, pozioni.

## Test

`tests/incantesimi_nuovi_test.gd`, `tests/nascondiglio_test.gd`, `tests/ripartenza_super_test.gd`, `tests/partite_auto.gd` (scenari 1-6, tre semi), `tests/tutorial_auto.gd`.
