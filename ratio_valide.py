#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Un ratio qui REFUSE de se construire sans son etat de validite.

⚠️ CE N'EST PAS UN CAS, C'EST UNE PRIMITIVE -- et on ne l'a compris qu'a la deuxieme
occurrence, a un jour d'intervalle, dans deux compteurs successifs :

  1. `_denominateur_incomplet` imprimait « complet » quand le balayage source trouvait
     MOINS que le parseur (`max(0, source - parse)`). Mesure : nist_045_ic202a,
     source=0, parse=6.
  2. `couverture_parse`, ecrit POUR fermer cette classe, rendait `COMPLET` sur du vide :
     `verbes == 0` donnait `manquants == 0`. Trouve par une question de relecture, pas par le
     banc que je venais d'ecrire.

La forme fautive est toujours la meme : un ratio se construit a partir de deux nombres,
et **rien dans le type ne l'oblige a dire s'il est mesurable**. Quand il ne l'est pas,
il rend la valeur la plus flatteuse. Ici c'est impossible : `Ratio` n'a pas de
constructeur qui accepte un denominateur nul ou une incoherence en silence.

TROIS ETATS, jamais deux -- « rien recu » n'est pas « rien trouve ».

    python3 ratio_valide.py --self-test
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Optional

MESURE = "MESURE"           # numerateur et denominateur ont un sens
NON_MESURABLE = "NON_MESURABLE"   # denominateur nul, absent, ou incoherent


@dataclass(frozen=True)
class Ratio:
    """Ne s'instancie que par `mesurer()` ou `non_mesurable()`."""
    etat: str
    numerateur: Optional[int]
    denominateur: Optional[int]
    raison: str = ""

    @property
    def valide(self) -> bool:
        return self.etat == MESURE

    @property
    def manquants(self) -> Optional[int]:
        """`None` quand il n'y a rien a soustraire — JAMAIS 0, qui se lit « complet »."""
        if not self.valide:
            return None
        return self.denominateur - self.numerateur

    @property
    def complet(self) -> Optional[bool]:
        return None if not self.valide else self.manquants == 0

    def texte(self) -> str:
        if not self.valide:
            return "non mesurable : %s" % (self.raison or "raison non donnee")
        return "%d/%d" % (self.numerateur, self.denominateur)

    def dict(self) -> dict:
        return {"etat": self.etat, "numerateur": self.numerateur,
                "denominateur": self.denominateur, "valide": self.valide,
                "manquants": self.manquants, "complet": self.complet,
                "raison": self.raison, "texte": self.texte()}


def non_mesurable(raison: str, numerateur=None, denominateur=None) -> Ratio:
    if not raison or len(raison.strip()) < 8:
        raise ValueError("un ratio non mesurable DOIT nommer ce qui l'empeche "
                         "-- sinon il est indiscernable d'un oubli")
    return Ratio(NON_MESURABLE, numerateur, denominateur, raison.strip())


def mesurer(numerateur: int, denominateur: int, quoi: str = "") -> Ratio:
    """Construit le ratio, ou refuse. Les deux refus sont ceux qu'on a VECUS."""
    if denominateur is None or numerateur is None:
        return non_mesurable("numerateur ou denominateur absent%s"
                             % (" (%s)" % quoi if quoi else ""), numerateur, denominateur)
    if denominateur == 0:
        # Occurrence 2 : `verbes == 0` -> `manquants == 0` -> COMPLET sur du vide.
        return non_mesurable("denominateur NUL%s : il n'y a rien contre quoi mesurer, "
                             "et une absence de mesure n'est pas une couverture complete"
                             % (" (%s)" % quoi if quoi else ""), numerateur, denominateur)
    if numerateur > denominateur:
        # Occurrence 1 : le balayage source trouve MOINS que le parseur -> il est casse.
        return non_mesurable("numerateur %d > denominateur %d%s : le balayage trouve "
                             "MOINS que ce qu'il mesure, donc il est casse -- rien n'est "
                             "conclu" % (numerateur, denominateur,
                                         " (%s)" % quoi if quoi else ""),
                             numerateur, denominateur)
    if numerateur < 0 or denominateur < 0:
        return non_mesurable("valeur negative -- entree incoherente", numerateur, denominateur)
    return Ratio(MESURE, numerateur, denominateur)


def _self_test() -> int:
    ok = fail = 0

    def eq(nom, got, want):
        nonlocal ok, fail
        if got == want:
            ok += 1
        else:
            fail += 1
            print("  FAIL %s: %r != %r" % (nom, got, want))

    # --- le cas sain : le ratio se construit et mesure -----------------------
    r = mesurer(7, 12)
    eq("sain valide", r.valide, True)
    eq("sain manquants", r.manquants, 5)
    eq("sain complet", r.complet, False)
    eq("sain texte", r.texte(), "7/12")
    r = mesurer(3, 3)
    eq("egal complet", r.complet, True)
    eq("egal manquants", r.manquants, 0)

    # --- occurrence 2 : denominateur nul -------------------------------------
    r = mesurer(0, 0, "verbes COBOL")
    eq("nul non valide", r.valide, False)
    eq("nul manquants=None pas 0", r.manquants, None)
    eq("nul complet=None pas True", r.complet, None)
    eq("nul nomme sa cause", "NUL" in r.raison, True)

    # --- occurrence 1 : numerateur > denominateur ----------------------------
    r = mesurer(6, 0)
    eq("6/0 non valide", r.valide, False)
    r = mesurer(6, 2, "scan source")
    eq("num>den non valide", r.valide, False)
    eq("num>den dit casse", "casse" in r.raison, True)

    # --- absents --------------------------------------------------------------
    eq("None non valide", mesurer(None, 5).valide, False)
    eq("den None non valide", mesurer(5, None).valide, False)

    # --- un non_mesurable DOIT nommer sa raison -------------------------------
    try:
        non_mesurable("")
        fail += 1
        print("  FAIL: raison vide acceptee")
    except ValueError:
        ok += 1
    try:
        non_mesurable("court")
        fail += 1
        print("  FAIL: raison trop courte acceptee")
    except ValueError:
        ok += 1

    # --- le dict porte l'etat, toujours ---------------------------------------
    eq("dict sain", mesurer(1, 2).dict()["valide"], True)
    eq("dict nul", mesurer(0, 0).dict()["valide"], False)
    eq("dict nul texte", mesurer(0, 0).dict()["texte"].startswith("non mesurable"), True)

    print("\n  ratio_valide --self-test %d/%d" % (ok, ok + fail))
    return 0 if fail == 0 else 1


if __name__ == "__main__":
    import sys
    sys.exit(_self_test() if "--self-test" in sys.argv else 0)
