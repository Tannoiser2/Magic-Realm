# Magic Realm Classico + libreria 3D — piano di migrazione

Stato: **prima fase avviata**, non giocabile nella modalità classica.
La pubblicazione su GitHub Pages usa il ramo principale: non modificare `main` fino alla regressione conclusa.

## Base tecnica verificata
- `scripts/reame.gd`: stato giornata, setup, obiettivi, punteggio, salvataggi.
- `scripts/mappa.gd`: generatore di **40 tessere Super** con Cascate, fiume e Grotta; NON riutilizzabile senza modifiche per la disposizione originale.
- `scripts/combattimento.gd`: motore di combattimento.
- `scripts/arcano.gd`, `scripts/nativi.gd`, `scripts/viaggi.gd`: sottosistemi attivati dai numeri di scenario.
- `scripts/ia.gd`: rivali con obiettivi legati al numero di scenario.
- `scripts/profili_regole.gd`: nuova definizione di profili, **non ancora collegata** al motore.

## Architettura obiettivo
1. Profili indipendenti: SUPER 1–6; CLASSICO 1–4 (Encounter); CLASSICO completo; PERSONALIZZATO.
2. Sostituire gradualmente i controlli `scenario >= N` con `regole.abilitata("...")`.
3. Implementare un generatore `classico_20` senza cambiare quello `super_40`.
4. Configurare la vittoria classica (cinque punti distribuiti nelle cinque categorie; 28 giorni) e le condizioni specifiche degli Encounter.
5. Allineare setup, tessere, personaggi, magia, nativi e oggetti ai regolamenti classici. Le etichette presenti in `profili_regole.gd` sono IPOTESI DI PARTENZA, da verificare sulle regole prima dell'implementazione.
6. IA: scelte in base a obiettivi PV, rischio, risorse, incontri e scadenza.
7. Versionare i salvataggi e testare la lettura dei vecchi salvataggi Super.

## Componenti in 3D
Per ogni soggetto, mantenere:
- `original_id`, `tipo`, `variante`, `immagine_fonte`, `diritti`
- `reference_front`, `reference_back` (opzionale), `mesh_glb`, `mesh_stl` (opzionali)
- `dimensioni_mm`, `scala_godot`, `pivot`, `collisione`, `stato_qa`.
Categorie da inventariare dal modulo TTS: personaggi, mostri, nativi, viaggiatori, armi, armature, tesori, abitazioni, segnalini, tessere e altri elementi.

### MakerWorld MakerLab Image-to-3D
Workflow candidato: immagine isolata ad alta risoluzione -> generazione su MakerLab nel browser -> export consentito dal servizio -> QA geometria -> normalizzazione scala/pivot -> import Godot -> STL/3MF per stampa, ove possibile.

**Non esiste in questo repository una API MakerWorld verificata**: l'automazione del caricamento o scaricamento non è attualmente implementata.
Usare il file originale TTS come riferimento per sagoma e identità; non assumere che l'output generativo abbia precisione dimensionale o topologia idonea per la stampa.

### Criteri QA per la produzione
- Nessuna parte mancante, oggetto a pezzo unico quando richiesto.
- Modello watertight/manifold se destinato a stampa 3D.
- Base piana e spessori minimi coerenti con il processo produttivo.
- Orientamento upright coerente, pivot al centro della base.
- Poligoni e texture adeguati a una scena Godot con decine di pedine.
- Controllo visivo fronte/retro e confronto con le illustrazioni originali.

## Sequenza test
1. Test dei profili e non regressione delle sei configurazioni Super.
2. 20 tessere classic: generazione valida ripetuta su molti semi.
3. Tre partite per scenario come smoke test, poi simulazioni su almeno centinaia di semi per i profili completi.
4. Salvataggio/caricamento, invarianti e test di vittoria.
5. Browser desktop e Google TV: performance, camera e click.

## Avvertenze
Questa fase crea la struttura dei profili e la specifica 3D: **non dichiara realizzato il gioco classico né creati modelli 3D**.