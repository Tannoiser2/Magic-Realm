# Magic Realm Classico — quattro Encounter della seconda edizione

Questa conversione conserva **Super Magic Realm** come gioco distinto, accessibile dal menu del portale.

## Giocare online

- Portale: https://tannoiser2.github.io/Magic-Realm/
- Super: https://tannoiser2.github.io/Magic-Realm/super/
- Classico: https://tannoiser2.github.io/Magic-Realm/classico/

Nel menu del Classico scegli uno dei quattro Encounter:

| Incontro | Contenuto |
| --- | --- |
| I — Caccia al tesoro | Esplorazione, ricerca, commercio, tesori; senza combattimento |
| II — I mostri attaccano | Come I, con combattimento fra personaggi e mostri |
| III — Guerra | Come II, con guerra fra personaggi e nativi, ingaggio e attività Seguire |
| IV — Magia | Come III, con incanti, incantesimi, rune e magie disponibili nel motore |

Seleziona il personaggio fra i 16 originali, un'abitazione iniziale consentita e fino a tre rivali IA. Distribuisci i cinque punti vittoria, gioca 28 giorni e cerca di ottenere un punteggio non negativo. Il punteggio maggiore definisce il vincitore assoluto. La mappa ha 20 tessere e inizia da Borderland.

## Usare Godot localmente

Clona il ramo pubblicato `main` con `git clone https://github.com/Tannoiser2/Magic-Realm.git`, aprilo in Godot 4.7.2 e premi F5. Durante lo sviluppo, per provare modifiche non ancora pubblicate, clona `feature/classic-horses-combat`.

## Salvataggi

Super e Classico usano salvataggi locali e percorsi Firebase separati. Il Classico mantiene l'Encounter scelto anche dopo ricaricamento.

## Stato delle regole

**Modalità sperimentale, non conversione integrale dell'originale**. I cavalli dei personaggi possono essere comprati presso i nativi, cavalcati oppure utilizzati per trasportare oggetti. Un pony aggiunge movimenti alternati, un cavallo da lavoro un movimento extra, e in grotta bisogna smontare. Le manovre a cavallo possono far colpire il cavallo al posto del cavaliere. Mancano ancora i cavalli dei nativi e diversi casi particolari. Alcune missioni e campagne classiche, diversi incantesimi di controllo e trasformazione, gestione completa dei leader ingaggiati ed effetti particolari dei tesori rimangono incompleti. La scelta di Seguire condivide i principali movimenti e risultati, ma non tutte le interazioni avanzate sono riprodotte.

Per un elenco verificabile di quanto implementato e dei limiti attuali, leggi [AUDIT_REGOLE_CLASSICHE_2E.md](AUDIT_REGOLE_CLASSICHE_2E.md). Non confondere le quattro modalità praticabili con l'intero regolamento da torneo.

## Pubblicazione

Il workflow `Pubblica` genera e distribuisce un sito con tre indirizzi (portale, `super/`, `classico/`), senza cancellare i salvataggi Super. Il ramo di sviluppo viene unito a `main` solamente dopo i test automatici Godot.
