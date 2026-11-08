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

## Supporto GLB aggiunto al rendering

Il file `scripts/main.gd` ora cerca automaticamente miniature opzionali sotto `res://assets/3d/`: `personaggi/<pedina>.glb`, `mostri/<tipo>.glb`, `nativi/<gruppo>.glb`, `abitazioni/<id>.glb`, `viaggiatori/<id>.glb`. Se non trova un modello, mostra la pedina originale 2D: nessuna sostituzione distruttiva.

**Contratto di import Godot**: GLB con asse Y verticale, superficie della base sul piano Y=0 e larghezza della figura normalizzata a una unità di Godot; il visualizzatore ridimensiona automaticamente il nodo alla dimensione della pedina esistente. Per la stampa 3D, conservare separatamente gli STL nelle misure reali in millimetri. Le basi campione STL sono prototipi con misure arbitrarie, da convalidare prima di adottarle in serie.

Il supporto GLB è scritto ma non è stato ancora testato con un progetto Godot avviato: non dichiarare riuscita l'importazione fino alla verifica runtime.


## Progresso del generatore classico (8 novembre 2026)

Creato `scripts/mappa_classica.gd` con le 20 tessere elencate nel regolamento originale, divise in 5 Caves, 5 Mountain, 5 Valley e 5 Woods. Borderland (ID 5) è sempre la prima tessera. Il codice tenta disposizioni casuali collegate da varchi, riutilizzando le informazioni originali di `data/tessere.json`, e fornisce un controllo di connessione a livello di tessera. Disponibile `tests/mappa_classica_test.gd` con cinque semi. **Non collegato alle partite** e **test runtime ancora da eseguire**: generatore da considerare sperimentale e non ancora equivalente alle procedure di piazzamento multiplayer del regolamento.

Lista ID: Cave [4,5,6,7,18]; Mountain [3,13,14,15,16]; Valley [21,22,23,24,25]; Woods [26,27,28,29,30]. Riferimento: 2a edizione, Preparazione della mappa e Tabella dei segnalini mappa.
