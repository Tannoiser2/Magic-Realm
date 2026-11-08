# Magic Realm — versione digitale

Versione digitale per uso personale di **Magic Realm** (Richard Hamblen, Avalon Hill 1979) nella riedizione
non ufficiale **Super Magic Realm**, costruita con Godot 4.7 a partire dal modulo Tabletop Simulator
(`Desktop/Ludoteca/Magic Realm`). Tutto è in italiano; tessere, pedine dei personaggi, mostri, segnalini,
abitazioni e armi sono le immagini originali del modulo.

Si gioca nel browser da GitHub Pages: https://tannoiser2.github.io/Magic-Realm/

## Cosa c'è

- **Il Reame in 3D**: le 40 tessere esagonali vengono disposte a caso a ogni partita come da regole
  (il fiume parte dalle Cascate e finisce nella Grotta, le strade combaciano, ogni tessera è collegata al fiume).
  Mappa ruotabile e ingrandibile, pedine in rilievo, radure raggiungibili evidenziate.
- **Tre scenari introduttivi** del Super Realm, che insegnano il gioco un pezzo alla volta:
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
- **24 personaggi** con i loro 12 segnalini d'azione, peso, equipaggiamento di partenza e abilità speciali
  (Mira, Resistenza, Furia, Berserk, Gambe corte, Conoscenza delle grotte, Astuto, Navigatore, Affondo,
  Scalatore, Esperienza, Segugio...). Negli scenari 2 e 3 si usano quelli con un'arma e meno di due segnalini magici.
- **Rivali guidati dall'IA** (fino a tre) che esplorano, cercano, si nascondono, riposano e combattono.
- **Salvataggi**: in automatico all'alba di ogni giorno sul dispositivo; con «Salva online» su Firebase
  (progetto `flammerouge-f8669`, radice `magicrealm/partite/<codice>`), da riprendere con il codice di 6 lettere.

Non ancora presenti (scenari 4-6 del Super Realm): magia e incantesimi, tesori, nativi, scambi e ingaggi,
viaggiatori, cavalli e l'attività «Seguire».

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

## Pubblicazione

La pubblicazione non parte a ogni modifica: si avvia a mano (Actions → *Pubblica* → *Run workflow*) oppure con un
commit che nel messaggio contiene `[pubblica]`. Il gioco compare nella ludoteca grazie alla cartella `ludoteca/`.

Font: IM Fell English (titoli) ed EB Garamond (testi), licenza SIL OFL.
