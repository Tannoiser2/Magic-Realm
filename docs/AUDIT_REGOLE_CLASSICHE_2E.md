# Magic Realm (Avalon Hill) — audit della seconda edizione

Riferimento regolamentare: https://magicrealm.ca/magic-realm-rules-second-edition/

## Stato dei quattro Encounter

| Sezione | Stato | Implementazione |
| --- | --- | --- |
| I — Mappa da 20 tessere | implementata, testata | `MappaClassica`, partenza Borderland e collegamenti |
| I — Movimento, nascondersi, ricerca, riposo | funzionanti con adattamenti | motore Reame condiviso |
| I — Tesori e saccheggio | funzionanti con adattamenti | Arcano anche senza magia |
| I — Nativi e quattro visitatori | implementati parzialmente | nove gruppi originali; quattro visitatori commerciali |
| I — Cavalli rotondi | implementato e testato | 17 cavalli, mercato nativo, carico, movimento e manovre; due cavalli speciali nei luoghi nascosti |
| I — Punti vittoria | implementati, testati | cinque punti e rettifica dell'oro iniziale |
| II — Combattimento contro i mostri | implementato | Combat; esclusione di nativi e personaggi |
| III — Combattimento umano/nativi | implementato con adattamenti | Combat + Nativi |
| III — Ingaggio | implementato con adattamenti | Nativi |
| III — Seguire (*FOLLOW*) | implementato parzialmente | movimento di gruppo, occultamento, scoperte, riposo; non tutti i dettagli di scelta/interruzione |
| IV — Magia | implementata parzialmente | selezione chits, incanto, rune, diversi incantesimi |
| Quattro Encounter dal menu | implementati, testati | selettore e salvataggi indipendenti |
| 7° giorno | implementato, testato | mostri/nativi della riga di caccia ritornano e rigenerano |
| Morte/rientro | implementato, testato | rientro alla Locanda con medesimo personaggio |
| Partite Super | invariate | sei scenari progressivi e partita libera |

## Differenze e regole ancora mancanti

**Non è corretto presentare questa conversione come una riproduzione integrale della seconda edizione.** Restano da implementare o completare:

- Regole precise di `FOLLOW`: interruzione volontaria per fase, partecipazione del leader ingaggiato e interazioni con i seguaci dei seguaci.
- Cavalli dei nativi (segnalini quadrati): manovre, cambio tattica, protezione, morte e rigenerazione distinti dai cavalli personali. Le regole dei cavalli rotondi sono implementate in prima versione, ma mancano alcuni casi limite di trasferimento, movimento e combinazioni con incantesimi.
- Le sei tessere visitatore/missione originali nella loro doppia faccia, i 2 incarichi `FOOD/ALE` e `ESCORT PARTY`, le sei campagne e i relativi effetti su fazioni e ricompense.
- Leader nativi ingaggiati che svolgono turni indipendenti; controllo dettagliato di underlings e denizen-versus-denizen.
- Magia completa della 2e: tutti gli incantesimi lanciabili, pacificazione, controllo, trasformazioni, interruzioni, tempi/colore e effetti speciali. Parte degli incantesimi esistenti resta soltanto apprendibile.
- Tutti gli effetti particolari dei tesori e i casi speciali di commercio e combattimento.
- Alcune regole avanzate e opzionali (meteo, stagioni ecc.). Il Nascondiglio esiste ora nel Super (scenari 4-6); nel Classico non è attivo. Queste **non** sono parte necessaria dei quattro Encounter base, ma sono presenti nel libro originale.
- Conformità puntuale della preparazione di tutti i mazzi e contatori al tabellone della seconda edizione: i dati fonte derivano dal modulo Super e alcuni vengono filtrati.
- Validazione umana in browser di campagne plurigiocatore e con IA, oltre ai test headless.

## Lista di controllo per area (verifica del 10 novembre 2026)

Il testo integrale della 2a edizione non è nel progetto: la lista segue la struttura dei quattro Encounter e va confrontata, numero per numero, con il regolamento di magicrealm.ca appena sarà possibile scaricarlo.

| Area | Encounter | Stato | Note |
| --- | --- | --- | --- |
| Preparazione: 20 tessere, segnalini, abitazioni, guarnigioni | I | OK | |
| Partenza alla Locanda o alle abitazioni del personaggio | I | OK | |
| Registrare le fasi (base, luce del sole, grotte) | I | OK | |
| Movimento, strade nascoste e segrete | I | OK | |
| Nascondersi, Ricerca e tabelle | I | OK | |
| Riposo, Allerta | I | OK | |
| Tiro dei mostri e mostri che si aggirano | I | OK | |
| Blocco a fine fase | I | OK | |
| Ritorno del 7° giorno | I | OK | solo la riga che caccia |
| Commercio con nativi e visitatori | I | SEMPL. | quattro visitatori commerciali; casi speciali mancanti |
| Cavalli personali (rotondi) | I | OK | |
| Cavalli dei nativi (quadrati) | III | SEMPL. | combattono, ma senza tutte le regole proprie |
| Saccheggio e tesori nei siti | I | OK | |
| Effetti dei tesori | I | SEMPL. | circa due terzi hanno effetto in gioco |
| Punti vittoria (5) e punteggio finale | I | OK | |
| Combattimento con i mostri | II | OK | |
| Fatica, ferite, morte | II | OK | |
| Morte e rientro alla Locanda | II | OK | |
| Combattimento tra personaggi e con i nativi | III | OK | |
| Rapporti con i nativi e attacchi a inizio combattimento | III | OK | |
| Ingaggio | III | SEMPL. | i capi ingaggiati non hanno turni propri |
| Seguire | III | SEMPL. | mancano interruzione per fase e capi ingaggiati |
| Missioni e campagne delle tessere visitatore | III | MANCA | |
| Magia: colori, segnalini, rituali, incanto | IV | OK | |
| Incantesimi lanciabili | IV | SEMPL. | 59 su 83 lanciabili (motore comune al Super) |
| Trasformazioni, controllo dei mostri, pacificazione | IV | MANCA | |
| Nativi incantatori | IV | MANCA | combattono senza magia |
| Regole opzionali (meteo, stagioni, ecc.) | — | MANCA | non necessarie agli Encounter |

## Criteri di verifica per ogni rilascio

1. Tutti i test headless Godot 4.7.2 verdi.
2. Ogni Encounter avviabile dal menu con 20 tessere, 28 giorni, 5 PV.
3. Test automatico di una partita di ciascun Encounter.
4. Salvataggio e ripristino, inclusi i salvataggi Super preesistenti.
5. Export Web e distribuzione confermati.
6. Etichetta **Sperimentale** finché le differenze elencate non sono risolte.

Nessun modello generativo 3D aggiuntivo è richiesto per usare gli Encounter.
