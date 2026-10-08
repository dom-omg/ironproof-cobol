#!/usr/bin/env python3
"""Garde : les chiffres du paper doivent survivre a une re-execution du benchmark.

POURQUOI CE GARDE EXISTE (incident 2026-08-02)
-----------------------------------------------
Le paper citait "586/586 = 100%, 1759 hors scope" et le guide de
reproductibilite attendait "537/537 = 100%, 1808 hors scope". Les deux etaient
internement coherents et se contredisaient : le README avait deux revisions de
retard (537 -> 571 -> 586) et rien ne l'a signale, parce qu'un document ne
pourrit pas bruyamment -- il reste vert au-dessus d'un code qui a bouge.

Pire, les deux comptabilites reversaient 67 programmes (dont 7 REFUTED : de
vrais contre-exemples Z3 sur notre propre generateur) dans le seau
"hors scope". Un taux dont le denominateur exclut nos propres echecs ne peut
pas descendre -- et un verdict qui ne peut pas etre rouge ne vaut rien en vert.

CE QUE LE GARDE FAIT
--------------------
Il RE-EXECUTE le pipeline sur le corpus, recalcule les cinq etats, et verifie
que chaque chiffre publie dans le .tex correspond. Il ne lit aucun resultat
mis en cache : un chiffre confronte a un log est confronte a l'instant ou le
log a ete ecrit, pas a l'etat du code.

PYTHONHASHSEED
--------------
Le benchmark N'ETAIT PAS reproductible sans seed epingle : trois processus a seed
libre ont donne 586, 587 et 588 programmes prouves, et 6 ou 7 refutations. Le tri
des unions d'ensembles de l'encodeur a retire la cause ; le seed reste epingle par
precaution. Avec PYTHONHASHSEED=0, trois processus donnent un resultat bit-identique.
Le garde REFUSE de conclure si le seed n'est pas fixe : un garde qui mesure
avec un instrument instable rend un verdict qu'on ne peut pas croire, et
"je n'ai pas pu mesurer" doit se lire autrement que "tout va bien".

TOLERANCE
---------
ZERO, sur tous les seaux. Avec le seed epingle il n'y a plus de bruit a
absorber, donc toute derive est un vrai changement.

CE QU'IL NE PRETEND PAS (A4)
----------------------------
Il verifie la CORRESPONDANCE entre le paper et le code, pas la JUSTESSE du
code. Un pipeline faux mais stable passe. Il ne verifie pas non plus que le
PDF a ete recompile depuis le .tex.

USAGE
    python3 check_paper_numbers.py            # re-execute et confronte
    python3 check_paper_numbers.py --self-test
"""
import argparse
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
TEX = os.path.join(HERE, "ironproof_cobol.tex")
CORPUS = os.path.join(REPO, "benchmark", "cobol_programs")

# Avec PYTHONHASHSEED epingle, aucune derive n'est du bruit.
TOLERANCE = {}
REQUIRED_SEED = "0"


def run_pipeline(corpus_dir):
    """Re-execute le pipeline et retourne les cinq etats reels.

    La classification vit dans papers/classify.py, SEULE definition partagee par
    tous les scripts qui produisent un chiffre du papier (2026-09-30 : quatre copies
    divergeaient en silence). Le perimetre se decide cote COBOL ; voir son docstring.
    """
    sys.path.insert(0, HERE)
    from classify import counts, iter_corpus
    return counts(list(iter_corpus(corpus_dir)))


# Chaque chiffre publie, avec la chaine EXACTE qui le porte dans le .tex.
# Si la chaine disparait, le garde ne peut plus confronter et le dit -- il ne
# se tait pas. Un controle qui n'a rien recu n'est pas un controle qui a
# regarde sans rien trouver.
CLAIM_ANCHORS = {
    "proved":              (606,  r"\textbf{606 (77.5\%)} are proved equivalent"),
    "refuted":             (0,    r"101 are only partially verified, none is refuted"),
    "partial":             (101,  r"101 are only partially verified"),
    "pipeline_failure":    (75,   r"75 fail inside our own pipeline"),
    "checking_path":       (782,  r"Z3-encodable output, and 782 do"),
    "no_encodable_output": (1563, r"the remaining 1{,}563 yield no encodable output"),
    "total":               (2345, r"The parser accepts all 2{,}345 programs"),
}


def claimed_numbers(tex_text):
    """Chiffres que le paper publie, ou None si l'ancre a disparu."""
    return {key: (value if anchor in tex_text else None)
            for key, (value, anchor) in CLAIM_ANCHORS.items()}


def compare(actual, claimed):
    problems = []
    for key, want in claimed.items():
        if want is None:
            problems.append(
                f"[{key}] le paper ne publie plus ce chiffre sous la forme "
                f"attendue -- le garde ne peut pas le confronter")
            continue
        got = actual[key]
        tol = TOLERANCE.get(key, 0)
        if abs(got - want) > tol:
            problems.append(
                f"[{key}] paper={want}  run={got}"
                + (f"  (tolerance {tol})" if tol else ""))
    return problems


def self_test():
    """Le garde doit tirer sur un ecart, et rester muet sur l'etat sain."""
    # L'etat sain EST ce que le paper publie : derive des ancres, jamais recopie
    # (une copie en dur ici a garde les chiffres d'aout apres leur remplacement).
    published = {k: v for k, (v, _) in CLAIM_ANCHORS.items()}
    base = dict(published)

    cases = [
        ("etat sain -> muet", dict(base), dict(published), 0),
        ("derive de 1 sur proved -> tire (tolerance ZERO)",
         dict(base, proved=588), dict(published), 1),
        ("le compte de REFUTED bouge -> tire",
         dict(base, refuted=base["refuted"] + 1), dict(published), 1),
        ("les echecs de pipeline sont reverses en hors-scope -> tire",
         dict(base, pipeline_failure=0,
              no_encodable_output=base["no_encodable_output"] + base["pipeline_failure"]),
         dict(published), 1),
        ("le paper ne publie plus le chiffre -> tire, il ne se tait pas",
         dict(base), dict(published, proved=None), 1),
    ]

    passed = 0
    for label, actual, claimed, expect in cases:
        got = len(compare(actual, claimed))
        ok = (got > 0) == (expect > 0)
        passed += ok
        print(f"  [{'OK ' if ok else 'FAIL'}] {label} (divergences={got})")

    print(f"\n  self-test : {passed}/{len(cases)}")
    return 0 if passed == len(cases) else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        print("SELF-TEST check_paper_numbers")
        return self_test()

    seed = os.environ.get("PYTHONHASHSEED")
    if seed != REQUIRED_SEED:
        print(f"REFUS DE CONCLURE -- PYTHONHASHSEED={seed!r}, "
              f"attendu {REQUIRED_SEED!r}")
        print("  Sans seed epingle le benchmark varie de +/-1 programme entre")
        print("  processus. Un verdict mesure sur un instrument instable ne")
        print("  vaut rien. Relancer :")
        print(f"    PYTHONHASHSEED={REQUIRED_SEED} "
              f"venv/bin/python3 papers/check_paper_numbers.py")
        return 2

    if not os.path.isdir(CORPUS):
        print(f"CORPUS ABSENT : {CORPUS}")
        print("  Le garde ne peut pas MESURER -- ce n'est pas un succes.")
        return 2

    print(f"Re-execution du pipeline sur {CORPUS} ...")
    actual = run_pipeline(CORPUS)
    print(f"  proved={actual['proved']} refuted={actual['refuted']} "
          f"partial={actual['partial']} "
          f"pipeline_failure={actual['pipeline_failure']} "
          f"no_encodable_output={actual['no_encodable_output']} "
          f"checking_path={actual['checking_path']} "
          f"total={actual['total']}")

    with open(TEX, encoding="utf-8") as fh:
        claimed = claimed_numbers(fh.read())
    problems = compare(actual, claimed)

    if problems:
        print(f"\nLE PAPER NE CORRESPOND PLUS AU CODE ({len(problems)})")
        for p in problems:
            print(f"  {p}")
        return 1

    print("\nOK -- les chiffres publies correspondent a une execution reelle.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
