## Cavalli rotondi della seconda edizione (Horse Trading chart, p.78).
## I due cavalli speciali T3 e L2 non vanno nelle scorte native.
class_name CavalliClassici
extends RefCounted

const SPEC := {
 "pony_l2": {"nome":"Pony L2/L4","tipo":"pony","galoppo":["L",2],"passo":["L",4],"prezzo":16,"vulnerabilita":"M","tesoro":true},
 "pony_m2": {"nome":"Pony M2/M5","tipo":"pony","galoppo":["M",2],"passo":["M",5],"prezzo":16,"vulnerabilita":"M"},
 "pony_m3m4": {"nome":"Pony M3/M4","tipo":"pony","galoppo":["M",3],"passo":["M",4],"prezzo":15,"vulnerabilita":"M"},
 "pony_m3m5": {"nome":"Pony M3/M5","tipo":"pony","galoppo":["M",3],"passo":["M",5],"prezzo":14,"vulnerabilita":"M"},
 "pony_l3m4": {"nome":"Pony L3/M4","tipo":"pony","galoppo":["L",3],"passo":["M",4],"prezzo":14,"vulnerabilita":"M"},
 "pony_l3m5": {"nome":"Pony L3/M5","tipo":"pony","galoppo":["L",3],"passo":["M",5],"prezzo":12,"vulnerabilita":"M"},
 "pony_m4m5": {"nome":"Pony M4/M5","tipo":"pony","galoppo":["M",4],"passo":["M",5],"prezzo":12,"vulnerabilita":"M"},
 "lavoro_h6t8": {"nome":"Cavallo da lavoro H6/T8","tipo":"lavoro","galoppo":["H",6],"passo":["T",8],"prezzo":12,"vulnerabilita":"H"},
 "lavoro_h6h7": {"nome":"Cavallo da lavoro H6/H7","tipo":"lavoro","galoppo":["H",6],"passo":["H",7],"prezzo":11,"vulnerabilita":"H"},
 "lavoro_m5h7": {"nome":"Cavallo da lavoro M5/H7","tipo":"lavoro","galoppo":["M",5],"passo":["H",7],"prezzo":11,"vulnerabilita":"H"},
 "lavoro_m5m6": {"nome":"Cavallo da lavoro M5/M6","tipo":"lavoro","galoppo":["M",5],"passo":["M",6],"prezzo":10,"vulnerabilita":"H"},
 "lavoro_l5m6": {"nome":"Cavallo da lavoro L5/M6","tipo":"lavoro","galoppo":["L",5],"passo":["M",6],"prezzo":9,"vulnerabilita":"H"},
 "lavoro_l4l5": {"nome":"Cavallo da lavoro L4/L5","tipo":"lavoro","galoppo":["L",4],"passo":["L",5],"prezzo":8,"vulnerabilita":"H"},
 "guerra_t3": {"nome":"Destriero T3/T5","tipo":"guerra","galoppo":["T",3],"passo":["T",5],"prezzo":25,"vulnerabilita":"T","tesoro":true},
 "guerra_t5": {"nome":"Destriero T5/T7","tipo":"guerra","galoppo":["T",5],"passo":["T",7],"prezzo":22,"vulnerabilita":"T"},
 "guerra_h4t7": {"nome":"Destriero H4/T7","tipo":"guerra","galoppo":["H",4],"passo":["T",7],"prezzo":20,"vulnerabilita":"T"},
 "guerra_h4h6": {"nome":"Destriero H4/H6","tipo":"guerra","galoppo":["H",4],"passo":["H",6],"prezzo":18,"vulnerabilita":"T"}
}

const STALLE := {
 "bashkars":["pony_m2","pony_m3m4","pony_m3m5","pony_l3m4","pony_l3m5","pony_m4m5"],
 "rogues":["lavoro_h6t8","lavoro_h6h7","lavoro_m5h7","lavoro_m5m6","lavoro_l5m6","lavoro_l4l5"],
 "order":["guerra_t5","guerra_h4t7","guerra_h4h6"]
}

static func definizione(id: String) -> Dictionary:
 return SPEC.get(id, {})

static func nuovo(id: String) -> Dictionary:
 if not SPEC.has(id):
  return {}
 return {"id":id,"attivo":false,"morto":false,"galoppo_usato":false}

static func attivo(p: Dictionary) -> Dictionary:
 for c in p.get("cavalli", []):
  if c.get("attivo", false) and not c.get("morto", false):
   return c
 return {}

static func forza(c: Dictionary, galoppo := false) -> int:
 var d: Dictionary = definizione(str(c.get("id", "")))
 if d.is_empty():
  return -1
 return Dati.peso_i(str(d["galoppo" if galoppo else "passo"][0]))

static func tempo(c: Dictionary, galoppo := false) -> int:
 var d: Dictionary = definizione(str(c.get("id", "")))
 return int(d["galoppo" if galoppo else "passo"][1]) if not d.is_empty() else 99

static func tipo(c: Dictionary) -> String:
 return str(definizione(str(c.get("id", ""))).get("tipo", ""))

static func cavalcabile(p: Dictionary, c: Dictionary, carico: int, vulnerabilita: int, in_grotta: bool) -> bool:
 if in_grotta or c.get("morto", false):
  return false
 var peso_cavaliere := forza(c)
 if peso_cavaliere < vulnerabilita:
  return false
 if carico <= peso_cavaliere:
  return true
 # Equipaggiamento piu pesante del cavallo montato puo viaggiare su un pack horse.
 for altro in p.get("cavalli", []):
  if altro["id"] != c["id"] and not altro.get("morto", false) and forza(altro) >= carico:
   return true
 return false

static func portata(p: Dictionary, carico_personale: int) -> int:
 # Cavalli da soma inattivi possono portare gli oggetti senza cumulare pesi.
 var massimo := carico_personale
 for c in p.get("cavalli", []):
  if not c.get("morto", false):
   massimo = maxi(massimo, forza(c))
 return massimo

static func attiva(p: Dictionary, id: String, carico: int, vulnerabilita: int, in_grotta: bool) -> bool:
 for c in p.get("cavalli", []):
  if c["id"] != id or c.get("morto", false):
   continue
  if c.get("attivo", false):
   c["attivo"] = false
   return true
  if not cavalcabile(p,c,carico,vulnerabilita,in_grotta):
   return false
  for altro in p["cavalli"]:
   altro["attivo"] = false
  c["attivo"] = true
  return true
 return false

static func extra_fasi(p: Dictionary, in_grotta: bool, normali: int) -> int:
 var c := attivo(p)
 if in_grotta or c.is_empty():
  return 0
 match tipo(c):
  "lavoro": return 1
  "pony": return normali
 return 0
