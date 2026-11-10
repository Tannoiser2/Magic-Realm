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

## Tutorial completo: [titolo, testo, immagine]
const TUTORIAL := [
	["Benvenuto nel Reame",
	"Magic Realm è un gioco di esplorazione: ogni personaggio gira da solo per un Reame pieno di sentieri nascosti, mostri, tesori e magia, e cerca di raggiungere i propri obiettivi prima degli altri.\n\nIl Super Realm si impara con sei scenari, uno dopo l'altro: ognuno aggiunge poche regole nuove. Comincia dallo scenario 1 e passa al successivo solo quando ti senti a tuo agio.\n\nIn questo tutorial trovi: come leggere lo schermo, come si gioca una giornata, come ci si muove e si cerca, come si combatte e, soprattutto, come si vince in ogni scenario. Usa «Avanti» e «Indietro» per sfogliarlo; lo riapri quando vuoi con il pulsante «Tutorial».", ""],
	["Lo schermo",
	"Al centro c'è la mappa del Reame: 40 tessere esagonali, ognuna con alcune radure numerate collegate da sentieri. Trascina per spostare la vista, usa la rotellina o pizzica per lo zoom, tieni premuto il tasto destro o ruota con due dita per girarla. «Centra» riporta la vista sulla tua pedina.\n\nLa TUA pedina è quella grande con il bordo rosso e il segnalino rosso che fluttua sopra. Le altre pedine sono i rivali guidati dal computer; i quadratini colorati sui bordi delle tessere sono i segnalini della mappa (avvisi, suoni, siti), e più avanti compariranno mostri, abitazioni e nativi.\n\nA sinistra c'è la scheda del tuo personaggio, a destra la Cronaca con tutto quello che succede, in basso il pannello delle decisioni.", "mappa"],
	["La scheda del personaggio",
	"In alto vedi il nome, il peso (quanto sei robusto: Leggero, Medio, Pesante, Tremendo) e la radura dove ti trovi.\n\nI SEGNALINI D'AZIONE sono il cuore del personaggio. Quelli azzurri (MOVIMENTO) servono a muoverti e a schivare in combattimento, quelli arancioni (COMBATTE) a colpire, quelli viola (MAGIA) agli incantesimi. La lettera è la forza (L, M, H, T), il numero la velocità (più basso è più veloce), gli asterischi lo sforzo: chi usa troppi asterischi si stanca. Un segnalino affaticato o ferito si scurisce e non si può usare finché non riposi.\n\nSotto ci sono l'equipaggiamento (arma e armature), le missioni da compiere e i rivali con i loro punti.", "scheda"],
	["Come funziona una giornata",
	"Ogni giorno ha sempre la stessa struttura.\n\n1) ALBA: tutti decidono in segreto cosa faranno. Tu lo fai nel pannello in basso, riempiendo le tue fasi (di solito 4, più eventuali fasi extra).\n2) GIORNO: i personaggi giocano il loro turno uno alla volta, in ordine casuale, eseguendo le attività nell'ordine in cui le hanno scritte.\n3) SERA: chi è nella stessa radura di un mostro o di un rivale ostile combatte.\n4) MEZZANOTTE: si riposa e si passa al giorno dopo.\n\nNon puoi cambiare idea durante il giorno: per questo conviene pensare bene al piano. Se non sai cosa fare, il pulsante «Piano consigliato» riempie le fasi al posto tuo, e poi puoi correggerle.", "piano"],
	["Pianificare: muoversi",
	"Per muoverti tocca sulla mappa una radura con l'ANELLO GIALLO: sono quelle raggiungibili dalla tua ultima posizione. Ogni passo occupa una fase e compare nelle caselle numerate; la radura scelta diventa verde e da lì si accendono le successive.\n\nAttenzione: entrare in una radura di montagna costa due fasi, così come risalire il fiume. Alcuni sentieri sono nascosti o segreti e non si vedono finché non li scopri cercando.\n\nQuando a fine turno ti fermi in una tessera, i suoi segnalini si scoprono: è così che si esplora. «Togli l'ultima» annulla l'ultima fase, «Svuota» le cancella tutte.", "piano"],
	["Pianificare: le altre attività",
	"Le schede marroni del pannello aggiungono un'attività alla prossima fase libera.\n\nRICERCA: tiri sulle tabelle per trovare indizi, sentieri nascosti, passaggi segreti, segnalini e (dallo scenario 4) tesori e incantesimi.\nNASCONDERSI (dallo scenario 2): con 1-5 al dado diventi invisibile; i mostri e i rivali non possono bloccarti né attaccarti.\nRIPOSO: rimette in gioco un segnalino affaticato, o trasforma una ferita in fatica.\nALLERTA: prepari l'arma per colpire più forte.\nINCANTO, COMMERCIO, INGAGGIO arrivano negli scenari 4 e 5.\n\nQuando hai finito premi «Conferma».", "piano"],
	["La Ricerca",
	"Quando arriva una fase di Ricerca scegli una tabella. Si tirano due dadi e conta il più alto (1 è il risultato migliore).\n\nCERCA: soprattutto passaggi segreti, sentieri nascosti e indizi.\nSCRUTA: indizi e segnalini; dalle montagne puoi scrutare anche le radure vicine.\nLOCALIZZA: serve a scoprire i segnalini di una tessera dopo che vi hai trovato indizi.\n\nIl risultato «Scopri segnalini» rivela i siti della radura: è quello che serve per le spedizioni dello scenario 1 e per trovare i tesori più avanti. Nello scenario 4 qui compaiono anche Saccheggia (prendi una carta tesoro) e Rune (impari un incantesimo).", "ricerca"],
	["Mostri, blocchi e nascondersi",
	"Dallo scenario 3 i mostri si risvegliano. Ogni mattina il tiro dei mostri decide quali si aggirano; quando finisci il turno in una tessera, i suoi segnalini possono evocarli, e quelli vicini ti raggiungono.\n\nUn mostro nella tua radura ti BLOCCA se sei allo scoperto: il tuo turno finisce lì e la sera combatterete. Per questo la regola d'oro è: metti NASCONDERSI come ultima attività del giorno, e anche come prima se devi passare vicino ai mostri. Chi è nascosto non viene bloccato.\n\nI mostri piccoli valgono poca fama, quelli tremendi (scritta T) sono letali: affrontali solo se la tua arma e la tua armatura reggono.", "mappa"],
	["Il combattimento",
	"Il combattimento avviene la sera e si gioca a round. In cima alla finestra vedi i passi del round, con quello attuale evidenziato.\n\nADESCARE: puoi attirare su di te dei mostri.\nAZIONE: puoi fuggire (con un segnalino Movimento più veloce dei mostri), preparare l'arma, lanciare un incantesimo.\nBERSAGLIO: scegli chi colpire.\nMISCHIA: la parte decisiva, sulla Tavola degli scontri (pagina seguente).\nFATICA e FERITE: alla fine paghi gli asterischi usati e scegli quali segnalini sono feriti.\n\nSe per due round di fila non succede nulla, il combattimento finisce da solo. Se tutti i tuoi segnalini sono feriti, o un colpo raggiunge il tuo peso, muori.", "mischia"],
	["La Tavola degli scontri",
	"Ogni colpo arriva da una DIREZIONE e ogni difensore fa una MANOVRA.\n\nIn alto ci sono i tuoi tre attacchi: AFFONDO colpisce chi fa Carica, FENDENTE chi Schiva, COLPO DALL'ALTO chi si Abbassa. Scegli l'attacco che sta sopra la colonna dove si trova il mostro.\n\nI mostri compaiono nelle caselle rosse: la riga dice da dove arriva il loro colpo. Per evitarlo scegli a destra la MANOVRA della stessa riga. Lo scudo para i colpi di una sola direzione, elmo e corazza proteggono automaticamente.\n\nUn colpo più veloce della manovra avversaria va sempre a segno. Se il colpo è forte almeno quanto il peso del bersaglio, lo uccide. La scelta consigliata è già selezionata: se sei in dubbio, premi «Rivela le giocate».", "mischia"],
	["Come si vince",
	"Ogni scenario ha il suo obiettivo, scritto nella guida che compare all'inizio della partita.\n\nScenario 1: completa per primo le quattro SPEDIZIONI elencate nella scheda (trova i segnalini indicati e cercali nella radura giusta).\nScenario 2: elimina quattro rivali o resta l'ultimo vivo.\nScenari 3 e 4: arriva per primo a 10 PUNTI VITTORIA. Valgono: le missioni completate, ogni sito scoperto, 1 punto ogni 10 di Fama e ogni 20 di Notorietà; nello scenario 4 anche grandi tesori, incantesimi e luoghi nascosti.\nScenario 5: 12 Punti Vittoria, contando anche 1 punto ogni 30 monete d'oro.\nScenario 6: all'inizio distribuisci 12 punti tra cinque traguardi; a fine mese vince chi li ha raggiunti tutti con più margine.\n\nI tuoi Punti Vittoria sono sempre scritti in cima alla scheda.", ""],
	["Consigli per la prima partita",
	"1) Inizia con lo scenario 1 e un personaggio robusto come l'Amazzone, il Capitano o il Cavaliere Nero.\n2) Ogni giorno: muoviti verso una tessera nuova, cerca, e (dallo scenario 2) nasconditi per ultimo.\n3) Leggi la Cronaca a destra: spiega ogni tiro e ogni conseguenza.\n4) Se sei stanco o ferito, passa un giorno a riposare in un posto tranquillo.\n5) Non attaccare i mostri tremendi finché non hai armi e armature adatte: scappa o nasconditi.\n6) Salva quando vuoi con «Salva online»: ottieni un codice per riprendere la partita anche da un altro dispositivo; il gioco salva comunque in automatico ogni alba.\n\nBuon viaggio nel Reame!", ""],
]
