## Testo delle regole in breve (pannello «Regole»).
extends RefCounted

const TESTO := """[b]Il Reame[/b]
La mappa è fatta di 40 tessere esagonali; si gioca nelle radure numerate, collegate da strade, gallerie (nere), sentieri nascosti e passaggi segreti (si usano solo dopo averli scoperti) e dal fiume, che scende dalle Cascate alla Grotta. Ci sono quattro tipi di radura: di bosco, di montagna (cerchio tratteggiato), di grotta (nere) e d'acqua (azzurre).

[b]La giornata[/b]
[b]Alba[/b]: registri in segreto le attività del giorno. Hai 2 fasi base e 2 fasi di luce, più eventuali fasi extra date dalle abilità del personaggio. Chi inizia il giorno in una grotta, o vi entra, non usa le fasi di luce; il Nano usa sempre solo le fasi base.
[b]Sorgere del sole[/b] (scenario 3): si tira un dado sulla Tabella delle apparizioni: i mostri di quella riga sono «in agguato» (i Fantasmi lo sono sempre).
[b]Giorno[/b]: i personaggi giocano il turno in ordine casuale. All'inizio del turno chi era nascosto si rivela (scenari 2 e 3).
[b]Sera[/b]: si combatte nelle radure dove ci sono personaggi con mostri o con altri personaggi ostili.
[b]Mezzanotte[/b]: i segnalini tornano pronti a evocare, gli indizi scadono; la Cappella toglie maledizioni e ipnosi. Al giorno 28 di ogni mese i mostri si rigenerano.

[b]Le attività[/b]
[b]Movimento[/b]: verso una radura collegata. Salire su una montagna richiede due fasi di movimento consecutive verso la stessa radura; entrare nell'acqua da terra, o risalire la corrente, richiede due movimenti; scendere la corrente uno solo. Chi porta oggetti più pesanti del suo segnalino Movimento più forte li abbandona.
[b]Ricerca[/b]: scegli la tabella e tiri due dadi tenendo il più alto.
  Cerca: 1 Scelta, 2 Indizi, 3 Passaggi segreti, 4 Sentieri nascosti, 5 Nemici nascosti, 6 Niente.
  Scruta: 1 Scopri segnalini, 2 Indizi, 3-4 Nemici nascosti, 5 Indizi, 6 Niente. Da una montagna puoi scrutare altre radure della tessera e delle tessere vicine.
  Localizza: 1-2 Scelta, 3 Sentieri nascosti, 4-5 Scopri indizi, 6 Niente.
  «Indizi» ti mostra i segnalini della tessera; «Scopri indizi» vale come «Scopri segnalini» se nello stesso giorno hai già trovato indizi in quella tessera. «Scopri segnalini» rivela i siti della radura.
[b]Nascondersi[/b]: riesce con un risultato inferiore a 6. Nascosto non puoi essere bloccato dai mostri né (senza «Nemici nascosti») dagli altri personaggi.
[b]Allerta[/b]: giri l'arma sul lato in allerta, di solito più veloce o più tagliente.
[b]Riposo[/b]: recuperi un segnalino affaticato a un asterisco, o porti un segnalino ferito ad affaticato.

[b]Fine di fase e di turno[/b]
Chi termina una fase allo scoperto nella radura di un mostro viene bloccato e il suo turno finisce. Quando finisci il turno in una tessera, i suoi segnalini si scoprono; poi i mostri in agguato già presenti nella tessera raggiungono la tua radura, l'avviso giallo evoca mostri nella tua radura e i segnalini rossi (suoni e siti) evocano mostri nelle loro radure, ognuno una volta al giorno. Un Luogo Perduto rivelato aggiunge altri cinque segnalini rossi.

[b]Il combattimento[/b]
Ogni round: si possono adescare i mostri, quelli non assegnati vanno a caso sui personaggi allo scoperto; si caricano gli altri personaggi; ognuno fa un'azione (fuggire, allertare l'arma, attivare un oggetto) con un segnalino più veloce delle minacce; si sceglie il bersaglio; poi si giocano in segreto attacco (o parata), manovra e scudo.
Affondo colpisce chi fa Carica, Fendente chi Schiva, Colpo dall'alto chi si Abbassa; un attacco più veloce della manovra colpisce comunque. I mostri vengono piazzati con due dadi (il rosso dà la direzione d'attacco, il bianco la manovra) e sulle caselle in diagonale cambiano tattica.
Nel primo round colpisce prima l'arma più lunga, poi il più veloce. Il danno è la lettera dell'arma (+1 se il segnalino Combattimento è più forte dell'arma, +1 per stella; colpendo un'armatura si perde una stella). Un danno pari o superiore alla vulnerabilità uccide; sull'armatura la danneggia o la distrugge e infligge una ferita (da Medio in su). Le armi da tiro tirano sulla tabella dei Proiettili.
Si possono giocare al massimo due asterischi per round: chi ne gioca due affatica un segnalino. Ogni ferita mette fuori gioco un segnalino; con tutti i segnalini feriti si muore. Il combattimento finisce dopo due round consecutivi senza fatica, ferite, morti o rivelazioni.
I mostri Tremendi che colpiscono e non uccidono afferrano la preda: girano sul lato rosso, fanno danno Massimo e impediscono la fuga.

[b]Punti e vittoria[/b]
Scenario 1: completa per primo le quattro spedizioni pubbliche.
Scenario 2: uccidi quattro personaggi o resta l'ultimo in vita.
Scenario 3: raggiungi 10 Punti Vittoria: missioni pubbliche e privata, 1 PV per ogni sito scoperto, 1 PV ogni 10 di Fama e ogni 20 di Notorietà. Uccidere un mostro dà fama e notorietà, moltiplicate per il numero di uccisioni della stessa sera.

[b]Non ancora presenti[/b]
Questa versione copre i primi tre scenari del Super Realm: mancano magia e incantesimi, tesori, nativi, scambi, ingaggi, viaggiatori, cavalli e l'attività «Seguire».

[b]Comandi[/b]
Trascina con il tasto sinistro per spostare la mappa, con il destro per ruotarla; rotellina o pizzico per lo zoom. Clic su una radura evidenziata per registrare un movimento. La partita si salva da sola all'alba di ogni giorno; «Salva online» la mette su Firebase con il suo codice."""
