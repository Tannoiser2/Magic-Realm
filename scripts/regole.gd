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

[b]Scenario 4: tesori e magia[/b]
Ogni sito ha una pila di tesori (grandi sopra, piccoli sotto) e alcuni anche incantesimi. Dopo averlo scoperto, con la RICERCA puoi saccheggiarlo (il dado indica quale carta prendi dalla cima: se la pila è più corta, niente) o leggere le rune (1-3 impari l'incantesimo, 4 lo risvegli, 5 maledizione, 6 niente). Lo Stagno affatica un segnalino per ogni tesoro, i Tumuli per ogni tentativo, la Fossa richiede due ricerche di fila, il Labirinto ti fa perdere, Sotterraneo e Tomba si aprono con le chiavi o con un segnalino di forza Tremenda. Alcune carte sono Tesori nei tesori: luoghi nascosti con una pila propria, il Forziere da aprire, resti che maledicono. I tesori attivi danno i loro effetti (fasi in più, segnalini, dadi singoli, fonti di colore); le carte con un effetto non ancora gestito valgono per fama, notorietà e oro.
Con l'attività INCANTO (la prima del giorno è la meditazione) un segnalino Magia di tipo I-V diventa un segnalino di colore (bianco, grigio, oro, viola, nero); puoi anche incantare la tessera, che diventa fonte di colore. Gli incantesimi si lanciano la sera: in combattimento come azione (servono un segnalino Magia del tipo giusto, non più lento di chi ti attacca, e il colore richiesto, da un segnalino di colore o dalla radura), fuori dal combattimento su se stessi. Il settimo giorno di ogni settimana tutta la mappa emana magia. Si vince a 10 PV: missioni, siti e luoghi scoperti, 1 per grande tesoro, 1 ogni 2 incantesimi imparati, 1 ogni 10 Fama e 20 Notorietà (tesori compresi).

[b]Scenario 5: i nativi si destano[/b]
Le guarnigioni stanno nelle loro abitazioni; gli altri gruppi compaiono quando finisci il turno in un'abitazione e il tiro dei nativi del giorno è il loro. I nativi vaganti (Banditi, Cultisti, Nani, Elfi) escono dai Luoghi Perduti. Ogni personaggio ha i suoi rapporti (alleato, amichevole, neutrale, ostile, nemico). Con COMMERCIO compri dal capo del gruppo tirando sulla Tabella degli incontri (il risultato moltiplica il valore) o vendi senza tiri; con INGAGGIO paghi il gruppo perché ti segua e combatta con te per 14 giorni. Chi è ostile o nemico può bloccarti a fine fase o attaccarti a inizio combattimento. Si vince a 12 PV: ogni incantesimo imparato vale 1 punto e ogni 30 oro un altro.

[b]Scenario 6: arrivano i viaggiatori[/b]
Ogni sito e ogni gruppo di nativi custodisce un viaggiatore, che scende sulla mappa quando saccheggi il sito o compri dal gruppo, e si rivela quando qualcuno finisce il turno nella tessera. I nomadi si prendono la sera per 1 oro e aiutano fino al giorno dopo; le missioni (10 Notorietà) vanno portate all'abitazione indicata; i compiti (5 Fama) chiedono di visitare quattro siti; i visitatori commerciano (il Fabbro ripara, il Chierico toglie le maledizioni). All'inizio assegni 12 Punti Vittoria tra grandi tesori, incantesimi, fama, notorietà e oro; siti scoperti, missioni e compiti li riducono. A fine mese vince chi ha soddisfatto tutti i traguardi con il margine più ampio.

[b]Non ancora presenti[/b]
I capi ingaggiati che agiscono da soli, le campagne dei viaggiatori, i clan, la trasformazione e 24 incantesimi su 83 (si imparano ma non si lanciano), alcuni effetti speciali dei tesori (indicati sulla carta) e le regole avanzate e opzionali (ferite gravi, meteo e stagioni, furto, eventi...). I nativi incantatori combattono senza magia.

[b]Aggiunti di recente[/b]
Dallo scenario 4: SEGUIRE un altro personaggio e il NASCONDIGLIO (lasci oggetti e oro in una radura e li riprendi con una Ricerca, senza tiro). Dallo scenario 5: i cavalli dei nativi, da comprare e cavalcare. Dallo scenario 3: chi muore ricomincia alla Locanda il giorno dopo il successivo con un nuovo avventuriero; a fine mese tornano anche i nativi non ingaggiati.

[b]Comandi[/b]
Trascina con il tasto sinistro per spostare la mappa, con il destro per ruotarla; rotellina o pizzico per lo zoom; su iPad trascina con un dito, pizzica e ruota con due dita. Clic su una radura evidenziata per registrare un movimento. La partita si salva da sola all'alba di ogni giorno; «Salva online» la mette su Firebase con il suo codice."""
