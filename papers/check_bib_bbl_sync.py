#!/usr/bin/env python3
"""Garde : le .bbl rendu doit dire la meme chose que le .bib source.

POURQUOI CE GARDE EXISTE (incident 2026-08-02)
-----------------------------------------------
Le .bbl est genere par bibtex a partir du .bib, mais il est COMMITE. Quand
quelqu'un edite le .bib sans relancer bibtex, le PDF continue de rendre
l'ancienne reference -- silencieusement. C'est ce qui est arrive a
`reuters2017cobol` : le .bib disait {Reuters} / "Aging Computer Language
COBOL..." pendant que le PDF affichait "Gillian Tett, Thomson Reuters",
une reference qui n'existe nulle part dans le .bib.

Une reference fantome dans un PDF soumis = desk-reject dans les venues qui
scannent les references hallucinees. Le defaut est invisible en relisant le
.bib OU le .bbl separement : il n'apparait qu'en les comparant.

CE QUE LE GARDE VERIFIE
-----------------------
Pour chaque cle presente dans les deux fichiers :
  1. Les noms de famille des auteurs du .bbl sont tous presents dans le .bib.
  2. Un fragment significatif du titre du .bib se retrouve dans le .bbl.

CE QU'IL NE PRETEND PAS (A4)
----------------------------
Il ne verifie pas que la reference est VRAIE (qu'elle existe dans le monde) --
seulement que les deux fichiers s'accordent. Une reference fausse mais
coherente des deux cotes passe. Il ne verifie pas non plus l'ordre des
entrees ni la numerotation : relancer bibtex reste la seule facon correcte de
regenerer le .bbl.

USAGE
    python3 check_bib_bbl_sync.py [--paper ironproof_cobol]
    python3 check_bib_bbl_sync.py --self-test
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))

# Mots trop generiques pour servir de preuve qu'un titre correspond.
_STOP = {
    "the", "a", "an", "of", "for", "and", "in", "on", "to", "with", "by",
    "study", "large", "code", "from", "while", "using", "towards", "toward",
}

# Macros d'accent LaTeX : \^e \`e \'e \"o \~n \=a \.z \c{c} \v{s} \u{a} \H{o}
# Sans ce nettoyage, "Reb\^elo" se decoupe en deux tokens et le dernier ("\^e")
# est pris pour un nom de famille -> le garde accuse a tort. Faux positif
# trouve au premier run sur le vrai paper (2026-08-02).
_ACCENT = re.compile(r"\\[`'^\"~=.uvHcbdrt]\s*\{?([A-Za-z])\}?")


def _strip_latex(s):
    """Reduit un nom LaTeX a ses lettres : Reb\\^elo et Reb{\\^e}lo -> Rebelo."""
    s = _ACCENT.sub(r"\1", s)
    s = re.sub(r"\\[a-zA-Z]+", "", s)    # \ss, \aa, commandes residuelles
    # Les accolades se retirent SANS espace : "Reb{e}lo" doit donner "Rebelo",
    # pas "Reb e lo" -- sinon le mot se scinde et le garde accuse a tort.
    s = re.sub(r"[{}\\]", "", s)
    return s.replace("~", " ")


def parse_bib(text):
    """Extrait {cle: (surnames, title)} du .bib."""
    out = {}
    for m in re.finditer(r"@\w+\{([^,]+),(.*?)\n\}", text, re.S):
        key, body = m.group(1).strip(), m.group(2)

        am = re.search(r"author\s*=\s*[{\"](.*?)[}\"]\s*,\s*\n", body, re.S)
        surnames = set()
        if am:
            raw = _strip_latex(am.group(1))
            for person in re.split(r"\s+and\s+", raw):
                person = person.strip().rstrip(",")
                if not person:
                    continue
                # "Surname, Given" -> Surname ; sinon dernier mot.
                surname = (person.split(",")[0] if "," in person
                           else person.split()[-1])
                surname = surname.strip()
                if surname:
                    surnames.add(surname.lower())
                    # Particule nobiliaire ("de Moura", "van Dijk", "de la
                    # Cruz") : le .bib en format "Surname, Given" garde tout le
                    # nom de famille ("de moura"), mais parse_bbl ne conserve
                    # que le DERNIER mot du nom rendu ("moura"). Sans ce token,
                    # un auteur correct est accuse de fantome. Faux positif
                    # trouve sur demoura2008z3 au 1er run ou il a ete cite
                    # (2026-08-03). On enregistre aussi le dernier mot.
                    surnames.add(surname.split()[-1].lower())

        tm = re.search(r"title\s*=\s*\{+(.*?)\}+\s*,\s*\n", body, re.S)
        title = re.sub(r"\s+", " ", tm.group(1)).strip() if tm else ""
        out[key] = (surnames, title)
    return out


def parse_bbl(text):
    """Extrait {cle: (surnames, blob)} du .bbl."""
    out = {}
    chunks = re.split(r"\\bibitem", text)
    for chunk in chunks[1:]:
        km = re.search(r"\{([^}]+)\}", chunk[chunk.find("]") + 1:]
                       if "]" in chunk else chunk)
        if not km:
            continue
        key = km.group(1).strip()

        surnames = set()
        # Un nom peut contenir des accolades imbriquees ({\^e}). Un .*?
        # non-greedy coupe au premier '}' et tronque "Reb{\^e}lo" en "Rebe" --
        # le garde accusait alors a tort. On autorise un niveau d'imbrication.
        for pm in re.finditer(
                r"\\bibinfo\{person\}\{((?:[^{}]|\{[^{}]*\})*)\}",
                chunk, re.S):
            person = _strip_latex(pm.group(1))
            person = re.sub(r"\s+", " ", person).strip()
            if person:
                surnames.add(person.split()[-1].lower())

        blob = re.sub(r"[~{}\\]", " ", chunk)
        blob = re.sub(r"\s+", " ", blob).lower()
        out[key] = (surnames, blob)
    return out


def significant_words(title):
    words = re.findall(r"[a-z]{4,}", title.lower())
    return [w for w in words if w not in _STOP]


def check(bib_path, bbl_path):
    """Retourne la liste des divergences (vide = OK)."""
    if not os.path.exists(bib_path):
        return [f"FICHIER ABSENT : {bib_path}"]
    if not os.path.exists(bbl_path):
        return [f"FICHIER ABSENT : {bbl_path}"]

    bib = parse_bib(open(bib_path, encoding="utf-8", errors="replace").read())
    bbl = parse_bbl(open(bbl_path, encoding="utf-8", errors="replace").read())

    problems = []
    shared = sorted(set(bib) & set(bbl))
    if not shared:
        # Un garde qui n'a rien recu doit le dire autrement qu'un garde
        # qui a regarde et n'a rien trouve.
        return ["AUCUNE cle commune entre .bib et .bbl -- garde inoperant"]

    for key in shared:
        bib_names, bib_title = bib[key]
        bbl_names, bbl_blob = bbl[key]

        ghost = sorted(n for n in bbl_names if n not in bib_names)
        if ghost:
            problems.append(
                f"[{key}] auteur(s) dans le .bbl RENDU mais absent(s) du .bib "
                f"source : {', '.join(ghost)}")

        words = significant_words(bib_title)
        if words and not any(w in bbl_blob for w in words):
            problems.append(
                f"[{key}] le titre du .bib ne se retrouve pas dans le .bbl : "
                f"\"{bib_title[:60]}...\"")

    return problems


def self_test():
    """Teste le garde dans les DEUX sens : il doit tirer, et rester muet."""
    import tempfile

    bib_ok = """@misc{x2017,
  author = {Irrera, Anna},
  title  = {{Banks scramble to fix old systems}},
  year   = {2017}
}
"""
    bbl_ok = r"""\bibitem[Irrera(2017)]%
        {x2017}
\bibfield{author}{\bibinfo{person}{Anna Irrera}.}
\newblock \bibinfo{title}{{Banks scramble to fix old systems}}.
"""
    bbl_ghost = r"""\bibitem[Tett(2017)]%
        {x2017}
\bibfield{author}{\bibinfo{person}{Gillian Tett}.}
\newblock \bibinfo{title}{{Banks scramble to fix old systems}}.
"""
    bbl_wrong_title = r"""\bibitem[Irrera(2017)]%
        {x2017}
\bibfield{author}{\bibinfo{person}{Anna Irrera}.}
\newblock \bibinfo{title}{{The Hidden World of Legacy IT}}.
"""

    # Le faux positif du premier run : accents LaTeX. L'etat est SAIN,
    # le garde doit rester muet -- sinon il accuse a tort.
    bib_accent = """@inproceedings{y2012,
  author = {Lahiri, Shuvendu and Reb\\^elo, Henrique},
  title  = {{SymDiff: A Language Agnostic Semantic Diff Tool}},
  year   = {2012}
}
"""
    bbl_accent = r"""\bibitem[Lahiri and Reb{\^e}lo(2012)]%
        {y2012}
\bibfield{author}{\bibinfo{person}{Shuvendu Lahiri}, {and}
  \bibinfo{person}{Henrique Reb{\^e}lo}.}
\newblock \bibinfo{title}{{SymDiff: A Language Agnostic Semantic Diff Tool}}.
"""

    # Particule nobiliaire : .bib en "Surname, Given" ("de Moura, Leonardo"),
    # .bbl rendu en "Leonardo de Moura". L'etat est SAIN, le garde doit rester
    # muet -- sinon il accuse un auteur correct (faux positif du 2026-08-03).
    bib_particle = """@inproceedings{z2008,
  author = {de Moura, Leonardo and Bj{\\o}rner, Nikolaj},
  title  = {{Z3: An Efficient SMT Solver}},
  year   = {2008}
}
"""
    bbl_particle = r"""\bibitem[de Moura and Bj{\o}rner(2008)]%
        {z2008}
\bibfield{author}{\bibinfo{person}{Leonardo de Moura}, {and}
  \bibinfo{person}{Nikolaj Bj{\o}rner}.}
\newblock \bibinfo{title}{{Z3: An Efficient SMT Solver}}.
"""

    cases = [
        ("etat sain -> muet", bib_ok, bbl_ok, 0),
        ("auteur fantome (l'incident reel) -> tire", bib_ok, bbl_ghost, 1),
        ("titre divergent -> tire", bib_ok, bbl_wrong_title, 1),
        ("accents LaTeX, etat sain -> muet", bib_accent, bbl_accent, 0),
        ("particule nobiliaire, etat sain -> muet", bib_particle, bbl_particle, 0),
    ]

    passed = 0
    with tempfile.TemporaryDirectory() as d:
        for label, bib, bbl, expect in cases:
            bp = os.path.join(d, "t.bib")
            lp = os.path.join(d, "t.bbl")
            open(bp, "w").write(bib)
            open(lp, "w").write(bbl)
            got = len(check(bp, lp))
            ok = (got > 0) == (expect > 0)
            passed += ok
            print(f"  [{'OK ' if ok else 'FAIL'}] {label} "
                  f"(divergences={got})")

    print(f"\n  self-test : {passed}/{len(cases)}")
    return 0 if passed == len(cases) else 1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--paper", default="ironproof_cobol")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        print("SELF-TEST check_bib_bbl_sync")
        return self_test()

    bib = os.path.join(HERE, f"{args.paper}.bib")
    bbl = os.path.join(HERE, f"{args.paper}.bbl")
    problems = check(bib, bbl)

    if problems:
        print(f"DIVERGENCE .bib / .bbl -- {args.paper} ({len(problems)})")
        for p in problems:
            print(f"  {p}")
        print("\n  Remede : relancer bibtex, puis recompiler le PDF.")
        return 1

    print(f"OK -- .bib et .bbl s'accordent ({args.paper})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
