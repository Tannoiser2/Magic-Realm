# Piano di integrazione: Magic Realm classico + componenti 3D

Stato: **fase iniziale**. Il ramo di sviluppo non modifica la versione GitHub Pages pubblicata.

## Principi di compatibilità

- Conservare i sei scenari Super e i vecchi salvataggi.
- Separare `famiglia` (classico/super), `scenario` e `funzioni` in configurazioni versionate.
- Non utilizzare un finto scenario 7: molte funzioni esistenti controllano `scenario >= N`.
- Non attivare il classico nell'interfaccia finché mappa, preparazione, vittoria, IA e test non sono verificati.
- Riferimento regolamentare: Magic Realm seconda edizione (4 Encounter); terza edizione, release 3.1 per chiarimenti.
- Verificare con il regolamento originale ogni flag degli Encounter: i flag di `profili_regole.gd` sono provvisori, non un'implementazione dei quattro Encounter.

## Sequenza di implementazione

1. Test automatici di regressione dei sei scenari Super.
2. Adattatore di compatibilità per lettura dei vecchi salvataggi (profilo implicito Super).
3. Sostituire nei sottosistemi i controlli numerici `scenario >= N` con `ProfiliRegole.abilitata(...)`.
4. Generatore classico da 20 tessere con Borderland iniziale e test di grafo di collegamenti.
5. Preparazione classica: personaggi, tesori, mostri, nativi, condizioni di vittoria e durata.
6. Implementare e testare distintamente i quattro Encounter e la partita completa.
7. IA che pianifica per i requisiti PV e reagisce al rischio nei 28 giorni.
8. Solo dopo: nuovo selettore di modalità nel menu, senza cambiare il default dei salvataggi.

## Pipeline componenti fisici 3D

MakerWorld MakerLab Image-to-3D: https://makerworld.com/it/makerlab/imageTo3d?from=makerlab

Generare *prima* un'immagine di riferimento pulita per ogni famiglia di componenti, preferibilmente con vista frontale/tre quarti e fondale uniforme. Convertire l'immagine in 3D con MakerLab o servizio alternativo autorizzato. Esportare STL/3MF per stampa, GLB per anteprime digitali dove supportato.

### Famiglie e requisiti

| Famiglia | Metodo consigliato | Controlli di stampa |
| --- | --- | --- |
| Personaggi e miniature | Image-to-3D con vista completa | basetta, armi robuste, dettagli minimi, stabilità |
| Mostri e nativi | Image-to-3D e correzione mesh | silhouette leggibile, scala relativa, supporti |
| Tessere esagonali | Modellazione parametrica esatta + texture/relief | diametro, spessore, incastri, combaciamento |
| Abitazioni e luoghi | Image-to-3D oppure CAD parametrico | ingombro, stabilità, geometrie chiuse |
| Segnalini, monete, chits | Modelli parametrici o rilievi | testo inciso, spessori, tolleranze |
| Tesori e armi | Image-to-3D / modelli semplici | dettagli fragile, orientamento |
| Organizer e vassoi | CAD parametrico | dimensioni dei contenitori e tolleranze |

Per le tessere NON utilizzare l'AI image-to-3D come sorgente geometrica principale: è essenziale la geometria esagonale esatta e la compatibilità dei bordi. Per i token sottili è migliore una estrusione vettoriale.

### Catalogazione

Usare uno schema stabile: `component_id`, `famiglia`, `nome`, `source_image`, `mesh_stl`, `mesh_3mf`, `mesh_glb`, `scala_mm`, `stato_qa`, `licenza`. Le immagini e le geometrie generate non sono ancora presenti in questo ramo.

### Validazioni

Ogni mesh destinata alla stampa deve essere manifold, con normali corrette, base stabile, spessori minimi e dimensioni in millimetri. Controllare il risultato nello slicer prima della stampa. Non assumere che la conversione automatica produca modelli stampabili senza interventi.

### Licenze

Il progetto deriva da materiale di un gioco commerciale e da un modulo TTS. Non pubblicare o vendere asset ricavati da immagini coperte da diritti senza verificare le autorizzazioni. Distinguere uso personale e diffusione pubblica.
