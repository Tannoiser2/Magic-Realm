## Punteggio Magic Realm originale 2a edizione, sezione 4.7.
## E' diverso dal punteggio Super: penalita x3, arrotondamento
## sfavorevole e bonus moltiplicato per i punti assegnati.
class_name PunteggioClassico
extends RefCounted

const CATEGORIE := ["grandi", "inc", "fama", "noto", "oro"]
const FATTORI := {"grandi": 1, "inc": 2, "fama": 10, "noto": 20, "oro": 30}

static func valida_assegnazione(punti: Dictionary, usa_magia := true) -> bool:
	var totale := 0
	for c in CATEGORIE:
		var n = punti.get(c, 0)
		if not (n is int) or n < 0 or n > 5:
			return false
		if c == "inc" and not usa_magia and n != 0:
			return false
		totale += n
	return totale == 5

## I valori sono il possesso finale del personaggio, PRIMA della rettifica
## oro iniziale; lo 0 in credito_oro_iniziale permette test su valori netti.
static func calcola(punti: Dictionary, valori: Dictionary, credito_oro_iniziale: int = 0, usa_magia := true) -> Dictionary:
	if not valida_assegnazione(punti, usa_magia):
		push_error("Magic Realm classico: assegnazione PV non valida")
		return {}
	var categorie := {}
	var totale := 0
	for c in CATEGORIE:
		var fattore: int = FATTORI[c]
		var assegnati: int = punti[c]
		var valore: int = int(valori.get(c, 0))
		if c == "oro":
			valore -= credito_oro_iniziale
		var richiesti := assegnati * fattore
		var differenza := valore - richiesti
		if differenza < 0:
			differenza *= 3
		# Floor anche sotto zero (a sfavore del giocatore).
		var base := floori(float(differenza) / float(fattore))
		var bonus := base * assegnati
		categorie[c] = {
			"valore": valore, "richiesti": richiesti,
			"base": base, "bonus": bonus, "totale": base + bonus
		}
		totale += base + bonus
	return {"totale": totale, "categorie": categorie, "vittoria": totale >= 0}
