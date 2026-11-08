## Testi della guida: introduzione a ogni scenario e suggerimenti che compaiono la prima volta.
class_name Guida
extends RefCounted

const SCENARI := {
	1: ["Scenario 1 · Esplorare il Reame",
		"Obiettivo: completare per primo le quattro spedizioni elencate a sinistra, sotto «Missioni».",
		"La tua pedina è quella sotto il segnalino rosso che galleggia sulla mappa. Ogni giorno, all'alba, registri in anticipo le attività della giornata nel pannello in basso; poi i personaggi giocano a turno in ordine casuale.",
		"In questo scenario ci sono solo due attività. MOVIMENTO: tocca una delle radure con l'anello giallo, vicine alla tua; montagne e risalita del fiume costano due fasi. RICERCA: tiri sulle tabelle Cerca, Scruta o Localizza per trovare indizi, sentieri nascosti, passaggi segreti e i segnalini delle radure.",
		"Una spedizione si completa ottenendo «Scopri segnalini» nella radura giusta della tessera con l'avviso richiesto: prima esplora (quando finisci il turno in una tessera i suoi segnalini si scoprono), poi vai lì e cerca."],
	2: ["Scenario 2 · Duello tra personaggi",
		"Obiettivo: uccidere quattro rivali o restare l'ultimo in piedi.",
		"Nuove attività: NASCONDERSI (con 1-5 al dado diventi invisibile), ALLERTA (prepari l'arma), RIPOSO (recuperi i segnalini affaticati o feriti).",
		"A fine fase puoi bloccare chi è allo scoperto nella tua radura: la sera vi affronterete. Il combattimento si gioca a round: scegli bersaglio, attacco (direzione e segnalino Combattimento) e manovra (segnalino Movimento). Colpisci se sei più veloce o se la tua direzione intercetta la sua manovra."],
	3: ["Scenario 3 · I mostri si risvegliano",
		"Obiettivo: 10 Punti Vittoria, da missioni, siti scoperti, fama e notorietà.",
		"Ogni mattina il tiro dei mostri decide quali si aggirano. Quando finisci il turno in una tessera, i suoi segnalini possono evocarli e quelli già vicini ti raggiungono. I mostri bloccano chi è allo scoperto: nasconditi come ultima attività del giorno e, se devi passare accanto a loro, anche come prima.",
		"Uccidere i mostri dà fama e notorietà; i tremendi cambiano tattica e fanno danni enormi. Scappa se ti attacca qualcosa che può ucciderti con un colpo."],
	4: ["Scenario 4 · Tesori e magia",
		"Obiettivo: 10 Punti Vittoria. Contano anche i grandi tesori, gli incantesimi imparati e i luoghi nascosti.",
		"Nei siti che hai scoperto la RICERCA offre due nuove scelte: Saccheggia (prendi una carta tesoro dalla pila) e Rune (impari un incantesimo). Tocca una carta nella scheda per leggerne l'effetto.",
		"Chi ha segnalini Magia può fare INCANTO: la prima volta del giorno medita, poi trasforma un segnalino in un segnalino di colore. Gli incantesimi si lanciano la sera, in combattimento o su se stessi, se hai il segnalino Magia del tipo giusto e il colore richiesto."],
	5: ["Scenario 5 · I nativi si destano",
		"Obiettivo: 12 Punti Vittoria; ora conta anche l'oro, 1 punto ogni 30.",
		"Nelle abitazioni ci sono i nativi. Con COMMERCIO compri e vendi con il loro capo, con INGAGGIO li paghi perché ti seguano e combattano per te. I rapporti di ogni gruppo con te sono nella scheda.",
		"Attento ai gruppi ostili o nemici: se sei allo scoperto nella loro radura possono bloccarti e attaccarti la sera."],
	6: ["Scenario 6 · Arrivano i viaggiatori",
		"Obiettivo: all'inizio assegni 12 Punti Vittoria a dei traguardi (grandi tesori, incantesimi, fama, notorietà, oro). A fine mese vince chi li ha raggiunti tutti con il margine più ampio.",
		"Ogni sito scoperto, missione o compito completato ti toglie un punto da raggiungere.",
		"Quando saccheggi un sito o compri dai nativi, scende sulla mappa un viaggiatore: nomadi da prendere la sera per 1 oro, missioni da portare a destinazione, compiti, visitatori con cui commerciare."],
}

const SUGGERIMENTI := {
	"piano": "Come si gioca il giorno: registra tutte le fasi in anticipo. Tocca un pulsante per aggiungere un'attività; per muoverti tocca una radura con l'anello giallo (le radure già scelte hanno l'anello verde). Quando le fasi sono complete premi «Conferma il giorno».",
	"tabella": "Ricerca: scegli una tabella. Si tirano due dadi e conta il più alto. Cerca trova soprattutto passaggi e sentieri, Scruta indizi e segnalini, Localizza serve dopo aver trovato indizi nella tessera.",
	"combattimento": "Combattimento: ogni round si svolge in passi (adescare, azioni, bersaglio, mischia). In alto vedi chi ti attacca; i suggerimenti dell'IA sono già selezionati nella mischia, puoi cambiarli o confermare.",
	"saccheggio": "Saccheggio: il dado dice quale carta prendi dalla cima della pila. I tesori trovati compaiono nella scheda: toccali per leggere l'effetto.",
	"incanto": "Incanto: un segnalino Magia incantato diventa un segnalino di colore, che serve a lanciare gli incantesimi di quel colore.",
	"commercio": "Commercio: per comprare tiri sulla Tabella degli incontri e il risultato moltiplica il prezzo. Vendere non richiede tiri.",
	"sera": "Sera: puoi lanciare un incantesimo su di te. Il segnalino Magia usato resta legato finché l'incantesimo dura.",
}
