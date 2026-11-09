# Magic Realm — versione digitale

Versione digitale per uso personale di **Magic Realm** (Richard Hamblen, Avalon Hill 1979) nella riedizione
non ufficiale **Super Magic Realm**, costruita con Godot 4.7 a partire dal modulo Tabletop Simulator
(`Desktop/Ludoteca/Magic Realm`). Tutto è in italiano; tessere, pedine dei personaggi, mostri, segnalini,
abitazioni e armi sono le immagini originali del modulo.

Si gioca nel browser da GitHub Pages: https://tannoiser2.github.io/Magic-Realm/

## Magic Realm Classico — modalità sperimentale (ramo feature)

Questo ramo include una **partita completa classica sperimentale**, selezionabile dal menu: mappa di 20 tessere, 16 personaggi originali, segnalini delle due Località Perdute, nove fazioni native originali, limite di 28 giorni e assegnazione di cinque Punti Vittoria. Il codice riutilizza parte del motore Super e non riproduce ancora tutte le regole fisiche classiche; in particolare i quattro Encounter originali sono ancora da sviluppare, così come cavalli ed effetti speciali mancanti.

I test Godot 4.7.2 hanno confermato la generazione delle mappe, la preparazione, il punteggio, la conclusione automatica delle partite e l'apertura del menu Classico. I primi tre test di campagna sono terminati per la morte dell'avventuriero prima del 28º giorno. I test di conclusione al 28º giorno sono predisposti separatamente.

Il sito pubblico GitHub Pages presenta un portale separato per **Super Magic Realm** e **Magic Realm Classico**. La modalità Classica resta indicata come sperimentale; salvataggi locali e partite online sono separati tra le due edizioni.

## Cosa c'è

- **Il Reame in 3D**: le 40 tessere esagonali vengono disposte a caso a ogni partita come da regole
  (il fiume parte dalle Cascate e finisce nella Grotta, le strade combaciano, ogni tessera è collegata al fiume).
  Mappa ruotabile e ingrandibile, pedine in rilievo, radure raggiungibili evidenziate.
- **I sei scenari** del Super Realm, che insegnano il gioco un pezzo alla volta:
  1. *Esplorare il Reame* — movimento (montagne, grotte, fiume a monte e a valle), le tre tabelle di ricerca,
     sentieri nascosti e passaggi segreti, le quattro spedizioni pubbliche.
  2. *Duello tra personaggi* — nascondersi, bloccare, allertare, riposare e il combattimento completo:
     cariche, fuga, bersaglio, attacchi, parate, manovre, scudo e armature, lunghezza e velocità delle armi,
     tabella dei proiettili, fatica, ferite, disimpegno.
  3. *I mostri si risvegliano* — la Tabella delle apparizioni, la riga di mostri in agguato, l'evocazione da
     avvisi gialli, suoni e siti, i Luoghi Perduti, i fantasmi, mostri tremendi con teste, clave e liane,
     Minotauro con lo scudo, Cavaliere scheletro con il destriero, incantesimi di Imp, Succube, Vampiro e
     Demoni (maledizioni, ipnosi, Potere dell'Abisso), fama e notorietà con il moltiplicatore della sera,
     missioni pubbliche e private, rigenerazione a fine mese, 10 Punti Vittoria.
  4. *Tesori e magia* — 152 carte tesoro (con i Tesori nei tesori) nei siti, saccheggio con i casi speciali di
     Stagno, Tumuli, Fossa, Labirinto, Sotterraneo e Tomba, Lettura delle rune, 83 incantesimi (una quarantina
     lanciabili), incanto dei segnalini e delle tessere, fonti di colore, volo, anelli magici.
  5. *I nativi si destano* — 24 gruppi di nativi con le loro pedine, rapporti di ogni personaggio, tiro dei
     nativi, Tabella degli incontri, commercio, ingaggio, blocchi e battaglie, nativi vaganti, 12 PV.
  6. *Arrivano i viaggiatori* — 40 viaggiatori (nomadi, missioni, compiti, visitatori), Punti Vittoria
     assegnati all'inizio e vittoria a fine mese.
- **24 personaggi** con i loro 12 segnalini d'azione, peso, equipaggiamento di partenza e abilità speciali
  (Mira, Resistenza, Furia, Berserk, Gambe corte, Conoscenza delle grotte, Astuto, Navigatore, Affondo,
  Scalatore, Esperienza, Segugio...). Negli scenari 2 e 3 si usano quelli con un'arma e meno di due segnalini magici; dal 4 tutti.
- **Rivali guidati dall'IA** (fino a tre) che esplorano, cercano, si nascondono, riposano e combattono.
- **Salvataggi**: in automatico all'alba di ogni giorno sul dispositivo; con «Salva online» su Firebase
  (progetto `flammerouge-f8669`, radice `magicrealm/partite/<codice>`), da riprendere con il codice di 6 lettere.

Non ancora presenti: cavalli, l'attività «Seguire», il nascondiglio, i capi ingaggiati che agiscono da soli,
le campagne dei viaggiatori, gli incantesimi di controllo e trasformazione (si imparano ma non si lanciano),
alcuni effetti speciali dei tesori (la carta lo indica) e la magia dei nativi incantatori.

## Struttura

| Percorso | Contenuto |
|---|---|
| `scripts/mappa.gd` | costruzione casuale della mappa e grafo delle radure |
| `scripts/reame.gd` | motore: giornata, attività, ricerca, mostri, missioni, vittoria, salvataggi |
| `scripts/combattimento.gd` | combattimento serale |
| `scripts/ia.gd` | decisioni dei rivali |
| `scripts/main.gd` | interfaccia 3D e pannelli |
| `data/*.json` | tessere (strade, sentieri, passaggi, fiume rilevati dalle immagini), personaggi, mostri e Tabella delle apparizioni, oggetti, segnalini, missioni |
| `tools/estrazione/` | script che hanno estratto dati e immagini dal modulo TTS |

## Prove

```
godot --headless --path . --script res://tests/partite_auto.gd     # partite automatiche nei tre scenari
xvfb-run godot --path . --script res://tests/screenshot.gd         # screenshot dei pannelli
python3 tools/controlla_glifi.py                                   # nessun carattere mancante nei font
```

## Plancia di combattimento — Melee Section originale 2e

La scheda di mischia usa la **disposizione della seconda edizione originale**: tre caselle rosse per i mostri sfalsate in diagonale (Charge/Thrust, Dodge/Swing, Duck/Smash), cerchi di attacco con frecce di intercettazione, tre ovali per lo scudo, corazza che protegge i primi due attacchi, elmo per lo Smash e armatura completa per tutti gli attacchi. In basso ci sono i tre quadrati MOVE; a destra la tabella di riposizionamento 1–6 e il box «Usati in questo round». Le immagini delle pedine appaiono nei box una volta rivelate.

La scheda e interattiva: scegliere direzione, manovra, scudo, segnalini FIGHT/MOVE e confermare «Rivela le giocate». La geometria e i riferimenti derivano dal diagramma **Using the Melee Section**, pagina 27 del regolamento della seconda edizione.

**Limite della versione digitale:** riproduciamo layout e comandi fisici, mentre il posizionamento iniziale manuale dei mostri e la successiva permutazione dei loro box utilizzano ancora la logica automatica preesistente del motore. Non presentiamo quindi il risultato come una trasposizione integrale delle regole originali di gestione delle pedine.

## Pubblicazione

Ultimo rilascio richiesto: plancia di combattimento originale 2e per Super e Classico.

La pubblicazione non parte a ogni modifica: si avvia a mano (Actions → *Pubblica* → *Run workflow*) oppure con un
commit che nel messaggio contiene `[pubblica]`. Il gioco compare nella ludoteca grazie alla cartella `ludoteca/`.

Font: IM Fell English (titoli) ed EB Garamond (testi), licenza SIL OFL.
