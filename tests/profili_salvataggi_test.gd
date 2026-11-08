## Run: godot --headless --path . --script res://tests/profili_salvataggi_test.gd
## Compatibility smoke test: new Super profiles and simulated pre-profile save.
extends SceneTree

func _init() -> void:
    for sc in [1, 3, 6]:
        var g := Reame.new()
        var profilo := ProfiliRegole.super_scenario(sc)
        assert(g.nuova_con_profilo(profilo, "amazzone", [], 12345))
        assert(g.s["profilo_regole"]["id"] == "super_%d" % sc)
        assert(g.usa_regola("mostri") == (sc >= 3))
        var saved := g.esporta()
        saved["s"].erase("profilo_regole")
        saved["s"]["versione"] = 1
        var restored := Reame.new()
        restored.importa(saved)
        assert(restored.profilo_regole()["id"] == "super_%d" % sc)
        assert(restored.s["giorno"] == 1)
    var incomplete := Reame.new()
    assert(not incomplete.nuova_con_profilo(ProfiliRegole.classico_completo(), "amazzone", [], 1))
    print("PASS: profile and legacy-save smoke checks")
    quit()
