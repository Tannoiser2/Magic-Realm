## Tutorial guidato: una vera partita preparata, lezione dopo lezione, con i dadi decisi in anticipo
## perché ogni situazione vada come spiegato. Il pannello della guida dice cosa fare; le scelte
## sbagliate vengono fermate con un avviso che spiega perché.
class_name Tutorial
extends RefCounted

var g: Reame
var passi: Array = []
var i := 0
var attivo := false
var in_attesa := false
var evid: Array = []
var carta := ""
var dati := {}
signal cambiato

func _init(reame: Reame) -> void:
	g = reame

func u() -> Dictionary:
	return g.umano()

func nome(k: String) -> String:
	return g.nome_r(k) if k != "" else "?"

# ------------------------------------------------------------ preparazione della partita
static func prepara_partita(r: Reame) -> void:
	r.nuova(5, "paladino", [], 20261110)
	r.s["tutorial"] = true
	r.s["scenario"] = 1
	# le regole seguono lo scenario della lezione
	r.s.erase("profilo_regole")
	r.s["missioni_pubbliche"] = []
	var p := r.umano()
	# niente missioni: gli obiettivi li spiega il tutorial
	p["missioni"] = []
	p["incantesimi"] = ["i_make_whole", "i_peace"]
	p["inc_iniziali"] = p["incantesimi"].duplicate()

func avvia() -> void:
	attivo = true
	_costruisci()
	i = 0
	_entra()

func corrente() -> Dictionary:
	return passi[i] if i < passi.size() else {}

func _entra() -> void:
	var st := corrente()
	evid = []
	carta = ""
	if st.is_empty():
		attivo = false
		cambiato.emit()
		return
	var att = st.get("attendi")
	if att != null:
		var lista: Array = att if att is Array else [att]
		if not (g.richiesta.get("tipo", "") in lista):
			in_attesa = true
			cambiato.emit()
			return
	in_attesa = false
	if st.has("prepara"):
		st["prepara"].call()
	if st.has("evid"):
		evid = st["evid"].call()
	carta = st.get("carta", "")
	cambiato.emit()

func avanti() -> void:
	i += 1
	_entra()

func testo() -> String:
	var st := corrente()
	if st.is_empty():
		return ""
	var t: String = st["t"]
	for k in dati:
		t = t.replace("{" + k + "}", str(dati[k]))
	return t

func on_richiesta(req: Dictionary) -> void:
	if not attivo:
		return
	if in_attesa:
		_entra()

func on_messaggio(t: String) -> void:
	if not attivo or in_attesa:
		return
	var st := corrente()
	if st.get("tipo", "") == "evento" and t.find(st["evento"]) >= 0:
		avanti()

func valida(req: Dictionary, x) -> String:
	## "" se la risposta va bene; altrimenti il motivo per cui il tutorial la ferma
	if not attivo:
		return ""
	var st := corrente()
	var tipo: String = st.get("tipo", "")
	if in_attesa:
		return ""
	if tipo == "ok" and req.get("tipo", "") == "piano":
		return "Prima leggi il riquadro della guida e premi «Avanti»."
	if tipo in ["piano", "risposta"] and req.get("tipo", "") == st.get("req", "piano"):
		var err: String = st["valida"].call(x)
		if err != "":
			return err
		if st.has("dopo"):
			st["dopo"].call()
		avanti()
	return ""

# ------------------------------------------------------------ le lezioni
func _vicino(k: String, evita: Array) -> String:
	var best := ""
	for x in g.vicini_di(u(), k):
		if x in evita:
			continue
		if g.tipo_radura(x) == "M":
			continue
		best = x
		break
	if best == "":
		for x in g.vicini_di(u(), k):
			if not (x in evita):
				return x
	return best

func _percorso() -> Array:
	## due passi di movimento senza montagne e senza tornare indietro
	var k0: String = u()["dove"]
	for a in g.vicini_di(u(), k0):
		if g.tipo_radura(a) == "M":
			continue
		for b in g.vicini_di(u(), a):
			if b != k0 and g.tipo_radura(b) != "M":
				return [a, b]
	var vs: Array = g.vicini_di(u(), k0)
	return [vs[0], g.vicini_di(u(), vs[0])[0]]

func _primo_mostro(tipo: String) -> String:
	for id in g.s["mostri"]:
		var m: Dictionary = g.s["mostri"][id]
		if m["tipo"] == tipo and not m["morto"]:
			return id
	return ""

func _costruisci() -> void:
	var L1 := "Lezione 1 di 8 · Il tuo eroe"
	var L2 := "Lezione 2 di 8 · Pianificare e muoversi"
	var L3 := "Lezione 3 di 8 · Mostri e nascondersi"
	var L4 := "Lezione 4 di 8 · Il combattimento"
	var L5 := "Lezione 5 di 8 · La magia"
	var L6 := "Lezione 6 di 8 · I tesori"
	var L7 := "Lezione 7 di 8 · I nativi"
	var L8 := "Lezione 8 di 8 · Come si vince"
	passi = [
		{"lez": L1, "tipo": "ok", "t": "Benvenuto nel Reame! Questo tutorial è una vera partita, preparata perché tu veda tutto il gioco: movimento, ricerca, mostri, combattimento, magia, tesori e nativi. Il riquadro della guida ti dice ogni volta cosa fare; se sbagli, il gioco ti ferma e spiega perché. Sei il PALADINO, un cavaliere sacro: buon combattente, con armatura e un po' di magia bianca."},
		{"lez": L1, "tipo": "ok", "t": "La TUA pedina è quella grande con il bordo rosso, sotto il segnalino rosso che fluttua al centro della mappa. La mappa è fatta di tessere esagonali; su ogni tessera ci sono RADURE numerate (i cerchi chiari) unite da sentieri. Ti muovi sempre da una radura all'altra lungo i sentieri. Trascina per spostare la vista, rotellina o due dita per lo zoom e la rotazione; «Centra» torna sulla tua pedina."},
		{"lez": L1, "tipo": "ok", "t": "A sinistra c'è la tua scheda. I SEGNALINI D'AZIONE sono la tua energia: azzurri per muoverti e schivare, arancioni per combattere, viola per la magia. La lettera è la forza (L leggera, M media, H pesante, T tremenda), il numero la velocità (più basso = più veloce), gli asterischi lo sforzo: quando ne usi troppi ti stanchi. A destra la CRONACA racconta ogni tiro di dado: leggila spesso."},
		{"lez": L2, "tipo": "ok", "t": "Ogni giorno ha quattro momenti. ALBA: decidi in anticipo tutte le attività della giornata. GIORNO: le esegui nell'ordine scritto, una per FASE. SERA: chi si trova con un mostro o un nemico combatte. MEZZANOTTE: si passa al giorno dopo. Le attività si scrivono nel pannello in basso, nelle caselle numerate: ogni casella è una fase."},
		{"lez": L2, "tipo": "piano", "t": "Ora pianifica il primo giorno. 1) Tocca sulla mappa la radura {A}, evidenziata dall'anello viola: è un passo di MOVIMENTO. 2) Poi tocca {B}, il passo successivo. 3) Infine tocca la scheda RICERCA nel pannello. 4) Premi «Conferma». Le altre fasi possono restare vuote.",
			"prepara": func():
				var via := _percorso()
				dati["kA"] = via[0]
				dati["kB"] = via[1]
				dati["A"] = nome(via[0])
				dati["B"] = nome(via[1]),
			"evid": func(): return [dati["kA"], dati["kB"]], "carta": "S",
			"valida": func(x):
				if x.size() < 3 or x[0].get("a") != "M" or x[0].get("dest") != dati["kA"] or x[1].get("a") != "M" or x[1].get("dest") != dati["kB"] or x[2].get("a") != "S":
					return "Il piano deve essere: Movimento a %s, Movimento a %s, Ricerca. Usa «Svuota» e riprova." % [dati["A"], dati["B"]]
				return "",
			"dopo": func(): g.s["dadi"] = [1, 1]},
		{"lez": L2, "tipo": "risposta", "req": "tabella", "attendi": "tabella", "t": "Il Paladino ha fatto i due passi ed è arrivato alla fase di RICERCA: scegli una tabella. CERCA trova soprattutto passaggi segreti e sentieri nascosti; SCRUTA indizi e segnalini; LOCALIZZA serve dopo aver trovato indizi. Si tirano due dadi e conta il più alto: 1 è il risultato migliore. Scegli SCRUTA.",
			"valida": func(x): return "" if x is Dictionary and x.get("tabella", "") == "scruta" else "Per questa lezione scegli la tabella SCRUTA."},
		{"lez": L2, "tipo": "ok", "t": "Hai ottenuto 1: «Scopri segnalini». Così si rivelano i segnalini della radura: siti con tesori, suoni dei mostri, avvisi. Inoltre, ogni volta che finisci il turno in una tessera, i suoi segnalini si scoprono: è così che si ESPLORA il Reame. Nello scenario 1 si vince proprio così: trovando con la ricerca i segnalini indicati dalle spedizioni."},
		{"lez": L3, "tipo": "ok", "attendi": "piano", "t": "È l'alba del secondo giorno, e nella tua radura è comparso un GOBLIN CON ASCIA! Dallo scenario 3 i mostri si risvegliano: quando finisci il turno in una tessera, i suoi segnalini possono evocarli. Un mostro BLOCCA chi è allo scoperto nella sua radura: il turno di quel personaggio finisce subito e la sera si combatte.",
			"prepara": func():
				g.s["scenario"] = 3
				var id := _primo_mostro("goblin_ascia")
				dati["gob"] = id
				g.s["mostri"][id]["dove"] = u()["dove"]
				g.s["mostri"][id]["lato"] = 0
				g.cambiato.emit()},
		{"lez": L3, "tipo": "piano", "t": "Per evitarlo puoi NASCONDERTI: tiri un dado e con 1-5 diventi invisibile. Chi è nascosto non viene bloccato né attaccato. Attenzione: all'inizio del turno ti riveli, e il goblin ti bloccherebbe già alla fine della prima fase. Quindi oggi tocca NASCONDERSI come PRIMA attività, poi RIPOSO, e premi «Conferma».",
			"carta": "H",
			"valida": func(x):
				if x.is_empty() or x[0].get("a") != "H":
					return "La prima attività deve essere NASCONDERSI: con il mostro già nella radura, devi sparire subito."
				for a in x:
					if a.get("a") == "M":
						return "Oggi non muoverti: resta nella radura con il goblin."
				return "",
			"dopo": func(): g.s["dadi"] = [2, 3]},
		{"lez": L3, "tipo": "ok", "attendi": "piano", "t": "Sei rimasto nascosto (il dado ha dato 3): il goblin non ti ha visto e non c'è stato combattimento. La regola d'oro: se un mostro è già vicino nasconditi PER PRIMO; altrimenti nasconditi PER ULTIMO, così la sera nessuno ti trova. Ora proviamo l'altra strada: affrontare il goblin."},
		{"lez": L4, "tipo": "piano", "t": "Oggi COMBATTI. Tocca ALLERTA (prepari l'arma) e poi RIPOSO, senza nasconderti, e premi «Conferma». Il goblin ti bloccherà alla fine della prima fase e stasera vi scontrerete. Il goblin è di peso Medio: per ucciderlo serve un colpo almeno Medio, come quello della tua mazza.",
			"carta": "A",
			"valida": func(x):
				for a in x:
					if a.get("a") in ["H", "M"]:
						return "Oggi non nasconderti e non muoverti: vogliamo affrontare il goblin."
				if x.is_empty() or x[0].get("a") != "A":
					return "Comincia con ALLERTA."
				return ""},
		{"lez": L4, "tipo": "ok", "attendi": ["adesca", "azione", "bersaglio"], "t": "È sera: inizia il combattimento. Ogni round passa per alcuni passi, elencati in cima alla finestra. ADESCARE: attiri i mostri su di te. AZIONE: puoi fuggire, preparare l'arma o lanciare un incantesimo. BERSAGLIO: scegli chi colpire. MISCHIA: decidi come attaccare e come schivare. Nei passi Adescare e Azione premi pure il pulsante principale; al passo BERSAGLIO scegli il goblin.",
			"prepara": func(): g.s["dadi"] = [3, 1]},
		{"lez": L4, "tipo": "risposta", "req": "bersaglio", "attendi": "bersaglio", "t": "Scegli come bersaglio il GOBLIN CON ASCIA.",
			"valida": func(x):
				var b = x.get("bersaglio", "") if x is Dictionary else x
				return "" if str(b) == dati["gob"] else "Scegli il goblin come bersaglio.",
			"dopo": func(): g.s["dadi"] = [3, 1]},
		{"lez": L4, "tipo": "risposta", "req": "mischia", "attendi": "mischia", "t": "Questa è la TAVOLA DEGLI SCONTRI. Il goblin è nella casella rossa della riga FENDENTE e della colonna CARICA: arriverà con un fendente, e la sua manovra è la carica. Per colpirlo tocca l'ottagono in alto sopra la sua colonna: AFFONDO (colpisce chi fa Carica). Per evitare il suo colpo tocca a destra la manovra della sua riga: SCHIVATA. Poi premi «Rivela le giocate».",
			"valida": func(x):
				if not (x is Dictionary) or not x.has("attacco") or x["attacco"].get("cerchio", "") != "thrust":
					return "Attacca con AFFONDO: è l'attacco che colpisce la Carica del goblin. Controlla anche di aver scelto un segnalino FIGHT."
				if not x.has("manovra") or x["manovra"].get("casella", "") != "dodge":
					return "Come manovra scegli SCHIVATA, sulla riga del fendente del goblin. Controlla di aver scelto un segnalino MOVE."
				return ""},
		{"lez": L4, "tipo": "ok", "attendi": "piano", "t": "Vittoria! Il tuo affondo ha colpito il goblin mentre caricava. Il suo fendente invece ti raggiunge solo se il suo attacco è più veloce della tua manovra (guarda nella Cronaca): in quel caso lo scudo o l'armatura ti hanno protetto. Uccidere i mostri dà FAMA e NOTORIETÀ, che contano per vincere. Regole da ricordare: un colpo più veloce della manovra avversaria va sempre a segno; se il colpo è forte almeno quanto il peso del bersaglio, lo uccide; le armature fermano i colpi ma possono rompersi. Dopo il combattimento paghi lo sforzo usato affaticando i segnalini: si recuperano con il RIPOSO."},
		{"lez": L5, "tipo": "ok", "t": "Ora la MAGIA (scenario 4). Un incantesimo richiede due cose: un segnalino MAGIA del tipo giusto (il Paladino ha segnalini di tipo I, la magia bianca) e il COLORE della magia. Il colore si ottiene trasformando un segnalino magico in un SEGNALINO DI COLORE con l'attività INCANTO, oppure trovandosi in un luogo che emana magia, come la Cappella (bianca).",
			"prepara": func():
				g.s["scenario"] = 4
				g.cambiato.emit()},
		{"lez": L5, "tipo": "piano", "t": "Pianifica due volte INCANTO e premi «Conferma». La prima volta il Paladino medita, la seconda trasforma un segnalino magico in un segnalino di colore.",
			"carta": "E",
			"valida": func(x):
				var n := 0
				for a in x:
					if a.get("a") == "E": n += 1
				return "" if n >= 2 else "Servono due attività INCANTO."},
		{"lez": L5, "tipo": "risposta", "req": "incanto", "attendi": "incanto", "t": "Scegli di incantare un segnalino MAGIA di tipo I: diventerà un segnalino di colore BIANCO.",
			"valida": func(x):
				var opz: Array = g.richiesta.get("dati", {}).get("opzioni", [])
				var k := int(x) if (x is int or x is float) else -1
				if k < 0 or k >= opz.size() or opz[k]["tipo"] != "chit" or u()["chits"][opz[k]["i"]]["magia"] != "I":
					return "Scegli un segnalino magico di tipo I (la magia bianca)."
				return ""},
		{"lez": L5, "tipo": "risposta", "req": "incantesimo_sera", "attendi": "incantesimo_sera", "t": "È sera. Ora hai un segnalino di colore bianco e un altro segnalino magico di tipo I: puoi lanciare GUARIGIONE COMPLETA, che rimette in forze tutti i segnalini affaticati o feriti. Sceglila. Gli incantesimi d'attacco, invece, si lanciano durante il combattimento come AZIONE.",
			"valida": func(x): return "" if x is Dictionary and x.get("inc", "") == "i_make_whole" else "Scegli GUARIGIONE COMPLETA."},
		{"lez": L6, "tipo": "ok", "attendi": "piano", "t": "I TESORI. Quando scopri un SITO (Tana, Bottino, Altare...) con la ricerca, puoi saccheggiarlo: nella RICERCA compare la scelta «Saccheggia», tiri un dado e prendi la carta di quel numero dalla cima della pila. Funziona allo stesso modo con gli oggetti abbandonati per terra: nella tua radura ce ne sono alcuni.",
			"prepara": func():
				var k: String = u()["dove"]
				g.s["mucchi"][k] = [{"id": "t_lucky_charm", "attivo": false, "allerta": false, "danno": 0}, {"id": "t_gripping_dust", "attivo": false, "allerta": false, "danno": 0}]
				g.cambiato.emit()},
		{"lez": L6, "tipo": "piano", "t": "Pianifica una RICERCA e premi «Conferma».", "carta": "S",
			"valida": func(x): return "" if not x.is_empty() and x[0].get("a") == "S" else "La prima attività deve essere RICERCA.",
			"dopo": func(): g.s["dadi"] = [1, 1]},
		{"lez": L6, "tipo": "risposta", "req": "tabella", "attendi": "tabella", "t": "Scegli «Saccheggia: Oggetti abbandonati».",
			"valida": func(x): return "" if x is Dictionary and x.get("tabella", "") == "saccheggia" else "Scegli il pulsante SACCHEGGIA."},
		{"lez": L6, "tipo": "ok", "t": "Hai trovato il PORTAFORTUNA: ora è nella tua scheda, sotto Equipaggiamento. Toccalo per leggerne l'effetto (qui: tiri un solo dado su tutte le tabelle, cioè niente più risultati peggiori). Ogni tesoro vale anche ORO, e i GRANDI TESORI (bordo rosso) danno Punti Vittoria. Con la Ricerca puoi anche leggere le RUNE dei siti per imparare nuovi incantesimi."},
		{"lez": L7, "tipo": "ok", "attendi": "piano", "t": "I NATIVI (scenario 5): gruppi di soldati, contadini, guardie e predoni che vivono nelle abitazioni. Nella tua radura è arrivato l'ORDINE, i cavalieri sacri: per il Paladino sono AMICHEVOLI. Nella scheda trovi i tuoi rapporti con ogni gruppo: alleato, amichevole, neutrale, ostile, nemico. Gli ostili e i nemici possono bloccarti e attaccarti come i mostri.",
			"prepara": func():
				g.s["scenario"] = 5
				g.nativi.compari("order", u()["dove"])
				g.cambiato.emit()},
		{"lez": L7, "tipo": "piano", "t": "Pianifica COMMERCIO e premi «Conferma».", "carta": "T",
			"valida": func(x): return "" if not x.is_empty() and x[0].get("a") == "T" else "La prima attività deve essere COMMERCIO."},
		{"lez": L7, "tipo": "risposta", "req": "commercio", "attendi": "commercio", "t": "Vendere non richiede tiri: spunta il PORTAFORTUNA e premi «Vendi all'Ordine gli oggetti scelti». Per COMPRARE invece tiri sulla Tabella degli incontri nella colonna del tuo rapporto: il risultato moltiplica il prezzo (o il gruppo rifiuta, o si offende). Con INGAGGIO puoi pagare un gruppo perché ti segua e combatta con te per 14 giorni.",
			"valida": func(x):
				if x is Dictionary and x.get("tipo", "") == "vendi":
					return ""
				return "Per questa lezione VENDI un oggetto all'Ordine."},
		{"lez": L8, "tipo": "ok", "t": "Hai visto tutto il gioco! COME SI VINCE: nello scenario 1 completando per primo le quattro spedizioni; nello scenario 2 restando l'ultimo vivo; negli scenari 3 e 4 arrivando a 10 PUNTI VITTORIA (missioni, siti scoperti, 1 punto ogni 10 Fama e 20 Notorietà, grandi tesori, incantesimi imparati); nello scenario 5 a 12 punti, contando anche 1 punto ogni 30 monete d'oro. Nello scenario 6 scegli tu all'inizio i tuoi traguardi."},
		{"lez": L8, "tipo": "ok", "t": "Ultimi consigli: inizia dallo scenario 1 e passa al successivo solo quando ti senti sicuro; nasconditi sempre per ultimo; scappa dai mostri Tremendi finché non hai armi e armature adatte; riposa quando sei stanco o ferito; se non sai cosa fare, il pulsante «Piano consigliato» riempie la giornata per te. Premi «Avanti» per tornare al menu e iniziare la tua prima partita. Buon viaggio nel Reame!"},
	]
