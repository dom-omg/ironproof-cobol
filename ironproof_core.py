#!/usr/bin/env python3
"""
IRONPROOF-COBOL — Full Legacy Modernization Pipeline v2.0
IronProof 2026

Converts COBOL programs to Python with formal Z3 equivalence proof.
Handles all 10 enterprise COBOL constructs.

Usage:
  ./venv/bin/python3 ironproof_core.py --cobol my.cbl           # translate + prove
  ./venv/bin/python3 ironproof_core.py --cobol my.cbl --translate  # Claude translates
  ./venv/bin/python3 ironproof_core.py --demo-bug               # demo bug detection
  ./venv/bin/python3 ironproof_core.py --demo-ok                # demo correct proof
"""

import ast
import re
import json
import sys
import hashlib
import argparse
import operator
import datetime
import time
import os
import tempfile
import textwrap
from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any, Tuple, Union

try:
    from z3 import Real, RealVal, If, And, Or, Solver, sat, unsat, simplify, BoolVal
    from z3 import Z3_OP_UNINTERPRETED
except ImportError:
    print("ERROR: z3-solver manquant. pip install z3-solver", file=sys.stderr)
    sys.exit(1)

try:
    import anthropic
    _ANTHROPIC_OK = True
except ImportError:
    _ANTHROPIC_OK = False


# ─────────────────────────────────────────────────────────────────────────────
# PIC Type System
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class PicType:
    integer_digits: int
    decimal_digits: int
    is_signed: bool = False
    is_alpha: bool = False

    @classmethod
    def parse(cls, s: str) -> "PicType":
        s = s.upper().rstrip(".")
        signed = "S" in s
        alpha = "A" in s or "X" in s
        s = s.replace("S", "")
        v = s.find("V")
        int_part = s[:v] if v != -1 else s
        dec_part = s[v + 1:] if v != -1 else ""

        def count(p: str) -> int:
            m = re.search(r"[9A-Z]\((\d+)\)", p)
            return int(m.group(1)) if m else len(re.findall(r"[9AX]", p))

        return cls(
            integer_digits=count(int_part),
            decimal_digits=count(dec_part),
            is_signed=signed,
            is_alpha=alpha,
        )

    @property
    def python_default(self) -> str:
        if self.is_alpha:
            return '""'
        if self.decimal_digits > 0:
            return f'Decimal("0.{"0" * self.decimal_digits}")'
        return "Decimal(0)"

    @property
    def python_type(self) -> str:
        return "str" if self.is_alpha else "Decimal"

    @property
    def max_value(self) -> float:
        return float(10 ** self.integer_digits - 1)


@dataclass
class Variable:
    name: str
    level: int = 1
    pic: Optional[PicType] = None
    occurs: Optional[int] = None        # OCCURS n TIMES
    redefines: Optional[str] = None     # REDEFINES varname
    value: Optional[str] = None         # VALUE clause
    children: List["Variable"] = field(default_factory=list)  # group items
    # USAGE declare (COMP, COMP-5, BINARY, PACKED-DECIMAL...), None = DISPLAY implicite.
    # Garde parce qu'un champ binaire n'a PAS une seule semantique : sous IBM, TRUNC(STD)
    # tronque au PICTURE, TRUNC(BIN) a la taille machine. Le jeter faisait prouver tout
    # champ binaire sous TRUNC(STD) sans le dire (sonde du 2026-09-24).
    usage: Optional[str] = None


# ─────────────────────────────────────────────────────────────────────────────
# Statement IR — all 10 construct types
# ─────────────────────────────────────────────────────────────────────────────

@dataclass
class Condition:
    left: str
    op: str
    right: str
    negated: bool = False

    def to_z3(self, env: Dict[str, Any]) -> Any:
        def v(s: str) -> Any:
            val = env.get(s, env.get(s.upper()))
            if val is not None:
                return val
            s_clean = s.strip("'\"")
            if s_clean in ("SPACES", "SPACE"):
                return "SPACES"
            if re.match(r"-?\d", s_clean):
                return RealVal(s_clean)
            return s_clean
        L, R = v(self.left), v(self.right)
        if isinstance(L, str) or isinstance(R, str):
            if self.op == "=":
                result = BoolVal(str(L) == str(R))
            elif self.op == "NOT=":
                result = BoolVal(str(L) != str(R))
            else:
                result = BoolVal(False)
            return result if not self.negated else BoolVal(not result.sexpr().startswith("true"))
        z = {"<=": L <= R, "<": L < R, ">=": L >= R, ">": L > R, "=": L == R, "NOT=": L != R}.get(self.op, L == R)
        return z if not self.negated else ~z


@dataclass
class ComputeStmt:
    target: str
    expression: str


@dataclass
class MoveStmt:
    source: str
    targets: List[str]


# ⚠️ `target: str` ETAIT UNE AMPUTATION SILENCIEUSE. `ADD 1 TO A, B, C` ecrit dans
# TROIS variables ; le champ n'en portait qu'UNE, et `B`/`C` n'existaient nulle part
# dans le modele. `MoveStmt` avait deja `targets` (une liste) -- le frere arithmetique
# ne l'avait pas. Compter les freres : `SubtractStmt` portait le meme defaut.
# La liste est le SEUL champ : ajouter `targets` a cote de `target` aurait fabrique
# deux champs disant la meme chose, sans rien qui l'impose -- le miroir non garde.
@dataclass
class AddStmt:
    sources: List[str]
    targets: List[str]
    giving: Optional[str] = None


@dataclass
class SubtractStmt:
    sources: List[str]
    targets: List[str]
    giving: Optional[str] = None


@dataclass
class MultiplyStmt:
    left: str
    right: str
    giving: Optional[str] = None


@dataclass
class DivideStmt:
    dividend: str
    divisor: str
    giving: Optional[str] = None
    remainder: Optional[str] = None


@dataclass
class IfStmt:
    conditions: List[Condition]
    conjunction: str  # AND / OR
    then_stmts: List[Any]
    else_stmts: List[Any]


@dataclass
class WhenClause:
    conditions: List[Condition]
    stmts: List[Any]


@dataclass
class EvaluateStmt:
    when_clauses: List[WhenClause]
    other_stmts: List[Any]


@dataclass
class PerformStmt:
    # ⚠️ `boucle_declaree` dit qu'un mot-cle de BOUCLE (UNTIL / TIMES / VARYING) etait
    # present dans la SOURCE, meme si la condition n'a pas pu etre lue. Sans lui,
    # `PERFORM 2000-Process UNTIL WS-INFile-EOF` -- ou le UNTIL porte un NIVEAU 88,
    # donc un identifiant nu sans operateur, que `_parse_one_condition` refuse -- se
    # presente comme un simple appel de procedure : `until_conds` est vide. Un
    # consommateur qui inline « les PERFORM sans boucle » linearise alors une BOUCLE,
    # et prouve un autre programme que celui qu'on lui a donne. Mesure du 2026-09-09 :
    # 62 fichiers dscobol portent un PERFORM ... UNTIL, et le champ `until_conds` en
    # perdait la quasi-totalite.
    boucle_declaree: bool = False
    target: Optional[str] = None     # paragraph/section name (None = inline)
    until_conds: List[Condition] = field(default_factory=list)   # PERFORM UNTIL
    times_expr: Optional[str] = None        # PERFORM n TIMES
    varying_var: Optional[str] = None       # PERFORM VARYING
    from_expr: Optional[str] = None
    by_expr: Optional[str] = None
    until_varying_conds: List[Condition] = field(default_factory=list)
    inline_stmts: List[Any] = field(default_factory=list)  # PERFORM ... END-PERFORM


@dataclass
class CallStmt:
    program: str
    using_vars: List[str]
    returning_var: Optional[str]


@dataclass
class ExecSqlStmt:
    sql: str
    into_vars: List[str]


@dataclass
class FileOpenStmt:
    mode: str      # INPUT, OUTPUT, I-O, EXTEND
    file_name: str


@dataclass
class FileReadStmt:
    file_name: str
    into_var: Optional[str]
    at_end_stmts: List[Any]


@dataclass
class FileWriteStmt:
    record_name: str
    from_var: Optional[str]


@dataclass
class FileCloseStmt:
    file_name: str


@dataclass
class GoToStmt:
    target: str


@dataclass
class StopRunStmt:
    pass


@dataclass
class Paragraph:
    name: str
    stmts: List[Any]


@dataclass
class IronproofProgram:
    name: str
    variables: Dict[str, Variable]
    paragraphs: Dict[str, Paragraph]   # named sections/paragraphs
    body: List[Any]                    # main procedure body
    copy_books: List[str]              # COPY books resolved
    has_sql: bool = False
    has_file_io: bool = False
    has_goto: bool = False


# ─────────────────────────────────────────────────────────────────────────────
# 1. Preprocessor — COPY book resolver
# ─────────────────────────────────────────────────────────────────────────────

class IronproofPreprocessor:

    def __init__(self, copy_dirs: List[str] = None):
        self.copy_dirs = copy_dirs or ["."]
        self.resolved: List[str] = []

    def process(self, source: str) -> str:
        lines = source.splitlines()
        out = []
        for line in lines:
            m = re.match(r"\s+COPY\s+['\"]?(\S+?)['\"]?\s*\.?\s*$", line, re.IGNORECASE)
            if m:
                book = m.group(1)
                content = self._load_copy(book)
                if content:
                    self.resolved.append(book)
                    out.append(f"      * COPY {book} (inlined)")
                    out.extend(content.splitlines())
                else:
                    out.append(f"      * COPY {book} (NOT FOUND — stub)")
                    out.append(line)
            else:
                out.append(line)
        return "\n".join(out)

    def _load_copy(self, name: str) -> Optional[str]:
        for d in self.copy_dirs:
            for ext in ["", ".cpy", ".cbl", ".cob"]:
                path = os.path.join(d, name + ext)
                if os.path.exists(path):
                    return open(path).read()
        return None


# ─────────────────────────────────────────────────────────────────────────────
# 2. Comprehensive COBOL Parser
# ─────────────────────────────────────────────────────────────────────────────

# ⚠️ EN COBOL, `,` ET `;` SONT DES SEPARATEURS SANS VALEUR SEMANTIQUE -- et le
# tokeniseur enlevait le POINT final sans jamais toucher la virgule. Mesure exercee
# le 2026-08-27, avant correctif :
#
#     MOVE 7 TO A, B, C.   ->  MoveStmt(targets=['A,', 'B,', 'C'])
#     ADD  1 TO A, B, C.   ->  AddStmt(target='A,')
#
# `A,` et `B,` ne designent AUCUNE variable declaree : le modele ecrit dans des cibles
# fantomes. C'est la 8e amputation, et le point de reprise du 2026-08-26 nomme ce
# defaut comme la source des DEUX SEULES accusations que ce corpus ait jamais
# produites. Population comptee sur les 2345 : 952 occurrences sur 209 programmes.
#
# ⛔ PORTEE DELIBEREMENT ETROITE, ET DECLAREE. On ne detache la virgule que d'un NOM
# COBOL nu. Les 631 occurrences portant une parenthese sont des INDICES DE TABLE
# (`X(WS-IDX, 2)`) : leur virgule separe des indices, et l'enlever donnerait
# `(WS-IDX` -- casse autrement, et en silence. Un indice demande un vrai parseur
# d'indices ; le declarer vaut mieux que le demi-corriger. Les 345 litteraux
# numeriques (`2,`) sont laisses intacts pour la meme raison : ils vivent presque tous
# dans ces memes indices, et `DECIMAL-POINT IS COMMA` rend `1,5` legitime.
_RE_NOM_SEPARE = re.compile(r"^[A-Za-z][A-Za-z0-9-]*[,;]$")


def _sans_separateur(mot: str) -> str:
    """Un nom COBOL suivi d'un separateur `,`/`;`, rendu sans lui. Sinon, intact."""
    if _RE_NOM_SEPARE.match(mot):
        return mot[:-1]
    return mot


class IronproofParser:

    def parse(self, source: str, copy_dirs: List[str] = None) -> IronproofProgram:
        prep = IronproofPreprocessor(copy_dirs or ["."])
        source = prep.process(source)
        lines = self._normalize(source)
        name = self._parse_program_id(lines)
        variables = self._parse_data_division(lines)
        paragraphs, body = self._parse_procedure_division(lines)

        has_sql = any(isinstance(s, ExecSqlStmt) for p in paragraphs.values() for s in p.stmts) or \
                  any(isinstance(s, ExecSqlStmt) for s in body)
        has_file = any(isinstance(s, (FileOpenStmt, FileReadStmt, FileWriteStmt)) for p in paragraphs.values() for s in p.stmts) or \
                   any(isinstance(s, (FileOpenStmt, FileReadStmt, FileWriteStmt)) for s in body)
        has_goto = any(isinstance(s, GoToStmt) for p in paragraphs.values() for s in p.stmts) or \
                   any(isinstance(s, GoToStmt) for s in body)

        return IronproofProgram(
            name=name,
            variables=variables,
            paragraphs=paragraphs,
            body=body,
            copy_books=prep.resolved,
            has_sql=has_sql,
            has_file_io=has_file,
            has_goto=has_goto,
        )

    def _normalize(self, source: str) -> List[str]:
        out = []
        for raw in source.splitlines():
            if len(raw) >= 7:
                if raw[6] in ("*", "/"):
                    continue
                code = raw[7:72].strip()
            else:
                code = raw.strip()
                if code.startswith("*"):
                    continue
            if code:
                out.append(code.upper())
        return out

    def _parse_program_id(self, lines: List[str]) -> str:
        for line in lines:
            m = re.match(r"PROGRAM-ID\.\s+(\S+?)\.?$", line)
            if m:
                return m.group(1)
        return "UNKNOWN"

    _USAGE_RE = re.compile(
        r"USAGE\s+(?:IS\s+)?(COMP(?:-[0-9])?|BINARY(?:-\w+)?|PACKED-DECIMAL|INDEX|POINTER|DISPLAY|NATIONAL)",
        re.IGNORECASE,
    )
    _COMP_USAGE = {"COMP", "COMP-1", "COMP-2", "COMP-3", "COMP-4", "COMP-5",
                   "COMP-6", "BINARY", "BINARY-INT", "BINARY-LONG",
                   "BINARY-SHORT", "BINARY-DOUBLE", "PACKED-DECIMAL"}
    _USAGE_NU_RE = re.compile(
        r"(?<![\w-])(COMP(?:UTATIONAL)?(?:-[0-9])?|BINARY(?:-\w+)?|PACKED-DECIMAL)(?![\w-])",
        re.IGNORECASE,
    )

    # ⚠️ UNE SEULE DEFINITION POUR LES QUATRE SITES. Le test etait
    # `"PROCEDURE DIVISION" in line` -- UNE espace -- a quatre endroits. Le COBOL reel
    # ecrit `PROCEDURE    DIVISION.` (NIST) et `PROCEDURE        DIVISION.` (GnuCOBOL) :
    # la division entiere devenait invisible, `paragraphes: []` et `body: []`, et les
    # deux consommateurs s'accordaient sur un modele VIDE. Mesure du 2026-08-26 sur
    # benchmark/cobol_programs : PROCEDURE 1009 programmes sur 2345, DATA 969,
    # WORKING-STORAGE 781. Recopier le motif ici serait le miroir non garde.
    @staticmethod
    def _entete(line: str, *mots: str) -> bool:
        """Un en-tete de division/section, quel que soit l'espacement."""
        return re.search(r"\b" + r"\s+".join(mots) + r"\b", line) is not None

    def _parse_data_division(self, lines: List[str]) -> Dict[str, Variable]:
        variables: Dict[str, Variable] = {}
        in_parseable_section = False
        for line in lines:
            if self._entete(line, "DATA", "DIVISION"):
                in_parseable_section = True
                continue
            if self._entete(line, "PROCEDURE", "DIVISION"):
                break
            if (self._entete(line, "WORKING-STORAGE", "SECTION")
                    or self._entete(line, "LOCAL-STORAGE", "SECTION")
                    or self._entete(line, "LINKAGE", "SECTION")):
                in_parseable_section = True
                continue
            if (self._entete(line, "FILE", "SECTION")
                    or self._entete(line, "SCREEN", "SECTION")
                    or self._entete(line, "REPORT", "SECTION")):
                in_parseable_section = False
                continue
            if not in_parseable_section:
                continue

            rest = line.strip().rstrip(".")
            if not rest:
                continue

            m_lv = re.match(r"(\d{1,2})\s+(\S+)(.*)", rest)
            if not m_lv:
                continue
            lv = int(m_lv.group(1))
            name = m_lv.group(2).upper()
            tail = m_lv.group(3).strip()

            if lv == 88 or name == "FILLER":
                continue

            m_redef = re.match(r"REDEFINES\s+(\S+)\s*(.*)", tail, re.IGNORECASE)
            redef_target = None
            if m_redef:
                redef_target = m_redef.group(1).upper()
                tail = m_redef.group(2).strip()

            pic: Optional[PicType] = None
            pic_match = re.search(r"PIC(?:TURE)?\s+(?:IS\s+)?(\S+)", tail, re.IGNORECASE)
            if pic_match:
                try:
                    pic = PicType.parse(pic_match.group(1))
                except Exception:
                    pass

            usage_match = self._USAGE_RE.search(tail)
            usage_name = usage_match.group(1).upper() if usage_match else None

            if pic is None and usage_name and usage_name in self._COMP_USAGE:
                pic = PicType(integer_digits=9, decimal_digits=0, is_signed=True)

            # La forme courante ecrit `PIC S9(4) COMP.` SANS le mot USAGE, et `_USAGE_RE`
            # l'exige. On la lit ici pour le champ `usage` SEULEMENT : le repli PIC 9(9)
            # ci-dessus reste pilote par `usage_name`, pour ne deplacer aucun verdict
            # existant dans le meme changement. Les litteraux sont retires d'abord, sinon
            # `VALUE 'COMPTE'` lirait un faux COMP. Et ce motif-ci passe AVANT
            # `usage_name` : `_USAGE_RE` n'a pas de frontiere de mot, il lit
            # `USAGE COMPUTATIONAL-3` (packed) comme `COMP` (binaire).
            m_nu = self._USAGE_NU_RE.search(re.sub(r"'[^']*'|\"[^\"]*\"", " ", tail))
            usage_decl = m_nu.group(1).upper() if m_nu else usage_name

            val: Optional[str] = None
            val_match = re.search(r"VALUE\s+(?:IS\s+)?(.+?)(?:\s+COMP|\s+USAGE|\s*$)", tail, re.IGNORECASE)
            if val_match:
                val = val_match.group(1).strip().rstrip(".")

            occ: Optional[int] = None
            occ_match = re.search(r"OCCURS\s+(\d+)", tail, re.IGNORECASE)
            if occ_match:
                occ = int(occ_match.group(1))

            variables[name] = Variable(
                name=name, level=lv, pic=pic,
                occurs=occ, redefines=redef_target, value=val,
                usage=usage_decl,
            )

        return variables

    def _parse_procedure_division(self, lines: List[str]) -> Tuple[Dict[str, Paragraph], List[Any]]:
        in_proc = False
        proc: List[str] = []
        for line in lines:
            if self._entete(line, "PROCEDURE", "DIVISION"):
                in_proc = True
                continue
            if in_proc:
                proc.append(line)

        # LES EN-TETES, RELEVES AVANT L'APLATISSEMENT. Un nom de paragraphe qui
        # commence par un chiffre (`0000-MAINLINE`) est INDISCERNABLE d'un litteral
        # dans le flux de jetons : `COMPUTE X = Y + 5.` donnerait un paragraphe
        # nomme `5`. Le seul discriminant est structurel -- un en-tete OUVRE une
        # ligne (Area A) -- et cette information disparait au " ".join ci-dessous.
        entetes = set()
        for line in proc:
            m = self._RE_ENTETE_PARA.match(line)
            if m:
                entetes.add(m.group(1))

        # Join into token stream
        text = " ".join(proc)
        # Remove trailing period statements (replace ". " with " . ")
        tokens = self._tokenize(text)
        paragraphs, body = self._parse_paragraphs(tokens, entetes)
        return paragraphs, body

    # Un en-tete ouvre la ligne et porte son point. `_normalize` a deja retire les
    # colonnes de sequence et mis en MAJUSCULES -- la casse n'est donc jamais en jeu.
    _RE_ENTETE_PARA = re.compile(r"^([A-Z0-9][A-Z0-9-]*)\.(?:\s|$)")

    def _tokenize(self, text: str) -> List[str]:
        tokens = []
        i = 0
        while i < len(text):
            if text[i] in (" ", "\t"):
                i += 1
                continue
            if text[i] in ("'", '"'):
                quote = text[i]
                j = text.find(quote, i + 1)
                if j == -1:
                    j = len(text)
                tokens.append(text[i:j + 1])
                i = j + 1
                continue
            j = i
            while j < len(text) and text[j] not in (" ", "\t"):
                j += 1
            word = text[i:j]
            if word.endswith(".") and len(word) > 1:
                tokens.append(_sans_separateur(word[:-1]))
                tokens.append(".")
            else:
                tokens.append(_sans_separateur(word))
            i = j
        return [t for t in tokens if t and t not in (",", ";")]

    _RE_NOM_ALPHA = re.compile(r"^[A-Z][A-Z0-9-]*$")
    _RE_NOM_NUM = re.compile(r"^[0-9][A-Z0-9-]*$")

    def _parse_paragraphs(self, tokens: List[str],
                          entetes: Optional[set] = None) -> Tuple[Dict[str, Paragraph], List[Any]]:
        """`entetes` : les noms releves EN OUVERTURE DE LIGNE dans la division
        procedure. Il ne filtre QUE les noms commencant par un chiffre, parce que
        ce sont les seuls que le flux de jetons ne distingue pas d'un litteral.
        Passer `None` (aucun appelant du depot ne le fait) retombe sur l'ancienne
        regle alphabetique -- un nom numerique reste alors invisible, jamais
        halluciné : le defaut par defaut est l'abstention, pas l'invention."""
        paragraphs: Dict[str, Paragraph] = {}
        body: List[Any] = []

        # Detect paragraph names: a token followed by "." at top level
        # Strategy: collect all paragraph names first
        para_names = set()
        i = 0
        while i < len(tokens) - 1:
            tok = tokens[i]
            if tokens[i + 1] == "." and tok not in self._STMT_KEYWORDS:
                if self._RE_NOM_ALPHA.match(tok):
                    para_names.add(tok)
                elif entetes and self._RE_NOM_NUM.match(tok) and tok in entetes:
                    # `0000-MAINLINE`, `2100-SUMSALESFORSTATE`, `100` -- convention
                    # DS/IBM. 109 programmes du corpus rendaient `paragraphes: []`,
                    # donc un modele VIDE sur lequel les deux consommateurs
                    # s'accordaient (mesure 2026-08-26).
                    para_names.add(tok)
            i += 1

        # Now parse body, splitting at paragraph boundaries
        current_para: Optional[str] = None
        current_stmts: List[Any] = []
        i = 0
        while i < len(tokens):
            tok = tokens[i]
            if tok in para_names and i + 1 < len(tokens) and tokens[i + 1] == ".":
                # Save previous paragraph
                if current_para:
                    paragraphs[current_para] = Paragraph(name=current_para, stmts=current_stmts)
                elif current_stmts:
                    body.extend(current_stmts)
                current_para = tok
                current_stmts = []
                i += 2  # skip name and period
                continue

            stmt, consumed = self._parse_one_stmt(tokens, i)
            if stmt is not None:
                current_stmts.append(stmt)
                i += consumed
            else:
                i += 1

        if current_para:
            paragraphs[current_para] = Paragraph(name=current_para, stmts=current_stmts)
        elif current_stmts:
            body.extend(current_stmts)

        return paragraphs, body

    _STMT_KEYWORDS = {
        "COMPUTE", "MOVE", "IF", "ELSE", "END-IF", "EVALUATE", "WHEN", "END-EVALUATE",
        "PERFORM", "END-PERFORM", "CALL", "EXEC", "OPEN", "READ", "END-READ", "WRITE",
        "CLOSE", "ADD", "SUBTRACT", "MULTIPLY", "DIVIDE", "GO", "STOP", "DISPLAY",
        "STRING", "UNSTRING", "INITIALIZE", "SET",
    }

    def _parse_one_stmt(self, tokens: List[str], i: int) -> Tuple[Optional[Any], int]:
        if i >= len(tokens):
            return None, 1
        tok = tokens[i].upper()

        if tok == "COMPUTE":
            return self._parse_compute(tokens, i)
        if tok == "MOVE":
            return self._parse_move(tokens, i)
        if tok == "ADD":
            return self._parse_add(tokens, i)
        if tok == "SUBTRACT":
            return self._parse_subtract(tokens, i)
        if tok == "MULTIPLY":
            return self._parse_multiply(tokens, i)
        if tok == "DIVIDE":
            return self._parse_divide(tokens, i)
        if tok == "IF":
            return self._parse_if(tokens, i)
        if tok == "EVALUATE":
            return self._parse_evaluate(tokens, i)
        if tok == "PERFORM":
            return self._parse_perform(tokens, i)
        if tok == "CALL":
            return self._parse_call(tokens, i)
        if tok == "EXEC" and i + 1 < len(tokens) and tokens[i + 1].upper() == "SQL":
            return self._parse_exec_sql(tokens, i)
        if tok == "OPEN":
            return self._parse_file_open(tokens, i)
        if tok == "READ":
            return self._parse_file_read(tokens, i)
        if tok == "WRITE":
            return self._parse_file_write(tokens, i)
        if tok == "CLOSE":
            return self._parse_file_close(tokens, i)
        if tok == "GO" and i + 1 < len(tokens) and tokens[i + 1].upper() == "TO":
            return GoToStmt(target=tokens[i + 2] if i + 2 < len(tokens) else "?"), 3
        if tok == "STOP":
            return StopRunStmt(), 2  # STOP RUN
        if tok in (".", "END-IF", "END-EVALUATE", "END-PERFORM", "END-READ",
                   "ELSE", "WHEN", "DISPLAY", "INITIALIZE", "SET", "STRING", "UNSTRING"):
            return None, 0  # caller handles terminators

        return None, 1

    # ── COMPUTE ──────────────────────────────────────────────────────────────
    def _parse_compute(self, tokens: List[str], i: int) -> Tuple[Any, int]:
        # COMPUTE target = expression .
        j = i + 1
        if j >= len(tokens):
            return ComputeStmt(target="?", expression="0"), 1
        target = tokens[j]
        j += 1
        if j < len(tokens) and tokens[j] == "=":
            j += 1
        expr_tokens = []
        while j < len(tokens) and tokens[j] not in (".", "END-COMPUTE") and \
              tokens[j].upper() not in self._STMT_KEYWORDS:
            expr_tokens.append(tokens[j])
            j += 1
        if j < len(tokens) and tokens[j] == ".":
            j += 1
        expr = " ".join(expr_tokens).lower()
        return ComputeStmt(target=target, expression=expr), j - i

    # ── MOVE ─────────────────────────────────────────────────────────────────
    def _parse_move(self, tokens: List[str], i: int) -> Tuple[Any, int]:
        # MOVE source TO target1 target2 ...
        j = i + 1
        source = tokens[j] if j < len(tokens) else "?"
        j += 1
        if j < len(tokens) and tokens[j].upper() == "TO":
            j += 1
        targets = []
        while j < len(tokens) and tokens[j] not in (".", ) and \
              tokens[j].upper() not in self._STMT_KEYWORDS:
            targets.append(tokens[j])
            j += 1
        if j < len(tokens) and tokens[j] == ".":
            j += 1
        return MoveStmt(source=source, targets=targets), j - i

    # ── ADD ──────────────────────────────────────────────────────────────────
    def _parse_add(self, tokens: List[str], i: int) -> Tuple[Any, int]:
        # ADD a b TO target [GIVING result]  OR  ADD a b GIVING result
        j = i + 1
        sources = []
        while j < len(tokens) and tokens[j].upper() not in ("TO", "GIVING", ".") and \
              tokens[j].upper() not in self._STMT_KEYWORDS:
            sources.append(tokens[j])
            j += 1
        targets: List[str] = []
        giving = None
        if j < len(tokens) and tokens[j].upper() == "TO":
            j += 1
            j = self._noms_cibles(tokens, j, targets)
        if j < len(tokens) and tokens[j].upper() == "GIVING":
            j += 1
            giving = tokens[j] if j < len(tokens) else None
            j += 1
        if j < len(tokens) and tokens[j] == ".":
            j += 1
        return AddStmt(sources=sources, targets=targets, giving=giving), j - i

    # ⚠️ CE QUI SUIT UNE CIBLE N'EST PAS UNE CIBLE. Premiere version de `_noms_cibles` :
    # « tout jeton jusqu'au prochain mot-cle d'instruction ». Mesure du 2026-08-27 sur
    # les 2345 -- +12 081 cibles fantomes, dont `ROUNDED`, `MODE`, `IS`,
    # `NEAREST-TOWARD-ZERO`, parce que `ADD ... TO X ROUNDED MODE IS <mode>` porte une
    # CLAUSE apres la cible. Quatre programmes passaient de 10 a 2513 cibles.
    # J'ai reintroduit EXACTEMENT le defaut que je corrigeais, dans l'autre sens : des
    # cibles d'ecriture qui ne designent aucune variable. L'ancien code a cible unique
    # y echappait PAR ACCIDENT, en s'arretant au premier jeton.
    # Trouve en mesurant, pas en relisant -- la suite (225 tests) etait verte.
    _FIN_CIBLES = {
        "GIVING", "FROM", "TO", "BY", "INTO",
        "ROUNDED", "MODE", "IS",                       # ADD X TO Y ROUNDED MODE IS ...
        "NEAREST-TOWARD-ZERO", "PROHIBITED", "TOWARD-GREATER", "TOWARD-LESSER",
        "NEAREST-AWAY-FROM-ZERO", "NEAREST-EVEN", "TRUNCATION",
        "ON", "SIZE", "ERROR", "NOT", "OVERFLOW",      # ON SIZE ERROR / NOT ON ...
        "END-ADD", "END-SUBTRACT", "END-COMPUTE", "END-MULTIPLY", "END-DIVIDE",
        "REMAINDER", "DEPENDING", "AT", "END", "THEN", "END-STRING",
    }
    # Une cible est un NOM COBOL. Un jeton qui n'en est pas un ne peut pas etre une
    # cible : la regle positive ferme la classe au lieu d'enumerer les intrus.
    _RE_NOM_CIBLE = re.compile(r"^[A-Za-z][A-Za-z0-9-]*$")

    def _noms_cibles(self, tokens: List[str], j: int, sortie: List[str]) -> int:
        """Les noms de cibles d'une instruction arithmetique.

        UNE definition, consommee par `_parse_add` ET `_parse_subtract` : recopier la
        boucle aurait rouvert le miroir au moment meme ou on le ferme.

        S'arrete au premier jeton qui n'est PAS un nom COBOL, ou qui ouvre une clause.
        `ROUNDED` est saute avec son `MODE IS <mode>` optionnel, parce qu'il qualifie la
        cible precedente au lieu d'en ouvrir une neuve -- sans ca, `A ROUNDED, B` ne
        rendrait que `A`."""
        while j < len(tokens):
            t = tokens[j]
            u = t.upper()
            if u == "ROUNDED":
                j += 1
                if j + 1 < len(tokens) and tokens[j].upper() == "MODE" \
                        and tokens[j + 1].upper() == "IS":
                    j += 3 if j + 2 < len(tokens) else 2
                continue
            if u in self._FIN_CIBLES or u in self._STMT_KEYWORDS:
                break
            if not self._RE_NOM_CIBLE.match(t):
                break
            sortie.append(t)
            j += 1
        return j

    # ── SUBTRACT ─────────────────────────────────────────────────────────────
    def _parse_subtract(self, tokens: List[str], i: int) -> Tuple[Any, int]:
        # SUBTRACT a FROM target [GIVING result]
        j = i + 1
        sources = []
        while j < len(tokens) and tokens[j].upper() not in ("FROM", "GIVING", ".") and \
              tokens[j].upper() not in self._STMT_KEYWORDS:
            sources.append(tokens[j])
            j += 1
        targets: List[str] = []
        if j < len(tokens) and tokens[j].upper() == "FROM":
            j += 1
            j = self._noms_cibles(tokens, j, targets)
        giving = None
        if j < len(tokens) and tokens[j].upper() == "GIVING":
            j += 1
            giving = tokens[j] if j < len(tokens) else None
            j += 1
        if j < len(tokens) and tokens[j] == ".":
            j += 1
        return SubtractStmt(sources=sources, targets=targets, giving=giving), j - i

    # ── MULTIPLY ─────────────────────────────────────────────────────────────
    def _parse_multiply(self, tokens: List[str], i: int) -> Tuple[Any, int]:
        # MULTIPLY a BY b [GIVING result]
        j = i + 1
        left = tokens[j] if j < len(tokens) else "?"
        j += 1
        if j < len(tokens) and tokens[j].upper() == "BY":
            j += 1
        right = tokens[j] if j < len(tokens) else "?"
        j += 1
        giving = None
        if j < len(tokens) and tokens[j].upper() == "GIVING":
            j += 1
            giving = tokens[j] if j < len(tokens) else None
            j += 1
        if j < len(tokens) and tokens[j] == ".":
            j += 1
        return MultiplyStmt(left=left, right=right, giving=giving), j - i

    # ── DIVIDE ───────────────────────────────────────────────────────────────
    def _parse_divide(self, tokens: List[str], i: int) -> Tuple[Any, int]:
        # DIVIDE a INTO b  → b = b / a  (dividend=b, divisor=a)
        # DIVIDE a BY b    → a = a / b  (dividend=a, divisor=b)
        # DIVIDE a INTO b GIVING c → c = b / a
        # DIVIDE a BY b GIVING c   → c = a / b
        j = i + 1
        first_arg = tokens[j] if j < len(tokens) else "?"
        j += 1
        verb = tokens[j].upper() if j < len(tokens) else "BY"
        if verb in ("INTO", "BY"):
            j += 1
        second_arg = tokens[j] if j < len(tokens) else "?"
        j += 1
        giving = rem = None
        if j < len(tokens) and tokens[j].upper() == "GIVING":
            j += 1
            giving = tokens[j] if j < len(tokens) else None
            j += 1
        if j < len(tokens) and tokens[j].upper() == "REMAINDER":
            j += 1
            rem = tokens[j] if j < len(tokens) else None
            j += 1
        if j < len(tokens) and tokens[j] == ".":
            j += 1
        if verb == "INTO":
            return DivideStmt(dividend=second_arg, divisor=first_arg, giving=giving, remainder=rem), j - i
        else:
            return DivideStmt(dividend=first_arg, divisor=second_arg, giving=giving, remainder=rem), j - i

    # ── IF ───────────────────────────────────────────────────────────────────
    def _parse_if(self, tokens: List[str], i: int) -> Tuple[Any, int]:
        j = i + 1
        conditions, conj, j = self._parse_conditions_stream(tokens, j)

        # THEN (optional)
        if j < len(tokens) and tokens[j].upper() == "THEN":
            j += 1

        # Then branch
        then_stmts = []
        while j < len(tokens) and tokens[j].upper() not in ("ELSE", "END-IF", "."):
            stmt, consumed = self._parse_one_stmt(tokens, j)
            if stmt is not None:
                then_stmts.append(stmt)
                j += consumed
            else:
                j += 1

        # Else branch
        else_stmts = []
        if j < len(tokens) and tokens[j].upper() == "ELSE":
            j += 1
            while j < len(tokens) and tokens[j].upper() not in ("END-IF", "."):
                stmt, consumed = self._parse_one_stmt(tokens, j)
                if stmt is not None:
                    else_stmts.append(stmt)
                    j += consumed
                else:
                    j += 1

        if j < len(tokens) and tokens[j].upper() in ("END-IF", "."):
            j += 1

        return IfStmt(conditions=conditions, conjunction=conj,
                      then_stmts=then_stmts, else_stmts=else_stmts), j - i

    def _parse_conditions_stream(
        self, tokens: List[str], i: int
    ) -> Tuple[List[Condition], str, int]:
        conditions = []
        conjunction = "AND"
        j = i
        _TERM = {"THEN", "COMPUTE", "MOVE", "IF", "ELSE", "END-IF", "EVALUATE",
                 "PERFORM", "CALL", "EXEC", "OPEN", "READ", "WRITE", "CLOSE",
                 "ADD", "SUBTRACT", "MULTIPLY", "DIVIDE", "GO", "STOP", "WHEN",
                 "END-EVALUATE", "END-PERFORM"}
        _OPS = {"<=", ">=", "<", ">", "=", "NOT="}

        while j < len(tokens) and tokens[j].upper() not in _TERM and tokens[j] != ".":
            tok = tokens[j].upper()
            if tok == "AND":
                conjunction = "AND"
                j += 1
                continue
            if tok == "OR":
                conjunction = "OR"
                j += 1
                continue
            if tok == "NOT" and j + 1 < len(tokens):
                j += 1
                # NOT condition
                cond, consumed = self._parse_one_condition(tokens, j)
                if cond:
                    # XOR et non affectation : `NOT A NOT EQUAL B` porte DEUX negations.
                    # Sur `NOT A = B` (le seul cas qui existait avant), False^True = True
                    # -- comportement identique.
                    cond.negated = cond.negated != True
                    conditions.append(cond)
                    j += consumed
                continue
            cond, consumed = self._parse_one_condition(tokens, j)
            if cond:
                conditions.append(cond)
                j += consumed
            else:
                break

        return conditions, conjunction, j

    # Les operateurs RELATIONNELS EN MOTS de COBOL. Mesure sur benchmark/cobol_programs :
    # 10 715 lignes `IF`, dont 7 151 en `EQUAL` -- que cette fonction rendait None, donc
    # `conditions` vide, donc un trou dans le pont (cobol_to_ir.py:200).
    # ⚠️ Le 7 151 est CONCENTRE : 52 fichiers distincts, 4 en portent ~4 000 (famille de
    # tests generes). Le gain se compte par FICHIER, jamais par ligne.
    _MOTS_REL = {"GREATER": ">", "EXCEEDS": ">", "LESS": "<",
                 "EQUAL": "=", "EQUALS": "=", "UNEQUAL": "NOT="}
    _AVEC_EGAL = {">": ">=", "<": "<="}

    def _parse_one_condition(self, tokens: List[str], i: int) -> Tuple[Optional[Condition], int]:
        # Chemin SYMBOLIQUE inchange (A = B, A > B ...) : meme forme, meme consommation.
        if i + 2 < len(tokens) and tokens[i + 1] in ("<=", ">=", "<", ">", "=", "NOT="):
            return Condition(left=tokens[i], op=tokens[i + 1], right=tokens[i + 2]), 3

        # Chemin EN MOTS : LEFT [IS] [NOT] <mot> [THAN|TO] [OR EQUAL [TO]] RIGHT
        j = i + 1
        if j >= len(tokens):
            return None, 0
        left = tokens[i]
        haut = lambda k: tokens[k].upper() if k < len(tokens) else ""
        if haut(j) == "IS":
            j += 1
        negated = False
        if haut(j) == "NOT":
            negated = True
            j += 1
        mot = haut(j)
        op = self._MOTS_REL.get(mot)
        if op is None:
            return None, 0
        j += 1
        if haut(j) in ("THAN", "TO"):
            j += 1
        # « GREATER THAN OR EQUAL TO » -- le OR appartient a l'OPERATEUR, pas a la
        # conjonction. Sans ce cas, le flux lisait `OR` comme un OU logique et la
        # condition se coupait en deux.
        if haut(j) == "OR" and haut(j + 1) in ("EQUAL", "EQUALS"):
            j += 2
            if haut(j) == "TO":
                j += 1
            op = self._AVEC_EGAL.get(op, op)
        if j >= len(tokens):
            return None, 0
        right = tokens[j]
        j += 1
        return Condition(left=left, op=op, right=right, negated=negated), j - i

    # ── EVALUATE ─────────────────────────────────────────────────────────────
    def _parse_evaluate(self, tokens: List[str], i: int) -> Tuple[Any, int]:
        j = i + 1
        subject_tokens = []
        while j < len(tokens) and tokens[j].upper() not in ("WHEN", "END-EVALUATE"):
            subject_tokens.append(tokens[j])
            j += 1
        subject = None
        if subject_tokens and subject_tokens[0].upper() != "TRUE":
            subject = subject_tokens[0]

        when_clauses: List[WhenClause] = []
        other_stmts: List[Any] = []

        while j < len(tokens) and tokens[j].upper() != "END-EVALUATE":
            if tokens[j].upper() != "WHEN":
                j += 1
                continue
            j += 1
            if j < len(tokens) and tokens[j].upper() == "OTHER":
                j += 1
                while j < len(tokens) and tokens[j].upper() not in ("WHEN", "END-EVALUATE"):
                    stmt, consumed = self._parse_one_stmt(tokens, j)
                    if stmt is not None:
                        other_stmts.append(stmt)
                        j += consumed
                    else:
                        j += 1
                continue

            conditions, _, j = self._parse_conditions_stream(tokens, j)
            if not conditions and subject and j < len(tokens) and \
               tokens[j - 1].upper() not in self._STMT_KEYWORDS and tokens[j - 1] != ".":
                match_val = tokens[j - 1]
                j_back = j
                conditions = [Condition(left=subject, op="=", right=match_val)]
            if not conditions and subject:
                peek = j
                while peek < len(tokens) and tokens[peek].upper() not in ("WHEN", "END-EVALUATE") and \
                      tokens[peek].upper() not in self._STMT_KEYWORDS and tokens[peek] != ".":
                    conditions = [Condition(left=subject, op="=", right=tokens[peek])]
                    peek += 1
                    break
                if peek > j:
                    j = peek
            stmts = []
            while j < len(tokens) and tokens[j].upper() not in ("WHEN", "END-EVALUATE"):
                stmt, consumed = self._parse_one_stmt(tokens, j)
                if stmt is not None:
                    stmts.append(stmt)
                    j += consumed
                else:
                    j += 1
            when_clauses.append(WhenClause(conditions=conditions, stmts=stmts))

        if j < len(tokens) and tokens[j].upper() == "END-EVALUATE":
            j += 1

        return EvaluateStmt(when_clauses=when_clauses, other_stmts=other_stmts), j - i

    # ── PERFORM ──────────────────────────────────────────────────────────────
    def _parse_perform(self, tokens: List[str], i: int) -> Tuple[Any, int]:
        j = i + 1
        target = None
        until_conds: List[Condition] = []
        times_expr = None
        varying_var = from_expr = by_expr = None
        varying_conds: List[Condition] = []
        inline_stmts: List[Any] = []
        boucle_declaree = False

        if j >= len(tokens):
            return PerformStmt(target=None, until_conds=[], times_expr=None,
                               varying_var=None, from_expr=None, by_expr=None,
                               until_varying_conds=[], inline_stmts=[]), j - i

        tok = tokens[j].upper()

        # PERFORM paragraphname [THROUGH other]
        # ⚠️ Une cible qui COMMENCE PAR UN CHIFFRE (`PERFORM 2100-DOUBLE`) etait
        # refusee par `^[A-Z]` : la cible sortait a None et la collecte inline
        # s'ouvrait, avalant le reste du flux -- meme amputation que le defaut
        # `PERFORM <para> UNTIL`, un etage plus bas. Le seul cas ou un jeton
        # numerique apres PERFORM n'est PAS une cible est `PERFORM n TIMES`, et
        # `TIMES` le dit explicitement.
        _suivant = tokens[j + 1].upper() if j + 1 < len(tokens) else ""
        _est_nom = bool(self._RE_NOM_ALPHA.match(tokens[j])) or \
            (bool(self._RE_NOM_NUM.match(tokens[j])) and _suivant != "TIMES")
        if tok not in ("UNTIL", "VARYING", "WITH", "END-PERFORM") and \
           _est_nom and \
           tok not in self._STMT_KEYWORDS:
            target = tokens[j]
            j += 1
            if j < len(tokens) and tokens[j].upper() in ("THROUGH", "THRU"):
                j += 2  # skip THROUGH and target

        tok = tokens[j].upper() if j < len(tokens) else ""

        # n TIMES
        if j + 1 < len(tokens) and tokens[j + 1].upper() == "TIMES":
            times_expr = tokens[j].lower()
            boucle_declaree = True
            j += 2
        # UNTIL condition
        elif tok == "UNTIL":
            j += 1
            boucle_declaree = True
            until_conds, _, j = self._parse_conditions_stream(tokens, j)
        # VARYING
        elif tok == "VARYING":
            j += 1
            boucle_declaree = True
            varying_var = tokens[j] if j < len(tokens) else "?"
            j += 1
            if j < len(tokens) and tokens[j].upper() == "FROM":
                j += 1
                from_expr = tokens[j].lower() if j < len(tokens) else "1"
                j += 1
            if j < len(tokens) and tokens[j].upper() == "BY":
                j += 1
                by_expr = tokens[j].lower() if j < len(tokens) else "1"
                j += 1
            if j < len(tokens) and tokens[j].upper() == "UNTIL":
                j += 1
                varying_conds, _, j = self._parse_conditions_stream(tokens, j)

        # Inline PERFORM — collect until END-PERFORM.
        # ⚠️ UNIQUEMENT quand il n'y a PAS de cible. En COBOL les deux formes
        # s'excluent : `PERFORM <para> UNTIL c` est HORS-LIGNE (le corps est le
        # paragraphe, il n'y a pas d'END-PERFORM), `PERFORM UNTIL c ... END-PERFORM`
        # est INLINE (pas de cible). L'ancienne condition se lisait
        # `A or (B and C and D)` par precedence : avec une cible ET `UNTIL`, la
        # collecte s'ouvrait quand meme et, faute d'END-PERFORM, avalait tout le
        # reste du flux -- paragraphes suivants compris. C'est ce qui a fait sortir
        # un verdict FAVORABLE sur arith_09_loan_payment alors que CALC-POWER
        # n'etait jamais entre dans l'IR (2026-08-26). Banc :
        # tests/test_cobol_perform_parse.py, tenu dans les deux sens.
        if target is None:
            while j < len(tokens) and tokens[j].upper() != "END-PERFORM":
                stmt, consumed = self._parse_one_stmt(tokens, j)
                if stmt is not None:
                    inline_stmts.append(stmt)
                    j += consumed
                else:
                    j += 1
            if j < len(tokens) and tokens[j].upper() == "END-PERFORM":
                j += 1

        if j < len(tokens) and tokens[j] == ".":
            j += 1

        return PerformStmt(
            target=target, until_conds=until_conds, times_expr=times_expr,
            varying_var=varying_var, from_expr=from_expr, by_expr=by_expr,
            until_varying_conds=varying_conds, inline_stmts=inline_stmts,
            boucle_declaree=boucle_declaree,
        ), j - i

    # ── CALL ─────────────────────────────────────────────────────────────────
    def _parse_call(self, tokens: List[str], i: int) -> Tuple[Any, int]:
        j = i + 1
        program = tokens[j].strip("'\"") if j < len(tokens) else "?"
        j += 1
        using = []
        returning = None
        if j < len(tokens) and tokens[j].upper() == "USING":
            j += 1
            while j < len(tokens) and tokens[j].upper() not in ("RETURNING", ".", "END-CALL"):
                using.append(tokens[j])
                j += 1
        if j < len(tokens) and tokens[j].upper() == "RETURNING":
            j += 1
            returning = tokens[j] if j < len(tokens) else None
            j += 1
        if j < len(tokens) and tokens[j] in (".", "END-CALL"):
            j += 1
        return CallStmt(program=program, using_vars=using, returning_var=returning), j - i

    # ── EXEC SQL ─────────────────────────────────────────────────────────────
    def _parse_exec_sql(self, tokens: List[str], i: int) -> Tuple[Any, int]:
        j = i + 2  # skip EXEC SQL
        sql_tokens = []
        into_vars = []
        while j < len(tokens) and tokens[j].upper() != "END-EXEC":
            if tokens[j].upper() == "INTO":
                j += 1
                while j < len(tokens) and tokens[j].upper() not in ("FROM", "WHERE", "END-EXEC"):
                    into_vars.append(tokens[j].lstrip(":"))
                    j += 1
                continue
            sql_tokens.append(tokens[j])
            j += 1
        if j < len(tokens) and tokens[j].upper() == "END-EXEC":
            j += 1
        if j < len(tokens) and tokens[j] == ".":
            j += 1
        return ExecSqlStmt(sql=" ".join(sql_tokens), into_vars=into_vars), j - i

    # ── FILE OPS ─────────────────────────────────────────────────────────────
    def _parse_file_open(self, tokens: List[str], i: int) -> Tuple[Any, int]:
        j = i + 1
        mode = tokens[j].upper() if j < len(tokens) else "INPUT"
        j += 1
        name = tokens[j] if j < len(tokens) else "?"
        j += 1
        if j < len(tokens) and tokens[j] == ".":
            j += 1
        return FileOpenStmt(mode=mode, file_name=name), j - i

    def _parse_file_read(self, tokens: List[str], i: int) -> Tuple[Any, int]:
        j = i + 1
        name = tokens[j] if j < len(tokens) else "?"
        j += 1
        into_var = None
        if j < len(tokens) and tokens[j].upper() == "INTO":
            j += 1
            into_var = tokens[j] if j < len(tokens) else None
            j += 1
        at_end = []
        if j < len(tokens) and tokens[j].upper() == "AT":
            j += 2  # skip AT END
            while j < len(tokens) and tokens[j].upper() not in ("NOT", "END-READ", "."):
                stmt, consumed = self._parse_one_stmt(tokens, j)
                if stmt is not None:
                    at_end.append(stmt)
                    j += consumed
                else:
                    j += 1
        while j < len(tokens) and tokens[j].upper() != "END-READ" and tokens[j] != ".":
            j += 1
        if j < len(tokens) and tokens[j].upper() in ("END-READ", "."):
            j += 1
        return FileReadStmt(file_name=name, into_var=into_var, at_end_stmts=at_end), j - i

    def _parse_file_write(self, tokens: List[str], i: int) -> Tuple[Any, int]:
        j = i + 1
        record = tokens[j] if j < len(tokens) else "?"
        j += 1
        from_var = None
        if j < len(tokens) and tokens[j].upper() == "FROM":
            j += 1
            from_var = tokens[j] if j < len(tokens) else None
            j += 1
        if j < len(tokens) and tokens[j] == ".":
            j += 1
        return FileWriteStmt(record_name=record, from_var=from_var), j - i

    def _parse_file_close(self, tokens: List[str], i: int) -> Tuple[Any, int]:
        j = i + 1
        name = tokens[j] if j < len(tokens) else "?"
        j += 1
        if j < len(tokens) and tokens[j] == ".":
            j += 1
        return FileCloseStmt(file_name=name), j - i


# ─────────────────────────────────────────────────────────────────────────────
# 3. Python Code Generator
# ─────────────────────────────────────────────────────────────────────────────

_PYTHON_RESERVED = frozenset({
    "and", "as", "assert", "async", "await", "break", "class", "continue",
    "def", "del", "elif", "else", "except", "finally", "for", "from",
    "global", "if", "import", "in", "is", "lambda", "nonlocal", "not",
    "or", "pass", "raise", "return", "try", "while", "with", "yield",
})

def _tous_les_stmts(program):
    """Toutes les instructions du programme, corps ET paragraphes, a plat.

    Le garde d'appariement des paragraphes a besoin de voir CHAQUE PerformStmt, y
    compris ceux niches dans un IF ou dans un autre paragraphe -- sinon il ne peut
    pas recevoir son cas, et un garde qui ne peut pas recevoir son cas est
    indiscernable d'un garde qui a regarde sans rien trouver.
    """
    def descendre(st):
        yield st
        for champ in ("stmts", "then_stmts", "else_stmts", "inline_stmts", "when_clauses"):
            for sous in (getattr(st, champ, None) or []):
                yield from descendre(sous) if hasattr(sous, "__dataclass_fields__") else ()
    for st in (getattr(program, "body", None) or []):
        yield from descendre(st)
    for para in (getattr(program, "paragraphs", None) or {}).values():
        for st in (getattr(para, "stmts", None) or []):
            yield from descendre(st)


# Ce que `_snake` a le droit de rendre : un identifiant Python, eventuellement
# suivi d'UN indice `[...]` (une table COBOL `WS-T (I)` devient `ws_t[i]`).
# L'espace avant `[` est tolere : `_snake` rend `ws_table [i]`, qui est du Python
# VALIDE. Un motif qui le refusait a produit un faux positif des le premier essai --
# le garde doit refuser ce qui NE PARSE PAS, pas ce qui est mal cadence.
_NOM_EMIS_RE = re.compile(r"^[A-Za-z_][A-Za-z_0-9]*(\s*\[[^\[\]]+\])?$")


class NomNonEmettable(ValueError):
    """`_snake` a recu un fragment COBOL qui n'est PAS un nom de donnee."""


def _snake(name: str, _valider: bool = True) -> str:
    """Nom COBOL -> nom Python. SEUL emetteur de noms du generateur.

    ⚠️ LE GARDE DE SORTIE EST LE COEUR DE CETTE FONCTION. Sans lui, un fragment
    qui n'est pas un nom traverse sans un mot et ressort en Python invalide TROIS
    COUCHES PLUS BAS, ou plus rien ne dit d'ou il venait. Mesure du 2026-08-26 sur
    2345 programmes : 82 echecs de generation viennent de la, en trois symptomes
    qui sont le MEME defaut --
        indice / modification de reference   `(WS-STUDENT-SUB,` -> `(ws_student_sub,`
        litteral la ou un nom est attendu    `'X'`              -> `'x'`
        PROGRAM-ID quote                     `"_SHORT"`         -> `"_short"`
    Aucun n'est un identifiant Python, et aucun ne le signalait.

    ⚠️ CE QUE LE GARDE N'ATTRAPE PAS, et il faut le dire : `ROUNDED` et `FUNCTION`
    rendent `rounded` et `function`, qui SONT des identifiants valides. Ce sont des
    MOTS-CLES COBOL pris pour des noms de donnee par la regex de
    `_cobol_expr_to_py` -- 38 echecs de plus, cause DIFFERENTE, en amont d'ici.
    Un garde de sortie ne peut structurellement pas les voir."""
    brut = name
    # Un separateur de liste colle au nom (`RPT-SHOP-ID,` dans `MOVE A, B TO C`)
    # n'a JAMAIS fait partie du nom : c'est le parseur qui ne l'a pas consomme.
    # Le laisser passer produisait `ws.rpt_shop_id, = ws.sf_shop_id` -- du Python
    # VALIDE qui depaquette un tuple, donc une traduction silencieusement FAUSSE.
    # Mesure du 2026-08-26 : 44 programmes sur 2345 emettaient un nom a virgule,
    # et aucun ne le signalait. On retire le separateur, on ne devine rien d'autre.
    name = name.strip().rstrip(",;")
    name = name.lower().replace("-", "_")
    name = re.sub(r"\(([^)]+)\)", lambda m: f"[{_snake(m.group(1), False)}]" if not m.group(1).isdigit() else f"[{m.group(1)}]", name)
    if name and name[0].isdigit():
        name = f"p_{name}"
    if name in _PYTHON_RESERVED:
        name = f"{name}_v"
    if _valider and not _NOM_EMIS_RE.match(name):
        raise NomNonEmettable(
            "IRONPROOF-COBOL: %r n'est pas un nom de donnee -- rendu %r, qui n'est "
            "pas un identifiant Python. Defaut de GENERATION, attrape a l'EMETTEUR : "
            "sans ce garde il serait ressorti en SyntaxError trois couches plus bas, "
            "sans dire d'ou il venait." % (brut, name))
    return name


class PythonGen:

    def generate(self, program: IronproofProgram) -> str:
        lines = [
            "# Generated by IRONPROOF-COBOL v2.0 — Ironproof",
            f"# Program: {program.name}",
            f"# Generated: {datetime.datetime.now(datetime.timezone.utc).isoformat()}",
            "# Review and validate before production deployment.",
            "",
        ]

        # Imports
        lines += ["from dataclasses import dataclass, field", "from decimal import Decimal, ROUND_HALF_UP"]
        if program.has_sql:
            lines += ["# pip install sqlalchemy", "# from sqlalchemy import create_engine, text"]
        if program.has_file_io:
            lines += ["from typing import Iterator"]
        lines += ["", ""]

        # Working Storage as dataclass
        lines += ["@dataclass", "class WorkingStorage:"]
        if program.variables:
            for var in program.variables.values():
                if var.pic:
                    pyname = _snake(var.name)
                    default = var.pic.python_default
                    pytype = var.pic.python_type
                    lines.append(f"    {pyname}: {pytype} = field(default_factory=lambda: {default})")
        else:
            lines.append("    pass")
        lines += ["", ""]

        # Named paragraphs → functions
        for para_name, para in program.paragraphs.items():
            fname = _snake(para_name)
            lines.append(f"def {fname}(ws: WorkingStorage) -> None:")
            body_lines = self._gen_stmts(para.stmts, indent=1)
            if not body_lines:
                body_lines = ["    pass"]
            lines.extend(body_lines)
            lines += ["", ""]

        # Main function
        fname = _snake(program.name)
        lines.append(f"def {fname}(ws: WorkingStorage) -> None:")
        body_lines = self._gen_stmts(program.body, indent=1)
        if not body_lines:
            body_lines = ["    pass"]
        lines.extend(body_lines)
        lines += ["", ""]

        # Entry point
        lines += [
            'if __name__ == "__main__":',
            "    ws = WorkingStorage()",
            f"    {fname}(ws)",
            "    print(ws)",
        ]

        # LE GENERATEUR REFUSE D'EMETTRE DU PYTHON QUI NE PARSE PAS.
        #
        # Mesure du 2026-08-26, echantillon de 60 programmes du banc: TROIS rendaient
        # un `SyntaxError`/`IndentationError` sur NOTRE propre sortie (dscobol_100_
        # tablewa l.77, gnucobol_155_a_b_cob l.15, gnucobol_1487_prog_cob l.11), soit
        # 5 %. L'erreur ressortait trois couches plus bas, indistinguable d'un echec
        # de solveur dans le seau « encoding/solver failures » du banc.
        #
        # Echouer LA OU ON LE SAIT: un bug de generation est un bug de generation, pas
        # une limite de preuve. Un denominateur qui absorbe nos propres bugs ne peut
        # pas descendre -- c'est le defaut deja documente, ici avec son mecanisme.
        src = "\n".join(lines)

        # TOUT PARAGRAPHE CITE PAR UN `PERFORM` DOIT EXISTER DANS LE PYTHON EMIS.
        #
        # Meme principe que le recensement des sorties: un appariement qui doit
        # BOUCLER. Si le paragraphe cible n'a pas de `def`, son corps a ete absorbe
        # ailleurs -- et c'est le mode de defaillance le plus dangereux du pipeline,
        # parce qu'il ne casse RIEN.
        #
        # Incident fondateur, real_02_invoice_total (2026-08-26). Le COBOL:
        #     PERFORM CALC-LINE-TOTALS VARYING WS-IDX FROM 1 BY 1 UNTIL ...
        #     IF ... END-IF   puis SIX COMPUTE (remise, TPS, TVQ, total)
        # Le Python emis: un `while` inline dont le corps AVALE tout ce qui suit --
        # `calc_line_totals` jamais defini (grep -c = 0), WS-IDX jamais incremente
        # (grep -c = 0), les six COMPUTE deplaces dans la mauvaise branche du ELSE.
        # Le Python PARSE, donc le `compile()` ci-dessous ne le voit pas. L'echec
        # ressortait trois couches plus bas en « aucune sortie appariee », classe
        # dans le seau « rien a prouver ». UN BUG DE TRADUCTION DEGUISE EN ABSENCE
        # DE CONTENU.
        #
        # Taille mesuree sur les 2 345 programmes du banc: 65 utilisent
        # `PERFORM <paragraphe> ... VARYING` hors-ligne (2,8 %), dont 38 avec de
        # l'arithmetique. Sur ces 38: **0** ont leur paragraphe present dans le
        # Python emis -- 11 absorbes, 27 echouent deja plus tot.
        manquants = sorted({
            st.target for st in _tous_les_stmts(program)
            if isinstance(st, PerformStmt) and st.target
            and ("def %s(" % _snake(st.target)) not in src
        })
        if manquants:
            raise SyntaxError(
                "IRONPROOF-COBOL: paragraphe(s) cite(s) par PERFORM mais ABSENT(S) du "
                "Python emis pour %s -- %s.\n"
                "  Leur corps a ete absorbe ailleurs. Le Python peut PARSER et etre "
                "faux.\n"
                "  Defaut de GENERATION: il ne doit pas ressortir en « aucune sortie "
                "appariee »." % (program.name, ", ".join(manquants[:6])))

        try:
            compile(src, "<ironproof-genere>", "exec")
        except SyntaxError as e:
            # La LIGNE FAUTIVE va dans le message: sans elle, le garde empeche de
            # voir la sortie qu'il refuse -- constate en essayant de grouper les 13
            # cas du 2026-08-26. Un garde qui cache la preuve du defaut qu'il attrape
            # rend le diagnostic impossible.
            _l = (src.splitlines()[e.lineno - 1].rstrip()
                  if e.lineno and 0 < e.lineno <= len(src.splitlines()) else "(hors bornes)")
            raise SyntaxError(
                "IRONPROOF-COBOL a genere du Python INVALIDE pour %s -- %s (ligne %s).\n"
                "  ligne fautive : %s\n"
                "  C'est un defaut de GENERATION, pas une limite de preuve. Il ne doit\n"
                "  pas ressortir en « echec d'encodage » trois couches plus bas."
                % (program.name, e.msg, e.lineno, _l[:120])) from e
        return src

    def _gen_stmts(self, stmts: List[Any], indent: int) -> List[str]:
        lines = []
        for stmt in stmts:
            lines.extend(self._gen_stmt(stmt, indent))
        return lines

    def _gen_stmt(self, stmt: Any, indent: int) -> List[str]:
        pad = "    " * indent

        if isinstance(stmt, ComputeStmt):
            expr = self._cobol_expr_to_py(stmt.expression)
            return [f"{pad}ws.{_snake(stmt.target)} = Decimal(str({expr}))"]

        if isinstance(stmt, MoveStmt):
            src = self._val(stmt.source)
            return [f"{pad}ws.{_snake(t)} = {src}" for t in stmt.targets]

        if isinstance(stmt, AddStmt):
            total = " + ".join(self._val(s) for s in stmt.sources)
            if stmt.giving:
                # `ADD a b GIVING c`      -> c = a + b   (aucune cible TO)
                # `ADD a TO b GIVING c`   -> c = b + a
                # Plus d'une cible AVEC `GIVING` n'est PAS modelisee : elle est
                # contaminee en amont (`_unmodeled_effect`), jamais decidee ici.
                if not stmt.targets:
                    return [f"{pad}ws.{_snake(stmt.giving)} = {total}"]
                return [f"{pad}ws.{_snake(stmt.giving)} = "
                        f"ws.{_snake(stmt.targets[0])} + {total}"]
            return [f"{pad}ws.{_snake(t)} = ws.{_snake(t)} + {total}"
                    for t in stmt.targets]

        if isinstance(stmt, SubtractStmt):
            total = " + ".join(self._val(s) for s in stmt.sources)
            if stmt.giving:
                base = stmt.targets[0] if stmt.targets else stmt.giving
                return [f"{pad}ws.{_snake(stmt.giving)} = ws.{_snake(base)} - ({total})"]
            return [f"{pad}ws.{_snake(t)} = ws.{_snake(t)} - ({total})"
                    for t in stmt.targets]

        if isinstance(stmt, MultiplyStmt):
            target = stmt.giving or stmt.right
            return [f"{pad}ws.{_snake(target)} = {self._val(stmt.left)} * {self._val(stmt.right)}"]

        if isinstance(stmt, DivideStmt):
            target = stmt.giving or stmt.divisor
            lines = [f"{pad}ws.{_snake(target)} = {self._val(stmt.dividend)} / {self._val(stmt.divisor)}"]
            if stmt.remainder:
                lines.append(f"{pad}ws.{_snake(stmt.remainder)} = {self._val(stmt.dividend)} % {self._val(stmt.divisor)}")
            return lines

        if isinstance(stmt, IfStmt):
            return self._gen_if(stmt, indent)

        if isinstance(stmt, EvaluateStmt):
            return self._gen_evaluate(stmt, indent)

        if isinstance(stmt, PerformStmt):
            return self._gen_perform(stmt, indent)

        if isinstance(stmt, CallStmt):
            fname = _snake(stmt.program)
            # ⚠️ Il y avait ici un `args = ", ".join(f"ws.{_snake(v)}" ...)` CALCULE ET
            # JAMAIS UTILISE : la ligne emise ne prend que `fname`. Du code mort,
            # invisible tant que `_snake` ne validait rien -- le garde d'emetteur l'a
            # fait tomber sur 80 programmes le 2026-08-26.
            # ET IL A REVELE PLUS GROS : `stmt.using_vars` contient tout le reste du
            # paragraphe (IF, DISPLAY, MOVE, litteraux, 'STOP', 'RUN'...). `CALL 'X'
            # USING A B` n'a pas de terminateur, donc le parseur avale jusqu'a la fin
            # -- MEME amputation que `PERFORM <para> UNTIL` (corrigee en 2cad284).
            # Consequence vivante : `_unmodeled_effect` contamine depuis `using_vars`,
            # donc il SUR-contamine (direction sure, mais bruyante). Defaut de PARSEUR,
            # non corrige ici : il demande son propre banc.
            line = f"{pad}{fname}(ws)  # CALL {stmt.program}"
            if stmt.returning_var:
                line = f"{pad}ws.{_snake(stmt.returning_var)} = {fname}(ws)"
            return [line]

        if isinstance(stmt, ExecSqlStmt):
            return self._gen_sql(stmt, indent)

        if isinstance(stmt, FileOpenStmt):
            return [f"{pad}# OPEN {stmt.mode} {stmt.file_name}",
                    f"{pad}{_snake(stmt.file_name)}_handle = open({_snake(stmt.file_name)}_path, "
                    f"'{'r' if stmt.mode == 'INPUT' else 'w'}')"]

        if isinstance(stmt, FileReadStmt):
            return self._gen_read(stmt, indent)

        if isinstance(stmt, FileWriteStmt):
            src = f"ws.{_snake(stmt.from_var)}" if stmt.from_var else f"str(ws.{_snake(stmt.record_name)})"
            return [f"{pad}{_snake(stmt.record_name)}_handle.write({src} + '\\n')"]

        if isinstance(stmt, FileCloseStmt):
            return [f"{pad}{_snake(stmt.file_name)}_handle.close()"]

        if isinstance(stmt, GoToStmt):
            return [
                f"{pad}# ⚠️  GO TO {stmt.target} — converted to function call (review control flow)",
                f"{pad}{_snake(stmt.target)}(ws)",
            ]

        if isinstance(stmt, StopRunStmt):
            return [f"{pad}return  # STOP RUN"]

        return []

    def _gen_if(self, stmt: IfStmt, indent: int) -> List[str]:
        pad = "    " * indent
        cond_py = self._gen_conditions(stmt.conditions, stmt.conjunction)
        lines = [f"{pad}if {cond_py}:"]
        then = self._gen_stmts(stmt.then_stmts, indent + 1)
        lines.extend(then if then else [f"{pad}    pass"])
        if stmt.else_stmts:
            lines.append(f"{pad}else:")
            els = self._gen_stmts(stmt.else_stmts, indent + 1)
            lines.extend(els if els else [f"{pad}    pass"])
        return lines

    def _gen_evaluate(self, stmt: EvaluateStmt, indent: int) -> List[str]:
        pad = "    " * indent
        lines = []
        first = True
        for wc in stmt.when_clauses:
            cond_py = self._gen_conditions(wc.conditions, "AND")
            kw = "if" if first else "elif"
            lines.append(f"{pad}{kw} {cond_py}:")
            body = self._gen_stmts(wc.stmts, indent + 1)
            lines.extend(body if body else [f"{pad}    pass"])
            first = False
        if stmt.other_stmts:
            lines.append(f"{pad}else:")
            body = self._gen_stmts(stmt.other_stmts, indent + 1)
            lines.extend(body if body else [f"{pad}    pass"])
        return lines

    def _gen_perform(self, stmt: PerformStmt, indent: int) -> List[str]:
        pad = "    " * indent

        # PERFORM section-name
        if stmt.target and not stmt.inline_stmts and not stmt.until_conds and not stmt.times_expr:
            return [f"{pad}{_snake(stmt.target)}(ws)"]

        # PERFORM n TIMES
        if stmt.times_expr:
            lines = [f"{pad}for _ in range(int({self._val(stmt.times_expr)})):"]
            body = self._gen_stmts(stmt.inline_stmts, indent + 1)
            return lines + (body if body else [f"{pad}    pass"])

        # PERFORM UNTIL condition
        if stmt.until_conds:
            cond_py = self._gen_conditions(stmt.until_conds, "AND")
            lines = [f"{pad}while not ({cond_py}):"]
            body = self._gen_stmts(stmt.inline_stmts, indent + 1)
            return lines + (body if body else [f"{pad}    pass"])

        # PERFORM VARYING
        if stmt.varying_var:
            var = f"ws.{_snake(stmt.varying_var)}"
            from_v = self._val(stmt.from_expr or "1")
            by_v = self._val(stmt.by_expr or "1")
            cond_py = self._gen_conditions(stmt.until_varying_conds, "AND") if stmt.until_varying_conds else "False"
            lines = [
                f"{pad}{var} = {from_v}",
                f"{pad}while not ({cond_py}):",
            ]
            body = self._gen_stmts(stmt.inline_stmts, indent + 1)
            lines.extend(body if body else [f"{pad}    pass"])
            lines.append(f"{pad}    {var} += {by_v}")
            return lines

        # Inline PERFORM (no condition)
        return self._gen_stmts(stmt.inline_stmts, indent)

    def _gen_sql(self, stmt: ExecSqlStmt, indent: int) -> List[str]:
        pad = "    " * indent
        sql = stmt.sql.strip()
        lines = [
            f"{pad}# EXEC SQL",
            f"{pad}# {sql}",
        ]
        if stmt.into_vars:
            targets = ", ".join(f"ws.{_snake(v)}" for v in stmt.into_vars)
            lines.append(f"{pad}# result → {targets}")
            lines.append(f"{pad}# TODO: wire to db connection — e.g.:")
            lines.append(f"{pad}# {targets}, = db.execute(text(\"{sql}\")).fetchone()")
            safe_sql = sql[:60].replace("'", "\\'")
            lines.append(f"{pad}raise NotImplementedError('SQL not wired: {safe_sql}')")
        return lines

    def _gen_read(self, stmt: FileReadStmt, indent: int) -> List[str]:
        pad = "    " * indent
        handle = f"{_snake(stmt.file_name)}_handle"
        lines = [f"{pad}_{_snake(stmt.file_name)}_line = {handle}.readline()"]
        if stmt.at_end_stmts:
            lines.append(f"{pad}if not _{_snake(stmt.file_name)}_line:")
            at_end = self._gen_stmts(stmt.at_end_stmts, indent + 1)
            lines.extend(at_end if at_end else [f"{pad}    pass"])
        if stmt.into_var:
            lines.append(f"{pad}ws.{_snake(stmt.into_var)} = _{_snake(stmt.file_name)}_line.rstrip('\\n')")
        return lines

    def _gen_conditions(self, conditions: List[Condition], conjunction: str) -> str:
        if not conditions:
            return "True"
        parts = []
        for c in conditions:
            left = self._val(c.left)
            right = self._val(c.right)
            py_ops = {"<=": "<=", "<": "<", ">=": ">=", ">": ">", "=": "==", "NOT=": "!="}
            op = py_ops.get(c.op, "==")
            expr = f"{left} {op} {right}"
            if c.negated:
                expr = f"not ({expr})"
            parts.append(expr)
        glue = " and " if conjunction == "AND" else " or "
        return glue.join(parts)

    def _val(self, s: str) -> str:
        if s is None:
            return "Decimal(0)"
        s_up = s.upper()
        # String literals
        if s.startswith(("'", '"')):
            return s
        # Numeric literals (including +1, -1, .08, +.5)
        if re.match(r"^[+-]?(\d+\.?\d*|\.\d+)$", s):
            return f"Decimal('{s}')"
        # Special values
        if s_up in ("ZERO", "ZEROS", "ZEROES"):
            return "Decimal(0)"
        if s_up in ("SPACE", "SPACES"):
            return '""'
        if s_up == "TRUE":
            return "True"
        if s_up == "FALSE":
            return "False"
        # Variable reference
        return f"ws.{_snake(s)}"

    def _cobol_expr_to_py(self, expr: str) -> str:
        # Normalize COBOL arithmetic to Python
        expr = expr.strip()
        # Replace variable names with ws. prefix
        def replace_var(m):
            name = m.group(0)
            if re.match(r"^[+-]?(\d+\.?\d*|\.\d+)$", name):
                return f"Decimal('{name}')"
            if name.upper() in ("ZERO", "ZEROS", "ZEROES"):
                return "Decimal(0)"
            return f"ws.{_snake(name)}"

        result = re.sub(r"[A-Z][A-Z0-9-]*", replace_var, expr, flags=re.IGNORECASE)
        return result


# ─────────────────────────────────────────────────────────────────────────────
# 4. Z3 Equivalence Prover (for pure computational sections)
# ─────────────────────────────────────────────────────────────────────────────


def pic_range(pic: PicType) -> Tuple[float, float]:
    max_int = 10 ** pic.integer_digits
    if pic.decimal_digits > 0:
        scale = 10 ** pic.decimal_digits
        max_val = (max_int * scale - 1) / scale
    else:
        max_val = max_int - 1
    if pic.is_signed:
        return (-max_val, max_val)
    return (0.0, max_val)


# Un niveau + un nom + une clause PIC NUMERIQUE, n'importe ou dans la source -- FILE
# SECTION comprise, que `_parse_data_division` ecarte explicitement. C'est la question
# « le domaine est-il ECRIT quelque part », pas « le parseur l'a-t-il lu ».
_RE_PIC_SOURCE = re.compile(
    r"^\s*(?:0?[1-9]|[1-7]\d)\s+([A-Za-z0-9][A-Za-z0-9-]*)\s+.*?\bPIC(?:TURE)?\s+"
    r"(?:IS\s+)?[S9VP(0-9)]+", re.M | re.I)


def pic_declares_dans_la_source(source: str) -> set:
    """Les noms portant un PIC NUMERIQUE quelque part dans la source (MAJUSCULES)."""
    return {m.group(1).upper() for m in _RE_PIC_SOURCE.finditer(source or "")}


# ⚠️ BALAYAGE SOURCE INDEPENDANT DU PARSEUR, comme `_RE_PIC_SOURCE` et le compteur de
# verbes de `couverture_parse`. Le relire avec `_parse_add` rendrait le compteur
# CIRCULAIRE : il compterait ce que le parseur a pris, donc il serait muet sur ce que le
# parseur a perdu -- exactement la classe qu'il existe pour trouver.
_RE_APRES_TO = re.compile(r"\b(?:TO|INTO|GIVING)\b", re.I)
_RE_MOT_CIBLE = re.compile(r"[A-Za-z][A-Za-z0-9-]*(?:\s*\([^)]*\))?|[0-9][A-Za-z0-9-]*")
# Un mot qui ARRETE la liste : ce qui suit n'est plus une cible.
_ARRET = {"ROUNDED", "ON", "SIZE", "ERROR", "NOT", "BY", "FROM", "GIVING",
          "REMAINDER", "TIMES", "UNTIL", "VARYING", "DEPENDING", "AT", "END",
          "INVALID", "KEY", "OVERFLOW", "DELIMITED", "POINTER", "WITH", "OF", "IN"}


def noms_cibles_source(ligne: str) -> list:
    """Les NOMS de cible nommes apres TO / INTO / GIVING sur cette ligne source."""
    ligne = ligne.split(".")[0] if ligne.rstrip().endswith(".") else ligne
    meilleur = []
    for m in _RE_APRES_TO.finditer(ligne):
        reste = ligne[m.end():]
        noms = []
        for w in _RE_MOT_CIBLE.finditer(reste):
            mot = w.group(0).strip()
            racine = mot.upper().split("(")[0].strip()
            if racine in _ARRET:
                break
            noms.append(racine)
        if len(noms) > len(meilleur):
            meilleur = noms
    return meilleur


def cibles_source(ligne: str) -> int:
    """Combien de cibles la LIGNE SOURCE nomme apres TO / INTO / GIVING.

    Balayage direct plutot qu'une regex unique : la premiere version portait un
    lookahead qui exigeait un separateur APRES le dernier mot, donc elle rendait 0 sur
    `ADD 10 TO WS-A, WS-B.` -- c'est-a-dire sur le cas exact qu'elle mesure. Calibree
    sur huit lignes temoins, dans les deux sens."""
    return len(noms_cibles_source(ligne))


# ⚠️ CETTE TABLE EST LA SUPPOSITION QUI A RATE DEUX FOIS. `cibles_non_declarees` a
# d'abord normalise les noms (`rstrip(",.")`), puis n'a lu que `target`/`giving` --
# aveugle a `MoveStmt.targets` (une LISTE) et `DivideStmt.remainder`. Meme cause les
# deux fois : on PARCOURT l'IR en supposant une forme au lieu de la LIRE sur les
# dataclasses. Le symptome se corrige ; ce qui empeche la troisieme fois est
# `tests/test_couverture_cibles_ir.py`, qui enumere les dataclasses d'instruction et
# ECHOUE des qu'un champ pouvant porter une cible n'est couvert par aucun garde.
_CIBLES_IR = {"AddStmt": ("targets", "giving"), "SubtractStmt": ("targets", "giving"),
              "MultiplyStmt": ("giving",), "DivideStmt": ("giving", "remainder"),
              "ComputeStmt": ("target",), "MoveStmt": ("targets",)}

# Les noms de champ qui, dans N'IMPORTE QUELLE dataclass d'instruction, designent une
# CIBLE. Le test de couverture s'en sert pour interroger les dataclasses.
CHAMPS_CIBLE = ("target", "targets", "giving", "remainder", "dest", "into")

# ⚠️ TOUTE CIBLE N'EST PAS UNE VARIABLE. `PerformStmt.target` et `GoToStmt.target`
# nomment un PARAGRAPHE : les confronter aux variables declarees produirait 2162 faux
# positifs (mesure du 2026-08-26, premiere sonde). L'exemption existait deja -- elle
# etait IMPLICITE, c'est-a-dire indiscernable d'un oubli. Elle est declaree ici pour que
# le test de couverture puisse la reconnaitre COMME une decision, et pour qu'une
# dataclass neuve a cible non classee fasse quand meme echouer le test.
_CIBLES_PARAGRAPHE = {"PerformStmt": ("target",), "GoToStmt": ("target",)}


def _cibles_ir(st) -> int:
    n = 0
    for a in _CIBLES_IR.get(type(st).__name__, ()):
        v = getattr(st, a, None)
        if isinstance(v, list):
            n += len([x for x in v if isinstance(x, str) and x])
        elif isinstance(v, str) and v and v not in ("0", "?"):
            n += 1
    return n


_CIBLE_ARITH = ("AddStmt", "SubtractStmt", "MultiplyStmt", "DivideStmt",
                "ComputeStmt", "MoveStmt")


def cibles_non_declarees(program) -> set:
    """Les cibles d'ECRITURE qui ne sont pas des variables declarees.

    Une instruction arithmetique ecrit dans une VARIABLE. Quand l'IR porte une cible
    absente de `program.variables`, ce n'est pas une propriete du programme : c'est le
    parseur qui a ramasse le mauvais jeton. Mesure du 2026-08-26 sur les 2345 :
    **5598 occurrences dans 409 programmes** -- `OF` (1215, la forme qualifiee
    `X OF Y`), `TO` (680), `(`, `(SUB)`, `GOBACK`.

    ⚠️ C'EST CE QUI A PRODUIT LA SEULE ACCUSATION NEUVE DU CORPUS.
    `gnucobol_704_prog_cob` : `ADD 1024 TO CBLACK, CBLUE, CGREEN, ...` rend
    `target = 'CBLACK,'` -- virgule collee, et UNE cible sur huit. Le generateur
    Python strippe la virgule et applique l'addition, l'encodeur Z3 ne la strippe pas
    et ne l'applique pas : COBOL(CBLACK)=257 contre Python(CBLACK)=1281. C'est la
    PREMIERE fois que les deux consommateurs ne s'accordent PAS sur une amputation --
    et le desaccord sort en ACCUSATION contre la traduction, alors que le defaut est
    dans notre parseur."""
    mauvaises = set()
    declarees = {n.upper() for n in (getattr(program, "variables", {}) or {})}

    def _visite(lst):
        for st in lst or []:
            if type(st).__name__ in _CIBLE_ARITH:
                # ⚠️ TOUS LES CHAMPS D'ECRITURE, ET LES LISTES. Une premiere version ne
                # lisait que `target`/`giving` -- donc elle etait AVEUGLE a
                # `MoveStmt.targets` (une LISTE) et a `DivideStmt.remainder`, c'est-a-dire
                # a la majorite de la population qu'elle existe pour trouver : ma sonde
                # a la main comptait 409 programmes, le garde en rendait 45. Deuxieme
                # fois que ce garde ne regarde pas ou le defaut vit (la premiere etait
                # le `rstrip(",.")`). Les noms de champ viennent des dataclasses, pas
                # d'un souvenir : AddStmt/SubtractStmt(targets, giving),
                # MultiplyStmt/DivideStmt(giving, remainder), ComputeStmt(target),
                # MoveStmt(targets: List[str]).
                _vals = []
                for attr in ("target", "giving", "remainder", "targets", "dest"):
                    v = getattr(st, attr, None)
                    _vals.extend(v if isinstance(v, list) else [v])
                for v in _vals:
                    if not isinstance(v, str) or not v or v in ("0", "?"):
                        continue
                    if v.replace(".", "").replace("-", "").isdigit():
                        continue
                    # COMPARAISON EXACTE, comme l'encodeur. Une premiere version
                    # faisait `rstrip(",.")` -- et rendait ENSEMBLE VIDE sur
                    # `gnucobol_704`, le programme meme qui a motive ce garde :
                    # `'CBLACK,'` redevenait `CBLACK`, qui EST declare. Normaliser ici
                    # reconstruit exactement l'angle mort qu'on ferme, parce que
                    # l'encodeur, lui, ne normalise pas.
                    if v.upper() not in declarees:
                        mauvaises.add(v)
            for a in ("then_stmts", "else_stmts", "inline_stmts", "at_end_stmts",
                      "other_stmts"):
                _visite(getattr(st, a, None))
            for wc in getattr(st, "when_clauses", None) or []:
                _visite(getattr(wc, "stmts", None))

    for para in (getattr(program, "paragraphs", {}) or {}).values():
        _visite(getattr(para, "stmts", None))
    _visite(getattr(program, "body", None))
    return mauvaises


def _symboles_libres(expr) -> set:
    """Les noms des constantes libres dont une expression Z3 DEPEND (MAJUSCULES).

    Model-independant : c'est la question « de quoi ce verdict depend-il », qui a une
    reponse avant que le solveur ne reponde quoi que ce soit."""
    vus, pile, out = set(), [expr], set()
    while pile:
        e = pile.pop()
        if not is_expr(e):
            continue
        k = e.get_id()
        if k in vus:
            continue
        vus.add(k)
        try:
            if e.num_args() == 0 and e.decl().kind() == Z3_OP_UNINTERPRETED:
                out.add(e.decl().name().upper())
        except Exception:
            pass
        pile.extend(e.children())
    return out


def _nom_symbole(z3v, defaut: str) -> str:
    """Le nom sous lequel `_symboles_libres` et le contre-exemple designeront ce symbole.

    `bornes` repond a « ce symbole a-t-il recu une borne ». La QUESTION se pose dans
    l'espace de noms des CONSTANTES Z3 (`_symboles_libres`, les cles du cx) ; la REPONSE
    etait construite depuis les CLES du dictionnaire d'entree. Rien n'obligeait les deux
    a s'accorder -- miroir non garde, a l'interieur meme du gate de domaine.

    Mesure du 2026-08-27, cote Natural : `bounds` clef `revenu` (java_name, qui retire
    le `#`), symbole Z3 `#REVENU`. Donc `'#REVENU' not in {'REVENU'}` -> DOMAINE_LIBRE
    sur une variable POURTANT declaree `(N7.2)`, borne calculee et passee. Et le message
    emis accusait la source du client (« absent de la DATA DIVISION, sans PIC ») d'un
    defaut qui etait NOTRE clef : un except trop large, un etage plus haut.

    On enregistre donc ce qu'on a REELLEMENT borne, pas l'etiquette qu'on nous a tendue.
    Les deux sont ajoutes : la ou ils coincident (COBOL) rien ne change."""
    try:
        return z3v.decl().name().upper()
    except AttributeError:          # pas un objet Z3 : on retombe sur l'etiquette
        return defaut.upper()


def _apply_pic_input_bounds(
    solver, input_vars: Dict[str, Any], variables: Dict[str, "Variable"]
) -> set:
    """Rend l'ensemble des noms REELLEMENT bornes (MAJUSCULES).

    ⚠️ Cette fonction se TAIT sur ce qu'elle ne borne pas -- une variable absente de
    `variables`, sans PIC, ou alphanumerique repart libre sans qu'une ligne ne bouge.
    Tant que le retour etait `None`, personne en aval ne pouvait distinguer « borne a
    son domaine PIC » de « libre sur tout R ». C'est ce silence qui a produit le
    contre-exemple `valueofsale = -1` sur un `PIC 9(4)V99` NON SIGNE
    (dscobol_021_bds1001.cbl:48) : le symbole vient de l'encodage Python et n'est pas
    dans `program.variables`, donc aucune borne ne l'a jamais atteint."""
    bornes = set()
    # Deterministic assertion order (TOR-DET-1): iterate by variable name, not
    # dict/hash order. A conjunction of bounds is order-independent semantically,
    # but the order assertions reach Z3 flips marginal unsat/sat/unknown outcomes.
    for name, z3v in sorted(input_vars.items(), key=lambda kv: kv[0]):
        var = variables.get(name) or variables.get(name.upper())
        if var and var.pic and not var.pic.is_alpha:
            lo, hi = pic_range(var.pic)
            solver.add(z3v >= RealVal(str(lo)))
            solver.add(z3v <= RealVal(str(hi)))
            bornes.add(name.upper())
            bornes.add(_nom_symbole(z3v, name))
    return bornes


@dataclass
class OverflowResult:
    variable: str
    pic_range: Tuple[float, float]
    can_overflow: bool
    overflow_input: Optional[Dict[str, str]] = None
    details: str = ""


def check_overflow(
    outputs: Dict[str, Any],
    input_vars: Dict[str, Any],
    variables: Dict[str, "Variable"],
    timeout_ms: int = 15_000,
) -> List[OverflowResult]:
    results = []
    # Deterministic result order + assertion order (TOR-DET-1): sort by var name.
    for name, formula in sorted(outputs.items(), key=lambda kv: kv[0]):
        if not is_expr(formula):
            continue
        var = variables.get(name) or variables.get(name.upper())
        if not var or not var.pic or var.pic.is_alpha:
            continue
        lo, hi = pic_range(var.pic)
        s = Solver()
        s.set("timeout", timeout_ms)
        _apply_pic_input_bounds(s, input_vars, variables)
        s.add(Or(formula > RealVal(str(hi)), formula < RealVal(str(lo))))
        t0 = time.time()
        check = s.check()
        elapsed = (time.time() - t0) * 1000
        if check == sat:
            model = s.model()
            cx = {str(d): str(model[d]) for d in model.decls()}
            try:
                val_str = model.eval(formula).as_decimal(4).rstrip("?")
            except Exception:
                val_str = "?"
            results.append(OverflowResult(
                variable=name, pic_range=(lo, hi), can_overflow=True,
                overflow_input=cx,
                details=f"Overflow possible: {name}={val_str} outside [{lo}, {hi}] (Z3 {elapsed:.0f}ms)",
            ))
        else:
            results.append(OverflowResult(
                variable=name, pic_range=(lo, hi), can_overflow=False,
                details=f"No overflow for {name} in [{lo}, {hi}] (Z3 {elapsed:.0f}ms)",
            ))
    return results


# ── SMOKE RUN : le verdict n'est pas rendu sur un artefact jamais EXECUTE ─────
# Mesure du 2026-08-26 : deux programmes portaient un certificat EQUIVALENT et
# leur traduction levait `TypeError: cannot unpack non-iterable decimal.Decimal
# object` A LA PREMIERE LIGNE UTILE. Le certificat etait juste SUR SON PERIMETRE
# -- et c'est exactement ce qui rend le cas grave : le perimetre excluait « le code
# tourne ». Un client qui recoit EQUIVALENT sur une traduction qui plante ne
# conclura pas que le perimetre etait mal lu.
#
# `compile()` et `ast.parse` verifient la SYNTAXE, jamais la correction. La
# population des traductions VALIDES-MAIS-FAUSSES n'avait aucun compteur ; celle-ci
# lui en donne un. Ce n'est PAS un test fonctionnel : c'est un smoke run, il ne
# verifie aucun resultat. Il repond a une seule question -- est-ce que ca demarre.
#
# TROIS ISSUES, jamais deux (le flou « ca n'a pas tourne » melangeait un defaut de
# traduction et une surface non cablee) :
#   TOURNE        le module s'execute jusqu'au bout
#   NE_TOURNE_PAS il leve, ET la cause est DANS le code emis -> accusation
#   NON_TESTABLE  il leve sur une surface qu'on n'a jamais pretendu cabler
#                 (SQL non branche, fichier absent) -> on bloque, on n'accuse pas
_SMOKE_NON_TESTABLE = (
    ("NotImplementedError", "sql not wired"),
    ("NotImplementedError", "file"),
)


@dataclass
class SmokeResult:
    status: str                 # TOURNE | NE_TOURNE_PAS | NON_TESTABLE
    exc_type: str = ""
    message: str = ""
    entry: str = ""

    @property
    def bloque(self) -> bool:
        return self.status != "TOURNE"


def _smoke_non_testable(exc: BaseException, src: str) -> bool:
    """La levee vient-elle d'une surface DECLAREE non cablee, plutot que du code ?

    Sans cette distinction, « ca n'a pas tourne » melange une traduction fausse et
    un chemin de fichier qu'on n'a jamais fourni -- et le flou revient a chaque run."""
    nom, msg = type(exc).__name__, str(exc).lower()
    for t, frag in _SMOKE_NON_TESTABLE:
        if nom == t and frag in msg:
            return True
    # un nom `<x>_path` absent est une entree d'environnement, pas un defaut d'emission
    if nom == "NameError":
        m = re.search(r"name '([^']+)' is not defined", str(exc))
        if m and m.group(1).endswith("_path"):
            return True
    return False


def smoke_run(python_src: str, entry_hint: str = "",
              timeout_s: int = 5) -> SmokeResult:
    """Executer le Python emis. Aucun resultat n'est verifie -- seulement qu'il demarre.

    ISOLATION (sinon « non testable » devient un fourre-tout) : cwd temporaire, et
    tout identifiant `<x>_path` reference par la source est pre-alimente avec un
    fichier temporaire. Ce qui leve APRES ca vient du code emis.

    BORNE DE TEMPS obligatoire : du code emis peut BOUCLER SANS FIN, et un garde qui
    peut pendre se fait desactiver. Le depassement rend NON_TESTABLE, pas
    NE_TOURNE_PAS -- une boucle qui n'a pas fini n'est pas la preuve d'un defaut
    d'emission, et accuser dans le doute est la mauvaise direction."""
    import contextlib
    import io
    import os
    import signal
    import tempfile
    g: Dict[str, Any] = {}

    class _Depassement(Exception):
        pass
    try:
        code = compile(python_src, "<ironproof-genere>", "exec")
    except SyntaxError as e:
        return SmokeResult("NE_TOURNE_PAS", "SyntaxError", str(e)[:160])
    prev = os.getcwd()
    tmp = tempfile.mkdtemp(prefix="ironproof_smoke_")
    try:
        os.chdir(tmp)
        # isolation des chemins : chaque `<x>_path` reference recoit un vrai fichier
        for nom in sorted(set(re.findall(r"\b(\w+_path)\b", python_src))):
            chemin = os.path.join(tmp, nom + ".dat")
            open(chemin, "w").close()
            g[nom] = chemin
        _precedent = signal.signal(
            signal.SIGALRM,
            lambda *_: (_ for _ in ()).throw(_Depassement("delai de %ds depasse" % timeout_s)))
        signal.alarm(int(timeout_s))
        with contextlib.redirect_stdout(io.StringIO()), \
                contextlib.redirect_stderr(io.StringIO()):
            exec(code, g)                                  # definitions
            ws_cls = g.get("WorkingStorage")
            if ws_cls is None:
                return SmokeResult("NON_TESTABLE", "", "aucune WorkingStorage emise")
            noms = [k for k, v in g.items()
                    if callable(v) and not k.startswith("_")
                    and k not in ("WorkingStorage", "field", "dataclass", "Decimal",
                                  "ROUND_HALF_UP", "Iterator")]
            if not noms:
                return SmokeResult("NON_TESTABLE", "", "aucune fonction emise")
            entry = entry_hint if entry_hint in noms else noms[-1]
            g[entry](ws_cls())
        return SmokeResult("TOURNE", entry=entry)
    except _Depassement as e:
        return SmokeResult("NON_TESTABLE", "Depassement", str(e),
                           entry=locals().get("entry", ""))
    except BaseException as e:                              # noqa: BLE001
        st = "NON_TESTABLE" if _smoke_non_testable(e, python_src) else "NE_TOURNE_PAS"
        return SmokeResult(st, type(e).__name__, str(e)[:160], entry=locals().get("entry", ""))
    finally:
        try:
            signal.alarm(0)
            signal.signal(signal.SIGALRM, _precedent)
        except Exception:
            pass
        os.chdir(prev)


# ── LE REGISTRE DES STATUTS ───────────────────────────────────────────────────
# Chaque statut declare ICI, a sa DEFINITION, s'il bloque le verdict et s'il
# ACCUSE. Pas au site d'usage.
#
# Pourquoi c'est une regle et pas une convention (2026-08-26) : un correctif
# de contamination ecrit pour AMELIORER la solidite a cree un faux vert, parce que
# les sorties retirees retombaient dans HORS_PERIMETRE -- non bloquant -- decide
# ailleurs, au site d'emission. Un statut dont la semantique se decide loin de sa
# definition est un faux vert qui attend. Tout statut absent de ce registre est
# traite comme BLOQUANT (fail-closed) et le banc ECHOUE.
#
#   bloque : empeche EQUIVALENT
#   accuse : affirme une divergence REELLE -> NON_EQUIVALENT (et non ABSTENTION).
#            « je n'ai pas pu lire » n'est pas « c'est faux ».
STATUTS = {
    "PROVED":         {"bloque": False, "accuse": False},
    "HORS_PERIMETRE": {"bloque": False, "accuse": False},   # le modele source ignore la variable
    "REFUTED":        {"bloque": True,  "accuse": True},    # divergence prouvee
    "NO_MATCH":       {"bloque": True,  "accuse": True},    # sortie source sans contrepartie
    "NON_VERIFIE":    {"bloque": True,  "accuse": False},   # NOUS refusons de la modeliser
    "UNKNOWN":        {"bloque": True,  "accuse": False},   # le solveur n'a pas tranche
    # Le smoke run : la traduction livree demarre-t-elle ?
    "NE_TOURNE_PAS":  {"bloque": True,  "accuse": True},    # la cause est DANS le code emis
    "NON_TESTABLE":   {"bloque": True,  "accuse": False},   # surface jamais pretendue cablee
    # Contre-exemple trouve HORS d'un domaine d'entree etabli. Bloque -- on ne conclut
    # pas a l'equivalence -- mais N'ACCUSE PAS : le temoin peut ne pas exister dans le
    # programme reel. Asymetrie assumee : `PROVED` sur un sur-ensemble du domaine
    # IMPLIQUE l'equivalence sur le domaine reel ; `REFUTED` sur un sur-ensemble
    # n'implique rien.
    "DOMAINE_LIBRE":  {"bloque": True,  "accuse": False},
    # Le modele SOURCE porte une cible d'ecriture qui n'est pas une variable declaree
    # -- donc il n'est pas le programme. Bloque sans accuser : une divergence entre
    # deux artefacts dont l'un est corrompu par NOTRE parseur ne dit rien du client.
    "MODELE_CORROMPU": {"bloque": True,  "accuse": False},
    # ⚠️ LA SCISSION DE `DOMAINE_LIBRE` (2026-08-26). `DOMAINE_LIBRE` disait « le
    # domaine de l'obligation est libre » -- une propriete du PROBLEME. Le fait mesure
    # etait « notre encodeur a emis un symbole sans borne » -- une propriete de NOTRE
    # OUTILLAGE. Meme famille que les 100 TRADUCTION_INVALIDE retirees du dos du client,
    # un etage plus haut : ca deguisait un defaut REPARABLE en limite fondamentale, et
    # c'est exactement pourquoi le gate ne pouvait pas etre exerce sur le corpus.
    # Discriminant : la SOURCE declare-t-elle un PIC numerique pour ce symbole ?
    #   oui -> ENCODAGE_INCOMPLET (le domaine EST dans la source, on ne l'a pas lu)
    #   non -> DOMAINE_LIBRE (limite reelle)
    "ENCODAGE_INCOMPLET": {"bloque": True, "accuse": False},
    # ⚠️ NOTRE DETTE, PAS LE RESIDU DU CLIENT (2026-08-27). Rendre `NON_VERIFIE` quand
    # l'appelant n'a pas fourni `source_vars` recreait le canal trop etroit A LA SORTIE :
    # « la source ne declare rien » (residu reel) et « ce site d'appel n'est pas cable »
    # (12 sites sur 14) devenaient la MEME valeur. Un chiffre pessimiste et non
    # informatif n'est pas meilleur qu'un optimiste -- il est plus dur a corriger.
    # Bloque (on ne conclut pas), n'accuse pas (le client n'y est pour rien), et se
    # compte SEPAREMENT pour que « residu declare » et « dette de cablage » ne se
    # confondent jamais dans un total.
    "CABLAGE_ABSENT": {"bloque": True, "accuse": False},
}


def statut_bloque(status: str) -> bool:
    """Fail-closed : un statut inconnu du registre BLOQUE."""
    return STATUTS.get(status, {"bloque": True})["bloque"]


def statut_accuse(status: str) -> bool:
    """Fail-closed dans l'autre sens : un statut inconnu n'ACCUSE pas.
    Bloquer sans accuser est la direction sure -- on s'abstient, on ne condamne pas."""
    return STATUTS.get(status, {"accuse": False})["accuse"]


@dataclass
class ProofResult:
    status: str
    output_var: str
    counterexample: Optional[Dict[str, str]] = None
    proof_time_ms: float = 0.0
    details: str = ""
    smt2: Optional[str] = None   # SMT-LIB2 of the discharged obligation; UNSAT re-checkable by any solver

    @property
    def proved(self) -> bool:
        # HORS_PERIMETRE n'est pas une PREUVE, c'est une DECLARATION DE PORTEE: la
        # traduction ecrit une variable que le modele source ne connait pas. Elle est
        # LISIBLE dans le certificat et ne bloque pas le verdict.
        #
        # ⚠️ L'ARGUMENT QUI JUSTIFIE CA EST UNE HYPOTHESE, PAS UNE PROPRIETE. La
        # premiere version disait « une variable inconnue du modele source ne peut pas
        # faire diverger les sorties modelisees ». C'est vrai DES SORTIES et faux DE LA
        # TRADUCTION: si le Python calcule cette variable et l'ecrit quelque part que
        # le modele ne suit pas -- un fichier, une valeur de retour, un effet de bord --
        # la traduction fait quelque chose que le COBOL ne fait pas, et on rend
        # EQUIVALENT quand meme.
        #
        # L'hypothese, enoncee comme telle: LES SEULES SORTIES DE LA TRADUCTION SONT
        # CELLES QUE LE MODELE ENUMERE. Vraie sur notre generateur. NON VERIFIEE sur
        # une traduction tierce -- c'est-a-dire exactement le regime qui compte.
        #
        # Mesure du 2026-08-26: un Python emis avec `ws_intrus = ws_num_a * 999` en
        # plus rendait EQUIVALENT, 5 obligations, sans un mot sur l'intruse.
        # Si l'on veut qu'une sortie inattendue BLOQUE le vert, c'est une ligne ici.
        #
        # La semantique est desormais DECLAREE dans STATUTS, pas ecrite ici.
        #
        # ⚠️ NE PAS confondre avec NON_VERIFIE, qui BLOQUE. Les deux situations sont
        # OPPOSEES et ne partagent pas de seau :
        #   HORS_PERIMETRE  le COBOL n'a PAS cette variable ; la traduction l'invente
        #   NON_VERIFIE     le COBOL l'a et la CALCULE, et NOUS refusons de la modeliser
        # Les melanger fait qu'un verdict S'AMELIORE quand le modele se degrade --
        # mesure le 2026-08-26 : la contamination retirait une sortie de
        # `cobol_outputs`, elle retombait dans le seau HORS_PERIMETRE, et 4 programmes
        # sont passes DEFAVORABLE -> FAVORABLE en perdant de VRAIES refutations.
        return not statut_bloque(self.status)


def _build_group_children(variables: Dict[str, Variable]) -> Dict[str, List[str]]:
    ordered = list(variables.items())
    group_map: Dict[str, List[str]] = {}
    for idx, (name, var) in enumerate(ordered):
        if var.pic is not None:
            continue
        children: List[str] = []
        for j in range(idx + 1, len(ordered)):
            child_name, child_var = ordered[j]
            if child_var.level <= var.level:
                break
            if child_var.pic is not None:
                children.append(child_name)
        if children:
            group_map[name] = children
    return group_map


# ── Contamination : une instruction non modelisee ne disparait pas ────────────
_HAVOC_MARK = "__havoc"


def _mentions_havoc(expr) -> bool:
    """L'expression depend-elle d'une valeur INCONNUE ?

    Le garde porte sur la VALEUR, pas sur la comptabilite de contamination : il
    tient meme si le set `tainted` et l'execution divergent. Illisible -> True,
    c'est-a-dire on REFUSE de prouver (direction sure)."""
    try:
        return _HAVOC_MARK in expr.sexpr()
    except Exception:
        return True


def _stmt_writes(stmts, paragraphs: Dict[str, Any] = None,
                 _vus: set = None) -> set:
    """Les variables qu'une liste d'instructions peut ecrire. Sur-approxime.

    ⚠️ TRANSITIF A TRAVERS LES APPELS DE PARAGRAPHE quand `paragraphs` est fourni.
    Sans ca, `PERFORM A UNTIL c` ou A fait `PERFORM B` ne collecte que les
    ecritures de A -- celles de B echappent a la contamination, l'encodeur rend
    leur valeur INITIALE, et cette constante est ensuite comparee au Python.
    Mesure du 2026-08-26 : deux REFUTATIONS neuves (dscobol_021_bds1001,
    fileio_01_sequential) ou le cote COBOL valait `0` -- pas une divergence
    COBOL/Python, une divergence entre notre modele AMPUTE et le Python. Des faux
    ROUGES produits par mon propre correctif, meme classe que les cinq du papier."""
    out: set = set()
    _vus = set() if _vus is None else _vus
    for st in stmts or []:
        for attr in ("target", "into_var", "returning_var", "varying_var"):
            v = getattr(st, attr, None)
            if isinstance(v, str) and v:
                out.add(v.upper())
        for attr in ("using_vars", "into_vars"):
            v = getattr(st, attr, None)
            if isinstance(v, (list, tuple, set)):
                out |= {x.upper() for x in v if isinstance(x, str)}
        for attr in ("at_end_stmts", "inline_stmts", "then_stmts", "else_stmts"):
            v = getattr(st, attr, None)
            if isinstance(v, (list, tuple)):
                out |= _stmt_writes(v, paragraphs, _vus)
        # le corps d'un PERFORM hors-ligne est le PARAGRAPHE cible : suivre.
        cible = getattr(st, "target", None)
        if paragraphs and isinstance(cible, str) and cible in paragraphs \
                and cible not in _vus:
            _vus.add(cible)                       # borne les cycles PERFORM
            out |= _stmt_writes(paragraphs[cible].stmts, paragraphs, _vus)
        for wc in getattr(st, "when_clauses", None) or []:
            out |= _stmt_writes(getattr(wc, "stmts", None), paragraphs, _vus)
        out |= _stmt_writes(getattr(st, "other_stmts", None), paragraphs, _vus)
    return out


def _unmodeled_effect(stmt, paragraphs) -> Optional[Tuple[Optional[set], str]]:
    """(ecritures, genre) pour une instruction que l'encodeur ne modelise pas.

    `ecritures = None` veut dire « le controle de flot lui-meme n'est pas
    modelise » : le modele sequentiel plat devient faux, donc plus rien n'est
    affirmable et TOUT est contamine. Rend None quand l'instruction est bien
    modelisee -- c'est la seule facon de ne pas contaminer.

    Les instructions qui n'ecrivent AUCUNE variable (OPEN/CLOSE/WRITE) rendent un
    ensemble VIDE : elles sont NOMMEES dans le rapport sans rien contaminer. Un
    effet non modelise qu'on tait est le defaut d'origine ; le declarer sans
    sur-refuser est la reponse juste."""
    # ⚠️ `ADD a TO b, c GIVING d` : plusieurs cibles ET un `GIVING`. On ne modelise pas
    # cette forme -- et le geste dangereux serait de decider quand meme sur la premiere
    # cible, ce que faisait l'ancien `target: str` en silence. On NOMME et on contamine
    # les cibles concernees : fail-closed plutot que de choisir arbitrairement.
    if isinstance(stmt, (AddStmt, SubtractStmt)) and stmt.giving and len(stmt.targets) > 1:
        w = {t.upper() for t in stmt.targets if isinstance(t, str) and t}
        w.add(stmt.giving.upper())
        return w, "%s multi-cible AVEC GIVING" % type(stmt).__name__[:-4].upper()
    if isinstance(stmt, CallStmt):
        w = {v.upper() for v in (stmt.using_vars or []) if isinstance(v, str)}
        if isinstance(stmt.returning_var, str) and stmt.returning_var:
            w.add(stmt.returning_var.upper())
        return w, "CALL"
    if isinstance(stmt, ExecSqlStmt):
        return {v.upper().lstrip(":") for v in (stmt.into_vars or [])
                if isinstance(v, str)}, "EXEC SQL"
    if isinstance(stmt, FileReadStmt):
        w = _stmt_writes(stmt.at_end_stmts, paragraphs)
        if isinstance(stmt.into_var, str) and stmt.into_var:
            w.add(stmt.into_var.upper())
        return w, "READ"
    if isinstance(stmt, FileWriteStmt):
        return set(), "WRITE"
    if isinstance(stmt, FileOpenStmt):
        return set(), "OPEN"
    if isinstance(stmt, FileCloseStmt):
        return set(), "CLOSE"
    if isinstance(stmt, GoToStmt):
        return None, "GO TO"          # controle de flot -> modele plat faux
    if isinstance(stmt, StopRunStmt):
        # NOMME, mais ne contamine pas. Dans ce modele plat, les paragraphes qui
        # suivent MAIN-PARA ne sont pas « apres la fin du programme » : ils sont
        # la facon dont l'encodeur approxime les PERFORM qui les appellent. En
        # faire un brise-flot refuserait 53 programmes sur 150 pour rien.
        # ⚠️ LIMITE DECLAREE : un STOP RUN au MILIEU d'un paragraphe rend bien le
        # modele plat faux ; ce cas n'est pas distingue ici.
        return set(), "STOP RUN"
    if isinstance(stmt, PerformStmt):
        # La forme inline SANS modificateur est la seule vraiment modelisee
        # (elle est deroulee telle quelle). Toute forme a repetition
        # -- UNTIL / TIMES / VARYING -- est une BOUCLE que l'encodeur execute
        # une seule fois. Expose par le correctif du parseur 2cad284 : le corps
        # du paragraphe cible entre desormais dans l'IR, donc il serait prouve
        # a une iteration pres. Contaminer ce que la boucle ecrit.
        boucle = bool(stmt.until_conds or stmt.times_expr or stmt.varying_var
                      or stmt.until_varying_conds)
        if not boucle:
            return None
        w = _stmt_writes(stmt.inline_stmts, paragraphs)
        if isinstance(stmt.varying_var, str) and stmt.varying_var:
            w.add(stmt.varying_var.upper())
        cible = paragraphs.get(stmt.target) if stmt.target else None
        if cible is not None:
            # TRANSITIF : le paragraphe cible peut lui-meme PERFORM d'autres
            # paragraphes, et leurs ecritures sont dans la boucle tout autant.
            w |= _stmt_writes(cible.stmts, paragraphs, {stmt.target})
        elif stmt.target:
            return None, "PERFORM (cible introuvable)"   # cible perdue -> tout
        return w, "PERFORM boucle"
    return None


def _build_cobol_z3(program: IronproofProgram, report: Optional[Dict[str, Any]] = None
                    ) -> Tuple[Dict[str, Any], Dict[str, Any], Dict[str, Any]]:
    """`report`, s'il est fourni, recoit {"unmodeled": [...], "tainted": [...]} :
    ce que l'encodeur n'a PAS modelise. Parametre optionnel expres -- les 5 sites
    d'appel existants depaquettent 3 valeurs et ne changent pas."""
    # Un STOP RUN qui TERMINE son paragraphe est l'idiome normal : les paragraphes
    # suivants sont atteints par PERFORM, et le modele plat les deroule. Un STOP RUN
    # au MILIEU d'un paragraphe rend ce modele FAUX -- les instructions qui suivent
    # ne s'executent pas, et l'encodeur les compte quand meme. Ce n'est pas une
    # approximation, c'est une sur-affirmation : la seule classe qui tue la these.
    # Mesure du 2026-08-26 : 4 programmes sur 2345 (96 autres ont un STOP RUN en fin
    # de paragraphe non terminal, ce qui est correct et ne doit PAS bloquer).
    _stop_run_milieu = set()
    for _par in program.paragraphs.values():
        for _j, _st in enumerate(_par.stmts):
            if isinstance(_st, StopRunStmt) and _j != len(_par.stmts) - 1:
                _stop_run_milieu.add(id(_st))
    for _j, _st in enumerate(program.body or []):
        if isinstance(_st, StopRunStmt) and _j != len(program.body) - 1:
            _stop_run_milieu.add(id(_st))
    tainted: set = set()
    sticky: set = set()      # contamine PAR UNE BOUCLE -> jamais nettoye
    flow_broken: List[str] = []   # controle de flot non modelise -> plus rien n'est affirmable
    unmodeled: List[Dict[str, Any]] = []
    z3_vars = {n: Real(n) for n, v in program.variables.items() if v.pic and not v.pic.is_alpha}
    group_children = _build_group_children(program.variables)

    constants: set = set()
    for n, v in program.variables.items():
        if v.value and n in z3_vars:
            val_str = v.value.upper()
            if val_str in ("ZEROS", "ZEROES", "ZERO"):
                z3_vars[n] = RealVal(0)
                constants.add(n)
            elif val_str not in ("SPACES", "SPACE"):
                try:
                    z3_vars[n] = RealVal(val_str)
                    constants.add(n)
                except Exception:
                    pass

    def _eval_expr(expr: str, env: Dict[str, Any]) -> Any:
        expr = expr.strip().lower()
        lower_env = {k.lower(): v for k, v in env.items()}
        safe_env: Dict[str, Any] = {}
        safe_expr = expr
        for i, (key, val) in enumerate(sorted(lower_env.items(), key=lambda x: -len(x[0]))):
            placeholder = f"__v{i}__"
            safe_expr = safe_expr.replace(key, placeholder)
            safe_env[placeholder] = val
        return _parse_arith(safe_expr, safe_env)

    def _cond_z3(conds: List[Condition], env: Dict[str, Any], conjunction: str = "AND") -> Any:
        if not conds:
            return BoolVal(True)
        full_env = {**env, **{k.upper(): v for k, v in env.items()}}
        parts = [c.to_z3(full_env) for c in conds]
        if len(parts) == 1:
            return parts[0]
        if conjunction == "OR":
            return Or(*parts)
        return And(*parts)

    str_vars: Dict[str, Any] = {}
    for n, v in program.variables.items():
        if v.pic and v.pic.is_alpha:
            if v.value:
                val_str = v.value.upper()
                if val_str in ("SPACES", "SPACE"):
                    str_vars[n] = "SPACES"
                else:
                    str_vars[n] = v.value.strip("'\"")
            else:
                str_vars[n] = "SPACES"

    assigned: set = set()
    outputs: Dict[str, Any] = {}
    env = dict(z3_vars)
    env.update(str_vars)

    def process_stmts(stmts: List[Any], env: Dict[str, Any]) -> Dict[str, Any]:
        env = dict(env)
        for stmt in stmts:
            if isinstance(stmt, ComputeStmt):
                try:
                    val = _eval_expr(stmt.expression, env)
                    env[stmt.target] = val
                    assigned.add(stmt.target)
                    outputs[stmt.target] = val
                except Exception as _exc:
                    _echec_calcul(stmt, env, _exc)
            elif isinstance(stmt, MoveStmt):
                src_val = env.get(stmt.source)
                if src_val is None:
                    src_str = stmt.source.strip("'\"")
                    if src_str in ("SPACES", "SPACE", "ZEROS", "ZEROES", "ZERO"):
                        if src_str.startswith("SPACE"):
                            src_val = "SPACES"
                        else:
                            src_val = RealVal(0)
                    else:
                        try:
                            src_val = RealVal(src_str)
                        except Exception:
                            src_val = src_str
                for t in stmt.targets:
                    env[t] = src_val
                    assigned.add(t)
                    outputs[t] = src_val
            elif isinstance(stmt, AddStmt):
                try:
                    src_vals = []
                    for s in stmt.sources:
                        v = env.get(s.upper())
                        if v is None:
                            v = _eval_expr(s, env)
                        src_vals.append(v)
                    total = sum(src_vals, RealVal(0))
                    if stmt.giving:
                        g = stmt.giving.upper()
                        if stmt.targets:
                            base = env.get(stmt.targets[0].upper(), RealVal(0))
                            env[g] = base + total
                        else:
                            env[g] = total
                        assigned.add(g)
                        outputs[g] = env[g]
                    else:
                        # ⚠️ CHAQUE cible est ecrite. `ADD 1 TO A, B, C` en ecrit
                        # trois ; le modele n'en portait qu'une.
                        for _t in stmt.targets:
                            k = _t.upper()
                            env[k] = env.get(k, RealVal(0)) + total
                            assigned.add(k)
                            outputs[k] = env[k]
                except Exception as _exc:
                    _echec_calcul(stmt, env, _exc)
            elif isinstance(stmt, SubtractStmt):
                try:
                    src_vals = []
                    for s in stmt.sources:
                        v = env.get(s.upper())
                        if v is None:
                            v = _eval_expr(s, env)
                        src_vals.append(v)
                    total = sum(src_vals, RealVal(0))
                    if stmt.giving:
                        g = stmt.giving.upper()
                        b = (stmt.targets[0] if stmt.targets else stmt.giving).upper()
                        env[g] = env.get(b, RealVal(0)) - total
                        assigned.add(g)
                        outputs[g] = env[g]
                    else:
                        for _t in stmt.targets:
                            k = _t.upper()
                            env[k] = env.get(k, RealVal(0)) - total
                            assigned.add(k)
                            outputs[k] = env[k]
                except Exception as _exc:
                    _echec_calcul(stmt, env, _exc)
            elif isinstance(stmt, MultiplyStmt):
                try:
                    left = env.get(stmt.left.upper(), _eval_expr(stmt.left, env))
                    right = env.get(stmt.right.upper(), _eval_expr(stmt.right, env))
                    target_key = (stmt.giving or stmt.right).upper()
                    env[target_key] = left * right
                    assigned.add(target_key)
                    outputs[target_key] = env[target_key]
                except Exception as _exc:
                    _echec_calcul(stmt, env, _exc)
            elif isinstance(stmt, DivideStmt):
                try:
                    dividend = env.get(stmt.dividend.upper(), _eval_expr(stmt.dividend, env))
                    divisor = env.get(stmt.divisor.upper(), _eval_expr(stmt.divisor, env))
                    target_key = (stmt.giving or stmt.divisor).upper()
                    env[target_key] = dividend / divisor
                    assigned.add(target_key)
                    outputs[target_key] = env[target_key]
                except Exception as _exc:
                    _echec_calcul(stmt, env, _exc)
            elif isinstance(stmt, PerformStmt):
                if stmt.inline_stmts and not stmt.times_expr and not stmt.varying_var and not stmt.until_conds:
                    env = process_stmts(stmt.inline_stmts, env)
                else:
                    # Toute forme a repetition est une BOUCLE non modelisee : la
                    # branche `elif` ne doit pas la faire echapper au garde.
                    _contaminer(stmt, env)
            elif isinstance(stmt, EvaluateStmt):
                env = process_evaluate(stmt, env)
            elif isinstance(stmt, IfStmt):
                env = process_if(stmt, env)
            else:
                _contaminer(stmt, env)
        return env

    def _echec_calcul(stmt: Any, env: Dict[str, Any], exc: Exception) -> None:
        """Un calcul qui LEVE ne doit pas disparaitre.

        `_parse_arith` leve bien sur un identifiant inconnu -- un champ de FD que
        le parseur ne collecte pas, par exemple. Les cinq gestionnaires
        arithmetiques faisaient `except Exception: pass` : l'instruction
        disparaissait, la cible gardait sa valeur INITIALE, et cette valeur
        ressortait PROUVEE. Trace sur gnucobol_1074_prog_cob.cbl (2026-08-26) :
        AMT-TAX = 0*1/20 parce que MULTIPLY NUM-ORD BY PRICE avait ete avale.
        Le `except` transformait notre trou en verdict."""
        cible = (getattr(stmt, "giving", None) or getattr(stmt, "target", None)
                 or getattr(stmt, "remainder", None))
        if not isinstance(cible, str) or not cible:
            # cible illisible -> on ne sait pas ce qui a ete manque : refus total
            flow_broken.append("CALCUL ECHOUE (cible inconnue)")
            unmodeled.append({"kind": "CALCUL ECHOUE", "stmt": type(stmt).__name__,
                              "writes": [], "flow": True, "why": str(exc)[:120]})
            return
        cible = cible.upper()
        unmodeled.append({"kind": "CALCUL ECHOUE", "stmt": type(stmt).__name__,
                          "writes": [cible], "flow": False, "why": str(exc)[:120]})
        if cible not in z3_vars:
            return
        tainted.add(cible)
        sticky.add(cible)          # la valeur initiale n'est PAS le resultat
        env[cible] = Real(f"{cible}{_HAVOC_MARK}_{len(tainted)}")
        assigned.add(cible)
        outputs[cible] = env[cible]

    def _contaminer(stmt: Any, env: Dict[str, Any]) -> None:
        """Fail-closed : ce que l'encodeur ne modelise pas recoit une valeur
        INCONNUE au lieu de disparaitre. Avant ce garde, l'equivalence etait
        prouvee entre un COBOL ampute et un Python quelconque (08dde49)."""
        eff = _unmodeled_effect(stmt, program.paragraphs)
        if eff is None:
            return                       # modelise ailleurs : rien a signaler
        writes, kind = eff
        if isinstance(stmt, StopRunStmt) and id(stmt) in _stop_run_milieu:
            # le programme s'arrete ici, mais le modele plat continue -> tout est faux
            writes, kind = None, "STOP RUN au milieu d'un paragraphe"
        if writes is None:
            # Le modele sequentiel plat devient faux : on ne peut plus rien
            # affirmer, meme sur ce qui a l'air propre en aval.
            flow_broken.append(kind)
        cibles = (set(z3_vars) if writes is None
                  else {w for w in writes if w in z3_vars})
        if writes is None or kind.startswith("PERFORM"):
            # Une reassignation issue du CORPS de la boucle n'est pas un
            # nettoyage : c'est la boucle executee UNE fois. Elle reste refusee.
            sticky.update(cibles)
        unmodeled.append({"kind": kind, "stmt": type(stmt).__name__,
                          "writes": sorted(cibles),
                          "flow": writes is None})
        for name in sorted(cibles):
            tainted.add(name)
            env[name] = Real(f"{name}{_HAVOC_MARK}_{len(tainted)}")
            assigned.add(name)
            outputs[name] = env[name]

    def _fusion(cond: Any, t: Any, e: Any) -> Any:
        """If(c, x, x) vaut x : ne pas le fabriquer.

        Les deux fusions reconstruisaient un If pour CHAQUE variable de
        `assigned`, meme quand aucune branche ne l'avait touchee. Sur
        gnucobol_034 (998 IF, ~2 500 variables) le terme grossissait sans fin :
        45 ms au banc d'avril, plus de 80 min le 2026-09-24, et
        check_paper_numbers ne finissait plus. Meme valeur, terme plus petit."""
        if t is e:
            return t
        if isinstance(t, str) and isinstance(e, str) and t == e:
            return t
        if is_expr(t) and is_expr(e) and t.eq(e):
            return t
        return If(cond, t, e)

    def process_evaluate(stmt: EvaluateStmt, env: Dict[str, Any]) -> Dict[str, Any]:
        default_env = process_stmts(stmt.other_stmts, env)
        for wc in reversed(stmt.when_clauses):
            cond = _cond_z3(wc.conditions, env)
            then_env = process_stmts(wc.stmts, env)
            merged = dict(default_env)
            # Deterministic key order (TOR-DET-1): set-union iteration is hash-ordered
            # per process; sort it so merged/outputs build in a fixed order. Per-key
            # values are identical regardless of order — only insertion order changes.
            for k in sorted(set(then_env) | set(default_env)):
                if k not in z3_vars or k in assigned or k in constants:
                    t = then_env.get(k, default_env.get(k))
                    e = default_env.get(k, then_env.get(k))
                    if t is not None and e is not None:
                        merged[k] = _fusion(cond, t, e)
                    elif t is not None:
                        merged[k] = t
            default_env = merged
        env.update(default_env)
        outputs.update({k: v for k, v in default_env.items() if k in assigned})
        return env

    def process_if(stmt: IfStmt, env: Dict[str, Any]) -> Dict[str, Any]:
        cond = _cond_z3(stmt.conditions, env, stmt.conjunction)
        then_env = process_stmts(stmt.then_stmts, env)
        else_env = process_stmts(stmt.else_stmts, env) if stmt.else_stmts else env
        merged = dict(env)
        # Deterministic key order (TOR-DET-1): sort the set union (see process_evaluate).
        for k in sorted(set(then_env) | set(else_env)):
            if k in assigned:
                t = then_env.get(k, env.get(k))
                e = else_env.get(k, env.get(k))
                if t is not None and e is not None:
                    merged[k] = _fusion(cond, t, e)
        env.update(merged)
        outputs.update({k: v for k, v in merged.items() if k in assigned and is_expr(v)})
        return merged

    all_stmts = list(program.body)
    if not all_stmts:
        for para in program.paragraphs.values():
            all_stmts.extend(para.stmts)

    process_stmts(all_stmts, env)
    numeric_vars = {n for n, v in program.variables.items() if v.pic and not v.pic.is_alpha}
    inputs = {k: v for k, v in z3_vars.items() if k not in assigned and k not in constants}
    all_vars = dict(z3_vars)
    all_vars.update(str_vars)
    for k, v in env.items():
        if k in str_vars and isinstance(v, str):
            all_vars[k] = v
    if flow_broken:
        valid_outputs: Dict[str, Any] = {}     # fail-closed, sans exception
    else:
        valid_outputs = {k: v for k, v in outputs.items()
                         if is_expr(v) and k in numeric_vars
                         and k not in sticky and not _mentions_havoc(v)}
    if report is not None:
        report["unmodeled"] = unmodeled
        report["tainted"] = sorted(t for t in tainted if t in numeric_vars)
        report["flow_broken"] = list(flow_broken)
        report["sticky"] = sorted(t for t in sticky if t in numeric_vars)
        report["dropped_outputs"] = sorted(
            k for k, v in outputs.items()
            if is_expr(v) and k in numeric_vars and k not in valid_outputs)
    return inputs, valid_outputs, all_vars


def _build_python_z3(source: str, all_vars: Dict[str, Any],
                     input_only: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    tree = ast.parse(source.strip())
    funcs = [n for n in ast.walk(tree) if isinstance(n, ast.FunctionDef)]
    if not funcs:
        return {}
    env = {}
    for k, v in all_vars.items():
        snake = _snake(k)
        env[snake] = v
        env[k.lower()] = v
    initial_keys = set(env.keys())
    for func in funcs:
        env = _exec_stmts_z3(func.body, env)
    out = {}
    for k, v in env.items():
        if k.startswith("__") or not is_expr(v):
            continue
        if isinstance(v, str):
            continue
        if k in initial_keys and str(env.get(k)) == str(all_vars.get(k.upper().replace("_", "-"), "")):
            continue
        cobol_key = k.upper().replace("_", "-")
        out[cobol_key] = v
    return out


def _extract_target_name(node) -> Optional[str]:
    if isinstance(node, ast.Name):
        return node.id
    if isinstance(node, ast.Attribute):
        return node.attr
    return None


def _exec_stmts_z3(stmts, env):
    env = dict(env)
    for stmt in stmts:
        if isinstance(stmt, ast.Assign):
            name = _extract_target_name(stmt.targets[0])
            if name:
                try:
                    env[name] = _eval_ast_z3(stmt.value, env)
                except Exception:
                    pass
        elif isinstance(stmt, ast.AugAssign):
            name = _extract_target_name(stmt.target)
            if name and name in env:
                try:
                    rhs = _eval_ast_z3(stmt.value, env)
                    ops = {ast.Add: operator.add, ast.Sub: operator.sub,
                           ast.Mult: operator.mul, ast.Div: operator.truediv}
                    op_fn = ops.get(type(stmt.op))
                    if op_fn:
                        env[name] = op_fn(env[name], rhs)
                except Exception:
                    pass
        elif isinstance(stmt, ast.Return) and stmt.value:
            try:
                env["__return__"] = _eval_ast_z3(stmt.value, env)
            except Exception:
                pass
        elif isinstance(stmt, ast.If):
            try:
                cond = _eval_ast_z3(stmt.test, env)
                then_env = _exec_stmts_z3(stmt.body, env)
                else_env = _exec_stmts_z3(stmt.orelse, env) if stmt.orelse else env
                # Deterministic key order (TOR-DET-1): sort the set union (Python side).
                for k in sorted(set(then_env) | set(else_env)):
                    t, e = then_env.get(k, env.get(k)), else_env.get(k, env.get(k))
                    if t is not None and e is not None and str(t) != str(e):
                        env[k] = If(cond, t, e)
                    elif t is not None:
                        env[k] = t
            except Exception:
                pass
        elif isinstance(stmt, ast.For):
            try:
                body_env = _exec_stmts_z3(stmt.body, env)
                env.update({k: v for k, v in body_env.items() if k not in env or str(env[k]) != str(v)})
            except Exception:
                pass
    return env


def _eval_ast_z3(node, env):
    if isinstance(node, ast.Constant):
        v = node.value
        if isinstance(v, bool):
            return BoolVal(v)
        if isinstance(v, (int, float)):
            return RealVal(str(v))
        if isinstance(v, str):
            try:
                return RealVal(v)
            except Exception:
                return v
        return v
    if isinstance(node, ast.Name):
        nm = node.id
        return env.get(nm, env.get(nm.lower(), env.get(nm.upper(), Real(nm))))
    if isinstance(node, ast.Attribute):
        return env.get(node.attr, env.get(node.attr.lower(), env.get(node.attr.upper(), Real(node.attr))))
    if isinstance(node, ast.BinOp):
        L, R = _eval_ast_z3(node.left, env), _eval_ast_z3(node.right, env)
        ops = {ast.Add: operator.add, ast.Sub: operator.sub,
               ast.Mult: operator.mul, ast.Div: operator.truediv}
        return ops.get(type(node.op), operator.add)(L, R)
    if isinstance(node, ast.UnaryOp):
        if isinstance(node.op, ast.USub):
            return -_eval_ast_z3(node.operand, env)
        if isinstance(node.op, ast.Not):
            inner = _eval_ast_z3(node.operand, env)
            if isinstance(inner, bool):
                return BoolVal(not inner)
            return ~inner
        return _eval_ast_z3(node.operand, env)
    if isinstance(node, ast.BoolOp):
        vals = [_eval_ast_z3(v, env) for v in node.values]
        if isinstance(node.op, ast.And):
            return And(*vals) if len(vals) > 1 else vals[0]
        return Or(*vals) if len(vals) > 1 else vals[0]
    if isinstance(node, ast.Compare):
        L = _eval_ast_z3(node.left, env)
        R = _eval_ast_z3(node.comparators[0], env)
        if isinstance(L, str) or isinstance(R, str):
            if isinstance(node.ops[0], ast.Eq):
                return BoolVal(str(L) == str(R))
            elif isinstance(node.ops[0], ast.NotEq):
                return BoolVal(str(L) != str(R))
            return BoolVal(False)
        ops = {ast.Lt: operator.lt, ast.LtE: operator.le, ast.Gt: operator.gt,
               ast.GtE: operator.ge, ast.Eq: operator.eq, ast.NotEq: operator.ne}
        return ops.get(type(node.ops[0]), operator.eq)(L, R)
    if isinstance(node, ast.IfExp):
        return If(_eval_ast_z3(node.test, env), _eval_ast_z3(node.body, env), _eval_ast_z3(node.orelse, env))
    if isinstance(node, ast.Call):
        if isinstance(node.func, ast.Name) and node.func.id == "Decimal":
            if node.args:
                arg = node.args[0]
                if isinstance(arg, ast.Constant):
                    return RealVal(str(arg.value))
                return _eval_ast_z3(arg, env)
        if isinstance(node.func, ast.Name) and node.func.id in ("int", "float", "str"):
            if node.args:
                return _eval_ast_z3(node.args[0], env)
        return RealVal(0)
    return RealVal(0)


def _parse_arith(expr: str, env: Dict[str, Any]) -> Any:
    expr = expr.strip()
    depth = 0
    for i in range(len(expr) - 1, 0, -1):
        c = expr[i]
        if c == ")": depth += 1
        elif c == "(": depth -= 1
        if depth == 0 and c in "+-":
            L, R = _parse_arith(expr[:i], env), _parse_arith(expr[i+1:], env)
            return (L + R) if c == "+" else (L - R)
    depth = 0
    for i in range(len(expr) - 1, 0, -1):
        c = expr[i]
        if c == ")": depth += 1
        elif c == "(": depth -= 1
        if depth == 0 and c in "*/":
            L, R = _parse_arith(expr[:i], env), _parse_arith(expr[i+1:], env)
            return (L * R) if c == "*" else (L / R)
    if expr.startswith("(") and expr.endswith(")"):
        return _parse_arith(expr[1:-1], env)
    key = expr.upper()
    if key in env: return env[key]
    if expr in env: return env[expr]
    try:
        return RealVal(expr)
    except Exception:
        raise ValueError(f"Expression inconnue: '{expr}'")


def is_expr(v: Any) -> bool:
    try:
        from z3 import is_expr as z3_is_expr
        return z3_is_expr(v)
    except Exception:
        return False


# Les trois verdicts, et ils NE se replient PAS en deux. Ajouter NON_VERIFIE sans
# apprendre au verdict a le lire creerait une nouvelle facon d'ACCUSER du code
# correct : « je n'ai pas pu lire cette sortie » n'est pas « ta sortie est fausse ».
# Mesure du 2026-08-26 : dscobol_048_table1 et nist_255_obic1a basculaient vers
# DEFAVORABLE avec ZERO REFUTED -- 7 et 2 NON_VERIFIE, rien d'autre.
VERDICT_EQUIVALENT = "EQUIVALENT"        # tout est apparie et prouve
VERDICT_ABSTENTION = "ABSTENTION"        # rien n'est refute, mais tout n'est pas lu
VERDICT_NON_EQUIVALENT = "NON_EQUIVALENT"  # une divergence REELLE a ete trouvee
# ⚠️ LE QUATRIEME. « Notre traduction ne demarre pas » n'est NI une divergence
# COBOL/Python NI une abstention : c'est un defaut de NOTRE generateur. Le ranger
# dans NON_EQUIVALENT fait porter au CLIENT une accusation qui nous appartient --
# meme faute que `all(r.proved)`, un cran plus loin. Mesure du 2026-08-26 : 106
# programmes sur 107 « non equivalents » etaient dans ce cas.
VERDICT_TRADUCTION_INVALIDE = "TRADUCTION_INVALIDE"

# La semantique de chaque statut est DECLAREE dans STATUTS (voir plus haut) --
# jamais recopiee ici : deux listes qui doivent s'accorder sont un miroir non garde.


def verdict_equivalence(results: List["ProofResult"]) -> str:
    """Le verdict d'un lot d'obligations. Trois issues, jamais deux.

    Un `all(r.proved)` seul confond « non verifie » et « refute » : il rend rouge
    dans les deux cas, donc il accuse quand il aurait du s'abstenir."""
    if not results:
        return VERDICT_ABSTENTION
    # L'ordre compte : une divergence REELLE l'emporte sur « ca ne demarre pas »,
    # parce qu'un contre-exemple Z3 dit quelque chose que l'autre ne dit pas.
    if any(r.status == "REFUTED" for r in results):
        return VERDICT_NON_EQUIVALENT
    # NO_MATCH = une sortie SOURCE sans contrepartie dans la traduction. C'est notre
    # generateur qui n'a pas emis, pas le COBOL qui diverge -- meme classe que
    # NE_TOURNE_PAS, et il ne part pas non plus sur le dos du client (2026-08-26).
    if any(r.status in ("NE_TOURNE_PAS", "NO_MATCH") for r in results):
        return VERDICT_TRADUCTION_INVALIDE
    if any(statut_accuse(r.status) for r in results):
        return VERDICT_NON_EQUIVALENT
    if any(statut_bloque(r.status) for r in results):
        return VERDICT_ABSTENTION
    return VERDICT_EQUIVALENT if all(r.proved for r in results) \
        else VERDICT_ABSTENTION


def _obligation_smoke(python_src: str, entry_hint: str = "") -> List["ProofResult"]:
    """Le smoke run, rendu sous forme d'OBLIGATION -- un seul mecanisme de verdict.

    Un verdict favorable sur un artefact jamais EXECUTE est ce qui a permis deux
    certificats EQUIVALENT sur des traductions qui levaient un TypeError a la
    premiere ligne utile (2026-08-26). L'obligation traverse `verdict_equivalence`
    comme les autres : NE_TOURNE_PAS accuse, NON_TESTABLE bloque sans accuser."""
    if not python_src or not python_src.strip():
        return []
    r = smoke_run(python_src, entry_hint=entry_hint)
    if r.status == "TOURNE":
        return []
    return [ProofResult(
        status=r.status, output_var="(execution)",
        details=("La traduction emise ne demarre pas : %s: %s. Un verdict favorable "
                 "sur un artefact jamais execute exclut « le code tourne » de son "
                 "perimetre -- et personne ne lit un certificat comme ca."
                 % (r.exc_type, r.message))
        if r.status == "NE_TOURNE_PAS" else
        ("Le smoke run n'a pas pu trancher : %s: %s. Surface jamais pretendue cablee "
         "(SQL, fichier) ou delai depasse. On bloque, on n'accuse pas."
         % (r.exc_type, r.message)))]


def prove_equivalence(
    cobol_outputs: Dict[str, Any],
    python_outputs: Dict[str, Any],
    input_vars: Dict[str, Any],
    bounds: Optional[Dict[str, Tuple[float, float]]] = None,
    variables: Optional[Dict[str, "Variable"]] = None,
    timeout_ms: int = 15_000,
    left_label: str = "COBOL",
    right_label: str = "Python",
    unverified: Optional[set] = None,
    source_vars: Optional[set] = None,
    cibles_invalides: Optional[set] = None,
    pic_declares: Optional[set] = None,
) -> List[ProofResult]:
    """`unverified` : les sorties que l'ENCODEUR a refuse de modeliser (le
    `dropped_outputs` de _build_cobol_z3). Elles recoivent NON_VERIFIE, qui BLOQUE
    le verdict -- sans ca elles retombent dans HORS_PERIMETRE, qui ne bloque pas,
    et le verdict s'ameliore parce que le modele s'est degrade."""
    unverified = {u.upper() for u in (unverified or set())}
    # ⚠️ `source_vars` : les variables que le programme SOURCE connait. Sans elles,
    # HORS_PERIMETRE confond deux choses OPPOSEES -- « le COBOL n'a pas cette
    # variable, la traduction l'a inventee » (declaration de portee, non bloquante)
    # et « le COBOL l'a et l'ECRIT, c'est NOUS qui ne l'avons pas modelisee »
    # (non-verification, bloquante). Mesure du 2026-08-26 : dscobol_075_ods0004
    # sortait EQUIVALENT avec 10 sorties REELLES du rapport (ACCT-BALANCE-O,
    # LAST-NAME-O, PRINT-REC...) rangees en HORS_PERIMETRE, une seule prouvee.
    #
    # ⚠️⚠️ ET « rien recu » N'EST PAS « la source ne declare rien » (2026-08-27).
    # `None` et `set()` s'effondraient ici dans la meme valeur, et l'effondrement
    # tombait du cote VERT : sans information, la soustraction `- source_vars` ne
    # retire rien, donc TOUTE sortie sans contrepartie va dans HORS_PERIMETRE, qui
    # ne bloque pas. Le correctif du 2026-08-26 a ete livre par un PARAMETRE OPTIONNEL,
    # donc il ne protege que les appelants mis a jour -- une autre chaine (non publiee ici)
    # n'en passe aucun, et heritait du comportement d'avant la scission.
    # Mesure du 2026-08-27 : 232 obligations Natural sur 596 en HORS_PERIMETRE,
    # comptees PROVED en aval (dans cette autre chaine).
    # FORME A RETENIR : un correctif livre par un parametre optionnel n'est un
    # correctif que pour les appelants mis a jour ; c'est la VALEUR PAR DEFAUT qui
    # decide de la polarite pour tous les autres. Ici elle etait permissive.
    _source_vars_inconnu = source_vars is None
    source_vars = {v.upper() for v in (source_vars or set())}
    # LES AUTRES DISCRIMINANTS DE LA MEME CLASSE (2026-08-27). Mesure du chemin verdict :
    #   unverified       `(... or set())`  absent => AUCUN NON_VERIFIE emis pour les
    #                                      sorties abandonnees par l'encodeur
    #   cibles_invalides `if cibles_...:`  absent => la branche MODELE_CORROMPU ne
    #                                      tourne jamais
    #   pic_declares     `(... or set())`  absent => DOMAINE_LIBRE au lieu
    #                                      d'ENCODAGE_INCOMPLET : deguise NOTRE trou en
    #                                      limite fondamentale du probleme
    # Aucun ne designe un ensemble de variables identifiable quand il manque -- c'est la
    # COMPLETUDE de l'ensemble d'obligations qui devient inconnue. Donc un enregistrement
    # AU NIVEAU DE L'APPEL, pas par variable : il bloque (on ne conclut pas), n'accuse pas
    # (le client n'y est pour rien), et se compte a part du residu declare.
    _discriminants_absents = [n for n, v in (("unverified", unverified),
                                             ("cibles_invalides", cibles_invalides),
                                             ("pic_declares", pic_declares)) if v is None]
    if not cobol_outputs:
        # ⚠️ NE PAS ACCUSER ICI. « Aucune sortie extraite » n'est pas « les deux
        # programmes different » -- c'est nous qui n'avons rien pu lire. NO_MATCH
        # accuse (il est reserve a une sortie source SANS contrepartie), et depuis
        # que la contamination retire des sorties, ce chemin se declenche des qu'on
        # les retire TOUTES : un faux ROUGE produit par un garde de solidite.
        # Mesure 2026-08-26 : fileio_01_sequential sortait NON_EQUIVALENT avec un
        # smoke run VERT et zero obligation.
        return [ProofResult(status="NON_VERIFIE", output_var="(aucun)",
                            details=(f"Aucune variable de sortie {left_label} n'a pu "
                                     f"etre extraite ou modelisee. Ni equivalence ni "
                                     f"divergence n'est affirmee."))]

    py_upper = {k.upper(): v for k, v in python_outputs.items()}
    shared = set(cobol_outputs) & set(py_upper)

    if not shared:
        return [ProofResult(status="NO_MATCH", output_var="(aucun)",
                            details=f"Pas de variable commune — {left_label}:{list(cobol_outputs)} / {right_label}:{list(py_upper)}")]

    # LE RECENSEMENT DOIT BOUCLER: obligations emises == sorties du modele source.
    #
    # Avant le 2026-08-26 on iterait sur l'INTERSECTION et le COMPLEMENT n'etait
    # jamais compte: une sortie du modele source sans contrepartie disparaissait en
    # silence, et le verdict restait EQUIVALENT sur MOINS de choses. `NO_MATCH` ne
    # tirait que si l'intersection etait VIDE -- donc jamais dans le cas partiel.
    #
    # Mesure qui l'a montre (arith_01_simple_compute, un seul champ renomme):
    #     temoin                    EQUIVALENT, 5 obligations
    #     sortie ws_sum renommee    EQUIVALENT, 4 obligations  <- WS-SUM disparait
    #     entree ws_num_a renommee  NON-EQUIVALENT, 5 REFUTED
    # Recensement sur 60 programmes du banc: 54 appels ou obligations == sorties,
    # 1 a intersection vide (NO_MATCH correct), **0 perte partielle**. Le defaut est
    # donc LATENT sur notre propre Python -- qui nomme toujours pareil -- et se
    # declenche sur une traduction TIERCE, c'est-a-dire exactement le cas qui
    # differencie le produit.
    #
    # Un certificat rendrait ca LISIBLE; il ne rendrait pas le vert correct. Le vert
    # doit devenir impossible: chaque sortie non appariee porte son propre NO_MATCH.
    non_appariees = sorted(set(cobol_outputs) - set(py_upper))

    results = [ProofResult(
        status="NO_MATCH", output_var=var,
        details=(f"Sortie {left_label} sans contrepartie {right_label} — non verifiee. "
                 f"Le verdict ne peut pas etre EQUIVALENT tant qu'elle manque."))
        for var in non_appariees]

    # LE COMPLEMENT DE L'AUTRE COTE. Une traduction qui ecrit une variable que le
    # modele source ne connait pas etait ignoree en SILENCE. Mesure: un Python avec
    # `ws_intrus = ws_num_a * 999` en plus -> EQUIVALENT, 5 obligations, rien de dit.
    # Recensement du banc (60 programmes): 8 appels sur 55 exposent des sorties en
    # trop, 24 au total -- TOUS avec zero sortie source, donc deja NO_MATCH. Le cas
    # « vert qui cache une intruse » n'existe pas sur NOTRE generateur; il existe sur
    # une traduction tierce, comme le defaut symetrique.
    # FAIL-CLOSED : le seau NON BLOQUANT n'est accessible QUE si l'appelant a fourni
    # le discriminant. Sans `source_vars`, on ne peut pas distinguer « la traduction
    # l'a inventee » (portee) de « la source l'ecrit et nous ne l'avons pas modelisee »
    # (trou). On refuse alors le seau vert et on bloque, en le DISANT.
    _sans_contrepartie = sorted(set(py_upper) - set(cobol_outputs) - unverified
                                - source_vars)
    if _source_vars_inconnu:
        results += [ProofResult(
            status="CABLAGE_ABSENT", output_var=var,
            details=(f"Sortie {right_label} sans contrepartie {left_label}, et "
                     f"l'appelant n'a fourni AUCUN `source_vars` : impossible de "
                     f"distinguer une variable inventee par la traduction d'une "
                     f"variable que {left_label} ecrit sans que nous l'ayons "
                     f"modelisee. Le seau non bloquant exige le discriminant."))
            for var in _sans_contrepartie]
    else:
        results += [ProofResult(
            status="HORS_PERIMETRE", output_var=var,
            details=(f"Sortie {right_label} sans contrepartie {left_label} — la traduction "
                     f"ecrit cette variable, le modele source ne la connait pas. Hors du "
                     f"perimetre verifie: « equivalent » vaut sur les sorties du modele, "
                     f"pas sur toute la traduction."))
            for var in _sans_contrepartie]

    # Connue de la SOURCE mais absente de `cobol_outputs` : ce n'est pas une portee,
    # c'est un trou de modelisation. Bloque, sans accuser.
    results += [ProofResult(
        status="NON_VERIFIE", output_var=var,
        details=(f"Le programme {left_label} CONNAIT cette variable, mais notre "
                 f"encodeur ne l'a pas modelisee. Ce n'est pas une declaration de "
                 f"portee : le verdict ne peut pas etre EQUIVALENT tant qu'elle "
                 f"n'est pas couverte."))
        for var in sorted((set(py_upper) & source_vars) - set(cobol_outputs)
                          - unverified)]

    # LES SORTIES QUE L'ENCODEUR A REFUSE DE MODELISER. Le COBOL les calcule ; c'est
    # NOUS qui ne savons pas les lire. Ce n'est PAS une declaration de portee, et ca
    # BLOQUE. Emis pour CHACUNE, y compris celles absentes du Python -- sinon
    # l'obligation disparait des deux cotes et devient invisible.
    if _discriminants_absents:
        results.append(ProofResult(
            status="CABLAGE_ABSENT", output_var="(cablage)",
            details=("Ce site d'appel ne fournit pas : %s. La COMPLETUDE de l'ensemble "
                     "d'obligations est donc inconnue -- on ne peut pas savoir si "
                     "l'encodeur a abandonne des sorties, si une cible d'ecriture est "
                     "invalide, ni si un domaine libre vient de la source ou de notre "
                     "lecture. Bloque sans accuser."
                     % ", ".join(_discriminants_absents))))

    results += [ProofResult(
        status="NON_VERIFIE", output_var=var,
        details=(f"Sortie {left_label} RETIREE par l'encodeur (instruction non "
                 f"modelisee ou calcul echoue en amont). Le modele source la calcule ; "
                 f"nous refusons de l'affirmer. Le verdict ne peut pas etre EQUIVALENT "
                 f"tant qu'elle n'est pas modelisee."))
        for var in sorted(unverified)]
    for var in sorted(shared):
        s = Solver()
        s.set("timeout", timeout_ms)
        # LES NOMS REELLEMENT CONTRAINTS. Sans cet ensemble, un contre-exemple ne
        # peut pas etre distingue d'un contre-exemple TROUVE HORS DU DOMAINE REEL.
        bornes: set = set()
        # MINOREES SEULEMENT : `x >= 0` pose, aucune borne superieure. Ne compte pas
        # comme contraint (un temoin peut sieger arbitrairement haut, hors de tout PIC
        # reel), mais se DIT autrement que « aucune borne du tout ».
        _minorees: set = set()
        if variables:
            bornes = _apply_pic_input_bounds(s, input_vars, variables)
        elif bounds:
            # Deterministic assertion order (TOR-DET-1): sort by variable name.
            for ivar, (lo, hi) in sorted(bounds.items(), key=lambda kv: kv[0]):
                z3v = input_vars.get(ivar)
                if z3v is None:
                    z3v = input_vars.get(ivar.upper())
                if z3v is not None:
                    s.add(z3v >= RealVal(str(lo)))
                    s.add(z3v <= RealVal(str(hi)))
                    bornes.add(ivar.upper())
                    bornes.add(_nom_symbole(z3v, ivar))
        else:
            # Deterministic assertion order (TOR-DET-1): sort by variable name.
            for _k in sorted(input_vars):
                s.add(input_vars[_k] >= RealVal(0))
                # ⚠️ `>= 0` n'est PAS un domaine : il n'a pas de borne superieure et il
                # est FAUX d'un PIC S9(n). Il ne compte pas comme « contraint ».
                # MAIS ce n'est pas non plus « aucune borne » : deux etats qui bloquent
                # pour des raisons DISTINCTES, et les confondre a l'impression est le
                # canal trop etroit. On les separe (2026-08-27, sur remarque de l'auteur).
                _minorees.add(_k.upper())
                _minorees.add(_nom_symbole(input_vars[_k], _k))

        s.add(cobol_outputs[var] != py_upper[var])
        # Self-contained SMT-LIB2 of the refutation query (declarations + assertions +
        # check-sat): UNSAT means equivalence, and any independent solver can re-check it.
        try:
            obligation_smt2 = s.to_smt2()
        except Exception:
            obligation_smt2 = None
        t0 = time.time()
        check = s.check()
        elapsed = (time.time() - t0) * 1000

        if check == unsat:
            results.append(ProofResult(status="PROVED", output_var=var,
                                       proof_time_ms=elapsed, smt2=obligation_smt2,
                                       details="Z3 UNSAT — équivalence prouvée ∀ input."))
        elif check == sat:
            model = s.model()
            cx = {str(d): str(model[d]) for d in model.decls()}
            try:
                c_str = model.eval(cobol_outputs[var]).as_decimal(4).rstrip("?")
                p_str = model.eval(py_upper[var]).as_decimal(4).rstrip("?")
                _w = max(len(left_label), len(right_label)) + len(var) + 3
                _lbl_l = f"{left_label}({var})".ljust(_w)
                _lbl_r = f"{right_label}({var})".ljust(_w)
                _lbl_e = "Écart".ljust(_w)
                details = (f"Z3 SAT — contre-exemple trouvé!\n"
                           f"  {_lbl_l}= {c_str}\n"
                           f"  {_lbl_r}= {p_str}\n"
                           f"  {_lbl_e}= {str(simplify(model.eval(cobol_outputs[var]) - model.eval(py_upper[var])))}")
            except Exception:
                details = f"Z3 SAT — contre-exemple: {cx}"
            # ⛔ LE GATE DE SOLIDITE. Prouver ∀ sur un SUR-ENSEMBLE du domaine reel
            # implique l'equivalence sur le domaine reel : `PROVED` est conservateur,
            # donc defendable. L'implication ne tient PAS dans l'autre sens -- un
            # temoin trouve dans le sur-ensemble peut ne pas exister dans le programme
            # reel. Une refutation dont le contre-exemple assigne un symbole NON
            # CONTRAINT accuse le client sur une valeur qu'il ne peut pas contenir.
            # Mesure fondatrice : dscobol_021_bds1001, `valueofsale = -1` sur un
            # `PIC 9(4)V99` non signe -- seule accusation du corpus, indefendable.
            # Elle DEGRADE, elle ne disparait pas : le statut bloque sans accuser, et
            # nomme les symboles libres pour qu'on sache quoi contraindre.
            # ⚠️ NE PAS LIRE LE CONTRE-EXEMPLE POUR DECIDER. Z3 rend un modele
            # MINIMAL : sur `x != x + 1`, la contrainte est vraie partout, donc aucune
            # assignation n'est necessaire et `cx` sort VIDE. Un gate qui inspecte `cx`
            # laisse alors passer l'accusation -- il depend de ce que le solveur a
            # daigne ecrire, pas de ce qu'on sait du domaine. Mesure : 2 temoins sur 8
            # (variable sans PIC, PIC alphanumerique) sortaient REFUTED.
            # On lit les symboles DONT L'OBLIGATION DEPEND, ce qui ne depend d'aucun
            # modele. Sur-conservateur par construction, et c'est le bon cote :
            # s'abstenir de trop plutot qu'accuser a tort.
            # ⛔ MODELE CORROMPU : le gate de domaine ne peut pas voir ce cas-la.
            # `gnucobol_704` est un programme FERME (aucun symbole libre), donc
            # `_libres` est vide et l'accusation passait. Ce qui la rend indefendable
            # n'est pas son domaine, c'est que le modele source n'est pas le programme.
            if cibles_invalides:
                results.append(ProofResult(
                    status="MODELE_CORROMPU", output_var=var,
                    counterexample=cx, proof_time_ms=elapsed,
                    details=("Divergence trouvee, mais le modele SOURCE porte %d cible(s) "
                             "d'ecriture qui ne sont pas des variables declarees : %s. "
                             "Le parseur a ramasse le mauvais jeton -- une divergence "
                             "entre deux artefacts dont l'un est corrompu par NOUS ne dit "
                             "rien de la traduction. Contre-exemple conserve pour "
                             "diagnostic : %s"
                             % (len(cibles_invalides),
                                ", ".join(sorted(cibles_invalides)[:6]), cx))))
                continue
            _sym = _symboles_libres(cobol_outputs[var]) | _symboles_libres(py_upper[var])
            _sym |= {n.upper() for n in cx}
            _libres = sorted(n for n in _sym
                             if n not in bornes and n != var.upper())
            if _libres:
                _pic = {n.upper() for n in (pic_declares or set())}
                _a_pic = [n for n in _libres if n in _pic]
                _statut = ("ENCODAGE_INCOMPLET" if _a_pic and len(_a_pic) == len(_libres)
                           else "DOMAINE_LIBRE")
                _jamais = ("[vrais_positifs: 0 sur 2345 — ce statut n'a JAMAIS ete "
                           "emis pour une vraie limite sur ce corpus. Ses deux seules "
                           "occurrences (gnucobol_535/536) portaient `E`, une constante "
                           "intrinseque GnuCOBOL que NOUS ne modelisons pas. Ne pas le "
                           "lire comme une limite fondamentale rencontree.] "
                           if _statut == "DOMAINE_LIBRE" else "")
                _pref = _jamais + ("Le domaine EST dans la source et NOUS ne l'avons pas lu : %s "
                         "porte(nt) une clause PIC numerique declaree (typiquement un "
                         "champ d'enregistrement sous un FD, que le parseur ecarte). "
                         "C'est un defaut REPARABLE de notre encodeur, pas une limite. "
                         % ", ".join(_a_pic)) if _statut == "ENCODAGE_INCOMPLET" else ""
                _min = [n for n in _libres if n in _minorees]
                _rien = [n for n in _libres if n not in _minorees]
                _detail_etats = ""
                if _min and _rien:
                    _detail_etats = (" Deux etats distincts : %s minoree(s) seulement "
                                     "(`>= 0`, aucune borne superieure) ; %s sans aucune "
                                     "borne. " % (", ".join(_min[:4]), ", ".join(_rien[:4])))
                elif _min:
                    _detail_etats = (" Etat : minoree(s) seulement (`>= 0`, aucune borne "
                                     "superieure) -- ce n'est PAS « aucune borne ». ")
                results.append(ProofResult(
                    status=_statut, output_var=var,
                    counterexample=cx, proof_time_ms=elapsed,
                    details=(_pref + _detail_etats + "Contre-exemple trouve, mais HORS d'un domaine d'entree "
                             "etabli : %s n'a/n'ont recu aucune borne (absent(s) de la "
                             "DATA DIVISION, sans PIC, ou PIC alphanumerique). Le temoin "
                             "peut ne pas exister dans le programme reel -- on ne "
                             "l'affirme pas. Contre-exemple conserve pour diagnostic : "
                             "%s" % (", ".join(_libres), cx))))
            else:
                results.append(ProofResult(status="REFUTED", output_var=var,
                                           counterexample=cx, proof_time_ms=elapsed,
                                           details=details))
        else:
            results.append(ProofResult(status="UNKNOWN", output_var=var,
                                       proof_time_ms=elapsed, details="Z3 timeout"))
    return results


# ─────────────────────────────────────────────────────────────────────────────
# 5. Claude API Translation
# ─────────────────────────────────────────────────────────────────────────────

def _extract_python_from_response(text: str) -> str:
    for pat in [r"```python\n(.*?)```", r"```\n(.*?)```"]:
        m = re.search(pat, text, re.DOTALL)
        if m:
            return m.group(1).strip()
    return text.strip()


def _get_anthropic_client() -> "anthropic.Anthropic":
    if not _ANTHROPIC_OK:
        raise RuntimeError("Module 'anthropic' non installé")
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        raise RuntimeError("ANTHROPIC_API_KEY non définie")
    return anthropic.Anthropic(api_key=api_key)


def translate_with_claude(cobol_src: str) -> str:
    client = _get_anthropic_client()
    prompt = f"""Expert COBOL→Python migration. Translate exactly. Rules:
- Single function named after PROGRAM-ID (snake_case)
- All variables use Decimal for numeric types
- Preserve exact conditions (<=, <, etc.)
- Use same variable names (lowercase)
- No comments, no imports

COBOL:
```
{cobol_src}
```
Python only, no explanation."""
    msg = client.messages.create(model="claude-opus-4-7", max_tokens=2048,
                                 messages=[{"role": "user", "content": prompt}])
    return _extract_python_from_response(msg.content[0].text)


@dataclass
class FeedbackLoopResult:
    final_python: str
    iterations: int
    proved: bool
    history: List[Dict[str, Any]]


def translate_with_feedback_loop(
    cobol_src: str,
    program: IronproofProgram,
    cobol_inputs: Dict[str, Any],
    cobol_outputs: Dict[str, Any],
    max_iterations: int = 3,
    verbose: bool = True,
    unverified: Optional[set] = None,
) -> FeedbackLoopResult:
    client = _get_anthropic_client()
    history: List[Dict[str, Any]] = []

    prompt = f"""Expert COBOL→Python migration. Translate exactly. Rules:
- Single function named after PROGRAM-ID (snake_case)
- All variables use Decimal for numeric types
- Preserve exact conditions (<=, <, etc.)
- Use same variable names (lowercase)
- No comments, no imports

COBOL:
```
{cobol_src}
```
Python only, no explanation."""

    messages = [{"role": "user", "content": prompt}]

    for iteration in range(1, max_iterations + 1):
        if verbose:
            print(f"  [Feedback Loop {iteration}/{max_iterations}]  Traduction LLM...")

        msg = client.messages.create(
            model="claude-opus-4-7", max_tokens=2048, messages=messages
        )
        python_src = _extract_python_from_response(msg.content[0].text)

        if verbose:
            print(f"  [Feedback Loop {iteration}/{max_iterations}]  Vérification Z3...")

        provable = {k: v for k, v in cobol_outputs.items() if is_expr(v)}
        python_outputs = _build_python_z3(python_src, cobol_inputs)
        bounds = {v: (0.0, 10_000_000.0) for v in cobol_inputs}
        results = prove_equivalence(provable, python_outputs, cobol_inputs, bounds=bounds,
                                    unverified=unverified)
        results += _obligation_smoke(python_src)

        all_proved = bool(results) and all(r.proved for r in results)
        refuted = [r for r in results if r.status == "REFUTED"]

        history.append({
            "iteration": iteration,
            "python_src": python_src,
            "proved": all_proved,
            "results": [{"var": r.output_var, "status": r.status,
                         "counterexample": r.counterexample, "details": r.details}
                        for r in results],
        })

        if all_proved:
            if verbose:
                print(f"  [Feedback Loop {iteration}/{max_iterations}]  ✅ Équivalence prouvée!")
            return FeedbackLoopResult(
                final_python=python_src, iterations=iteration,
                proved=True, history=history,
            )

        if iteration == max_iterations:
            if verbose:
                print(f"  [Feedback Loop {iteration}/{max_iterations}]  ❌ Max itérations — non prouvé")
            return FeedbackLoopResult(
                final_python=python_src, iterations=iteration,
                proved=False, history=history,
            )

        cx_details = []
        for r in refuted:
            cx_details.append(
                f"Variable {r.output_var}: {r.details}"
                + (f"\n  Counterexample inputs: {r.counterexample}" if r.counterexample else "")
            )
        cx_text = "\n".join(cx_details)

        if verbose:
            print(f"  [Feedback Loop {iteration}/{max_iterations}]  ❌ Z3 réfuté — envoi contre-exemple au LLM")

        correction_prompt = f"""Your COBOL→Python translation has a semantic bug.

The Z3 SMT solver found a counterexample proving the COBOL and Python produce different outputs:

{cx_text}

Original COBOL:
```
{cobol_src}
```

Your buggy Python:
```python
{python_src}
```

Fix the Python translation so it is semantically equivalent to the COBOL. Pay close attention to:
- Boundary conditions (<=, <, >=, >)
- Operator precedence
- Decimal precision
- Variable initialization

Return ONLY the corrected Python code, no explanation."""

        messages = [
            {"role": "user", "content": prompt},
            {"role": "assistant", "content": f"```python\n{python_src}\n```"},
            {"role": "user", "content": correction_prompt},
        ]

    return FeedbackLoopResult(
        final_python=python_src, iterations=max_iterations,
        proved=False, history=history,
    )


# ─────────────────────────────────────────────────────────────────────────────
# 6. Certificate + Pipeline
# ─────────────────────────────────────────────────────────────────────────────

_IDENTITE_CACHE: Dict[str, Any] = {}


def _identite_producteur() -> Dict[str, Any]:
    """Qui a produit ce certificat : solveur AVEC sa version, et empreinte du code.

    Un certificat sans identite de producteur n'est pas re-derivable, et deux
    certificats de part et d'autre d'un correctif sont indiscernables. L'empreinte
    est celle du FICHIER source qui emet -- re-calculable par un tiers, sans git."""
    if _IDENTITE_CACHE:
        return dict(_IDENTITE_CACHE)
    try:
        import z3 as _z3
        version = _z3.get_version_string()
    except Exception:
        version = "indisponible"
    try:
        with open(os.path.abspath(__file__), "rb") as fh:
            empreinte = hashlib.sha256(fh.read()).hexdigest()
    except Exception:
        empreinte = "indisponible"
    _IDENTITE_CACHE.update({
        "solver": {"name": "z3", "version": version},
        "encoder": {"name": "ironproof_core.py",
                    "source_sha256": empreinte,
                    "certificate_format": "4.0"},
        "note": ("Re-derivation : meme version de solveur ET meme empreinte "
                 "d'encodeur, sinon les deux certificats ne sont pas comparables."),
    })
    return dict(_IDENTITE_CACHE)



# ── LE COMPTEUR DE PORTEE ─────────────────────────────────────────────────────
# Cinq formes de vacuite trouvees le 2026-08-26, toutes de la MEME famille : un
# PROVED syntaxiquement correct dont le CONTENU est nul. `_assumable`, `__inK`,
# domaine vide, preuve orthogonale au domaine, portee qui couvre un trou. Chaque
# fois attrapee APRES COUP, a la main, par un cas particulier.
#
# LA REGLE QUI EN SORT, ecrite une fois : un verdict favorable doit porter la
# MESURE DE CE SUR QUOI IL PORTE, sinon il mesure zero sans le dire. Ce qui
# manquait n'est pas un compte d'obligations -- c'est une mesure d'ETENDUE :
# combien de comportement la preuve couvre effectivement.
#
# Tant que ce compteur n'existe pas, la SIXIEME forme est deja dans le corpus et
# personne ne la verra. C'est une propriete du verdict, pas un lot a traiter.


def _sorties_reelles(program) -> set:
    """Les variables que le programme SOURCE ecrit vraiment -- ses sorties.

    Derive du programme, jamais redige : une liste ecrite a la main serait un
    miroir non garde de plus."""
    ecrites: set = set()
    blocs = list(getattr(program, "paragraphs", {}).values())
    corps = getattr(program, "body", None) or []

    def _visite(stmts):
        for st in stmts or []:
            for a in ("target", "giving", "into_var", "returning_var", "remainder",
                      "varying_var"):
                v = getattr(st, a, None)
                if isinstance(v, str) and v:
                    ecrites.add(v.upper())
            for a in ("targets", "into_vars"):
                v = getattr(st, a, None)
                if isinstance(v, (list, tuple)):
                    ecrites.update(x.upper() for x in v if isinstance(x, str))
            for a in ("then_stmts", "else_stmts", "inline_stmts", "at_end_stmts",
                      "other_stmts"):
                _visite(getattr(st, a, None))
            for wc in getattr(st, "when_clauses", None) or []:
                _visite(getattr(wc, "stmts", None))

    for b in blocs:
        _visite(getattr(b, "stmts", None))
    _visite(corps)
    # une sortie est une variable DECLAREE et NUMERIQUE : le reste n'est pas
    # modelisable de toute facon, et le compter gonflerait le denominateur.
    declarees = {n.upper() for n, v in getattr(program, "variables", {}).items()
                 if getattr(v, "pic", None) and not v.pic.is_alpha}
    return ecrites & declarees


_RE_NIVEAU_PIC = re.compile(r"^\s*(0?[1-9]|[1-4]\d)\s+[A-Za-z0-9-]+.*?\bPIC\b",
                            re.M | re.I)


def _denominateur_incomplet(program, source: str = "") -> Dict[str, Any]:
    """Le compteur declare SON PROPRE angle mort.

    `_sorties_reelles` s'appuie sur `program.variables`. Or le parseur ne collecte
    pas les champs d'enregistrement d'un FD : dscobol_075_ods0004 rendait
    `couverture = 1/1` alors que ses 10 sorties de rapport (ACCT-BALANCE-O,
    LAST-NAME-O, PRINT-REC...) existent et sont ecrites. Un ratio calcule contre un
    denominateur qu'on ne voit pas est OPTIMISTE -- et un compteur de portee qui se
    tait sur sa propre portee serait la sixieme forme du defaut qu'il existe pour
    fermer."""
    if not source:
        return {"checked": False,
                "note": "source non transmise -- l'exhaustivite du denominateur "
                        "n'a PAS ete verifiee (ce n'est pas un feu vert)"}
    declarees_source = len(_RE_NIVEAU_PIC.findall(source))
    vues = len(getattr(program, "variables", {}) or {})
    # ⚠️ TROIS ETATS, pas deux. Un `max(0, source - parse)` imprimait « complet »
    # quand mon propre scan trouvait MOINS que le parseur -- c'est-a-dire quand le
    # scan est CASSE. Un controle qui ne peut dire que « tout va bien » est une
    # decoration, et c'aurait ete la sixieme forme du defaut, dans le compteur
    # cense la fermer. Mesure : nist_045_ic202a -> source=0, parse=6.
    if declarees_source < vues:
        return {"checked": True, "declared_in_source": declarees_source,
                "parsed": vues, "missing": None, "incomplete": None,
                "reliable": False,
                "note": ("SCAN NON FIABLE : le balayage de la source trouve %d "
                         "declaration(s) a clause PIC alors que le parseur en a %d. "
                         "Le denominateur de `coverage` n'a PAS pu etre verifie -- "
                         "ce n'est pas un feu vert." % (declarees_source, vues))}
    _rd = _ratio.mesurer(vues, declarees_source, "declarations a clause PIC")
    manquantes = _rd.manquants
    return {"checked": True, "reliable": True,
            "declared_in_source": declarees_source,
            "parsed": vues,
            "missing": manquantes,
            "incomplete": manquantes > 0,
            "note": ("Le parseur ne voit PAS %d declaration(s) a clause PIC presentes "
                     "dans la source (typiquement des champs d'enregistrement FD). "
                     "Le denominateur de `coverage` est donc TROP PETIT, et le ratio "
                     "OPTIMISTE." % manquantes) if manquantes else
                    "Toutes les declarations a clause PIC de la source sont parsees."}


# ⚠️ LISTE INDEPENDANTE DU PARSEUR, ET C'EST VOULU. Reutiliser `_STMT_KEYWORDS`
# rendrait le compteur CIRCULAIRE : il mesurerait ce que le parseur cherche, jamais ce
# que le COBOL contient -- donc il resterait vert sur les sept amputations qu'il existe
# pour attraper. Meme choix que `_RE_NIVEAU_PIC` pour la DATA DIVISION. Le prix est un
# angle mort, declare plus bas.
_VERBES_COBOL = (
    "ACCEPT|ADD|ALTER|CALL|CANCEL|CLOSE|COMPUTE|CONTINUE|DELETE|DISPLAY|DIVIDE|"
    "ENTRY|EVALUATE|EXEC|EXHIBIT|EXIT|GENERATE|GO|GOBACK|IF|INITIALIZE|INITIATE|"
    "INSPECT|MERGE|MOVE|MULTIPLY|OPEN|PERFORM|READ|RELEASE|RETURN|REWRITE|SEARCH|"
    "SET|SORT|START|STOP|STRING|SUBTRACT|TERMINATE|UNSTRING|WRITE"
)
_RE_VERBE = re.compile(r"(?:^|\s)(%s)(?=\s|\.|$)" % _VERBES_COBOL)


def _compte_stmts_ir(program) -> int:
    """Les instructions REELLEMENT dans l'IR, imbrications comprises."""
    total = [0]

    def _visite(lst):
        for st in lst or []:
            total[0] += 1
            for a in ("then_stmts", "else_stmts", "inline_stmts", "at_end_stmts",
                      "other_stmts"):
                _visite(getattr(st, a, None))
            for wc in getattr(st, "when_clauses", None) or []:
                _visite(getattr(wc, "stmts", None))

    for para in (getattr(program, "paragraphs", {}) or {}).values():
        _visite(getattr(para, "stmts", None))
    _visite(getattr(program, "body", None))
    return total[0]


_RE_VERBE_CIBLE = re.compile(r"\b(ADD|SUBTRACT|MULTIPLY|DIVIDE|MOVE|COMPUTE)\b", re.I)


# Registres speciaux COBOL : ecrire dedans est LEGITIME et ils ne sont jamais declares
# en WORKING-STORAGE. Les compter comme corruption produisait 120 faux positifs sur 81
# programmes (mesure 2026-08-26).
_REGISTRES_SPECIAUX = {
    "RETURN-CODE", "GOBACK", "TALLY", "SORT-RETURN", "SORT-STATUS", "SORT-FILE-SIZE",
    "SORT-CORE-SIZE", "SORT-MODE-SIZE", "LINAGE-COUNTER", "WHEN-COMPILED",
    "COB-CRT-STATUS", "NUMBER-OF-CALL-PARAMETERS", "XML-CODE", "JSON-CODE",
    "DEBUG-ITEM", "EXIT", "STOP", "CONTINUE",
}


def ventile_cibles(program, source: str = "") -> Dict[str, set]:
    """Les cibles d'ecriture non declarees, en TROIS seaux — « non declaree » en
    melangeait trois, et le melange rendait le garde inutilisable dans un sens.

      `registre`  registre special COBOL — LEGITIME, ne bloque rien.
      `non_lue`   nom a clause PIC ailleurs dans la source (typiquement champ FD) :
                  le programme l'ECRIT et nous ne l'avons pas modelise -> NON_VERIFIE.
      `corrompue` ni l'un ni l'autre : le parseur a ramasse le mauvais jeton
                  (`'CBLACK,'`, `TO`, `(SUB)`, `OF`) -> MODELE_CORROMPU.

    Mesure 2026-08-26 sur 2345 : registre 120 occ / 81 progs · non_lue 130 / 60 ·
    corrompue 2090 / 380."""
    pics = pic_declares_dans_la_source(source)
    out = {"registre": set(), "non_lue": set(), "corrompue": set()}
    for x in cibles_non_declarees(program):
        u = x.upper().rstrip(",.").split("(")[0].strip()
        if u in _REGISTRES_SPECIAUX:
            out["registre"].add(x)
        elif u in pics:
            out["non_lue"].add(x)
        else:
            out["corrompue"].add(x)
    return out


def cibles_perdues(program, source: str = "") -> set:
    """Les noms que la SOURCE designe comme cibles d'ecriture et qui n'apparaissent
    NULLE PART comme cible dans l'IR.

    ⛔ LA 12e FORME (2026-08-26). `MODELE_CORROMPU` bloque une ACCUSATION ; il ne
    bloquait pas un `EQUIVALENT` reposant sur la MEME corruption. Or une cible perdue
    rend l'equivalence **plus facile** a prouver : le gate tirait dans le sens
    desagreable et se taisait dans le sens agreable — l'asymetrie exacte que toute la
    serie existe pour fermer. Mesure : **24 des 566 `EQUIVALENT`** (14 par corruption
    visible du nom, 10 par perte silencieuse).

    Le mecanisme n'invente RIEN : une cible ecrite par le programme et absente de l'IR
    est **une sortie que le COBOL ECRIT et que nous n'avons pas modelisee**, donc
    `NON_VERIFIE`, qui bloque deja. On alimente `unverified`, le verdict degrade seul.

    Le releve est un balayage SOURCE independant du parseur (sinon circulaire). Il
    sur-bloque plutot que de sous-bloquer -- direction sure."""
    if not source:
        return set()
    lignes = IronproofParser()._normalize(source)
    debut = next((k for k, l in enumerate(lignes)
                  if re.match(r"^PROCEDURE\s+DIVISION", l)), None)
    if debut is None:
        return set()
    nommees = set()
    for l in lignes[debut + 1:]:
        if _RE_VERBE_CIBLE.search(l):
            nommees.update(noms_cibles_source(l))
    dans_ir = set()

    def _visite(lst):
        for st in lst or []:
            for a in _CIBLES_IR.get(type(st).__name__, ()):
                v = getattr(st, a, None)
                for x in (v if isinstance(v, list) else [v]):
                    if isinstance(x, str) and x:
                        dans_ir.add(x.upper().rstrip(",.").split("(")[0].strip())
            for a in ("then_stmts", "else_stmts", "inline_stmts", "at_end_stmts",
                      "other_stmts"):
                _visite(getattr(st, a, None))
            for wc in getattr(st, "when_clauses", None) or []:
                _visite(getattr(wc, "stmts", None))

    for para in (getattr(program, "paragraphs", {}) or {}).values():
        _visite(getattr(para, "stmts", None))
    _visite(getattr(program, "body", None))
    # ⚠️ TROISIEME RETRECISSEMENT DE CE GARDE, mesure avant d'etre corrige. Filtrer sur
    # `program.variables` seul excluait exactement la population principale : les champs
    # d'enregistrement sous un FD (`SORTFILE-CUSTOMER-RECORD`, `OUTFILE-...`), que
    # `_parse_data_division` ecarte. Resultat du premier cablage : **6 EQUIVALENT
    # bloques sur les 24 mesures, dont 3 des 14 a corruption visible**.
    # Le bon discriminant existe deja et lit la FILE SECTION : « ce nom porte-t-il une
    # clause PIC numerique QUELQUE PART dans la source ». Il exclut le bruit de mon
    # balayage (mots ramasses a tort apres `TO`) sans exclure les vraies sorties.
    declarees = {n.upper() for n in (getattr(program, "variables", {}) or {})}
    declarees |= pic_declares_dans_la_source(source)
    return (nommees & declarees) - dans_ir


import ratio_valide as _ratio  # la primitive du denominateur nul, 3e usage


def _compte_cibles_ir(program) -> int:
    n = [0]

    def _visite(lst):
        for st in lst or []:
            n[0] += _cibles_ir(st)
            for a in ("then_stmts", "else_stmts", "inline_stmts", "at_end_stmts",
                      "other_stmts"):
                _visite(getattr(st, a, None))
            for wc in getattr(st, "when_clauses", None) or []:
                _visite(getattr(wc, "stmts", None))

    for para in (getattr(program, "paragraphs", {}) or {}).values():
        _visite(getattr(para, "stmts", None))
    _visite(getattr(program, "body", None))
    return n[0]


def couverture_parse(program, source: str = "") -> Dict[str, Any]:
    """Ce que le PARSEUR rend de la source -- l'etage sous `couverture_preuve`.

    Sept amputations de parseur ont ete trouvees en 24 h, TOUTES par un verdict en
    aval qui detonnait. Aucune n'etait visible en relisant le code, et aucun compteur
    ne les portait : du source non parse est une entree INVISIBLE, meme classe qu'une
    portee non mesuree. Ce compteur les rend visibles par construction.

    TROIS ETATS, jamais deux -- et c'est le troisieme qui porte tout le poids :
      NON_FIABLE  le balayage source n'a rien pu mesurer, ou trouve MOINS que le
                  parseur. `PROCEDURE    DIVISION.` (plusieurs espaces) tombe ici :
                  le parseur ne voit aucune division procedure, 1009 programmes du
                  banc sur 2345 rendent `paragraphes: [], body: []`. « Rien recu »
                  n'est PAS « rien trouve ».
      INCOMPLET   des verbes de la source n'ont pas d'instruction dans l'IR.
      COMPLET     autant d'instructions que de verbes vus.

    ANGLE MORT DECLARE (A4) : le balayage compte des VERBES sur des lignes
    normalisees. Il sur-compte un verbe apparaissant dans un litteral alphanumerique
    ou dans un commentaire en ligne, et sous-compte un verbe porte par une ligne de
    continuation. Il ne dit donc pas « le parseur est correct » -- il dit « le
    parseur rend N pour M », et un ecart merite d'etre regarde."""
    if not source:
        return {"checked": False, "reliable": False, "etat": "NON_FIABLE",
                "note": "source non transmise -- la couverture de parse n'a PAS ete "
                        "mesuree (ce n'est pas un feu vert)"}
    lignes = IronproofParser()._normalize(source)
    debut = next((k for k, l in enumerate(lignes)
                  if re.match(r"^PROCEDURE\s+DIVISION", l)), None)
    if debut is None:
        return {"checked": True, "reliable": False, "etat": "NON_FIABLE",
                "verbes_source": None, "stmts_ir": _compte_stmts_ir(program),
                "note": "Aucune PROCEDURE DIVISION trouvee dans la source normalisee. "
                        "Le denominateur n'existe pas -- rien n'est conclu."}
    verbes = sum(len(_RE_VERBE.findall(l)) for l in lignes[debut + 1:])
    stmts = _compte_stmts_ir(program)
    # Le parseur voit-il seulement la division ? Le test du parseur est
    # `"PROCEDURE DIVISION" in line` -- UNE espace ; la source peut en porter
    # plusieurs, et alors la division entiere est invisible.
    # MIROIR GARDE, pas decoration. Le balayage ci-dessus (`^PROCEDURE\s+DIVISION`)
    # est INDEPENDANT du test du parseur ; ce branchement est l'obligation qui echoue
    # quand les deux faces divergent. Elles s'accordent depuis le correctif de
    # normalisation, donc il est MUET aujourd'hui -- ce qui est le bon comportement
    # sur un etat sain, et se prouve par mutation (test_le_garde_de_divergence_tire).
    vue_du_parseur = any(IronproofParser._entete(l, "PROCEDURE", "DIVISION")
                         for l in lignes)
    if not vue_du_parseur:
        return {"checked": True, "reliable": False, "etat": "NON_FIABLE",
                "verbes_source": verbes, "stmts_ir": stmts,
                "note": ("La source declare une PROCEDURE DIVISION (%d verbe(s)) que le "
                         "parseur NE VOIT PAS : sa detection exige une espace unique. "
                         "La division procedure entiere est absente de l'IR." % verbes)}
    if verbes < stmts:
        return {"checked": True, "reliable": False, "etat": "NON_FIABLE",
                "verbes_source": verbes, "stmts_ir": stmts,
                "note": ("SCAN NON FIABLE : %d verbe(s) balaye(s) dans la source pour "
                         "%d instruction(s) dans l'IR. Mon balayage trouve MOINS que le "
                         "parseur -- il est casse, et rien n'est conclu."
                         % (verbes, stmts))}
    # ⚠️ DENOMINATEUR NUL. `verbes == 0` donnait `manquants = 0`, donc **COMPLET sur
    # du vide** -- « rien recu » imprime comme « rien trouve », et c'est EXACTEMENT le
    # `max(0, source - parse)` que `_denominateur_incomplet` a du corriger la veille.
    # La faute s'est reproduite dans le compteur ecrit pour la fermer, et c'est l'auteur qui
    # l'a trouvee en une question, pas le banc. Une division procedure sans un seul
    # verbe est degeneree : on ne conclut pas.
    if verbes == 0:
        return {"checked": True, "reliable": False, "etat": "NON_FIABLE",
                "verbes_source": 0, "stmts_ir": stmts,
                "note": ("Denominateur NUL : aucun verbe COBOL balaye dans la division "
                         "procedure. Il n'y a rien contre quoi mesurer -- ce n'est pas "
                         "une couverture complete, c'est une absence de mesure.")}
    _rv = _ratio.mesurer(stmts, verbes, "verbes COBOL")
    manquants = _rv.manquants
    # ⚠️ LA PERTE DE CIBLES, DANS LA VALEUR DU VERDICT. 19 des 24 `EQUIVALENT` a cible
    # perdue sont BLOQUES (`MODELE_CORROMPU` ou `NON_VERIFIE`) ; les 5 restants portent
    # une perte dont le NOM n'est pas resolvable par le balayage source, donc rien ne
    # peut alimenter `unverified`. Pour ceux-la, le verdict doit porter la perte lui-meme
    # -- un `EQUIVALENT` ne doit pas pouvoir s'imprimer sans le compte de ce qui manque.
    _cibles_src = sum(cibles_source(l) for l in lignes[debut + 1:]
                      if _RE_VERBE_CIBLE.search(l))
    _cibles_ir_n = _compte_cibles_ir(program)
    # ⛔ TROISIEME OCCURRENCE DU `max(0, ...)`, dans un compteur ecrit deux passes apres
    # celui qui l'avait deja produit. `COMPUTE X = Y + 1` n'a NI `TO` NI `GIVING`, donc
    # le balayage source rend 0 la ou l'IR porte 5 cibles (`arith_01_simple_compute`).
    # `max(0, src - ir)` ecrase ca en « 0 perdue » -- il imprime le resultat le plus
    # flatteur exactement quand il n'est pas mesurable. `ratio_valide.Ratio` REFUSE de
    # se construire dans ce cas : le TYPE porte la discipline, plus une garde a se
    # souvenir d'ecrire.
    _r = _ratio.mesurer(_cibles_ir_n, _cibles_src, "cibles d'ecriture")
    _perdues_n = _r.manquants          # None quand non mesurable, JAMAIS 0
    return {"checked": True, "reliable": True,
            "etat": "COMPLET" if manquants == 0 else "INCOMPLET",
            "verbes_source": verbes, "stmts_ir": stmts, "manquants": manquants,
            "cibles_source": _cibles_src, "cibles_ir": _cibles_ir_n,
            "cibles_perdues": _perdues_n,
            "cibles_mesurable": _r.valide,
            "note_cibles": ("%d cible(s) d'ecriture nommee(s) dans la source n'ont PAS "
                            "de contrepartie dans l'IR. Une cible perdue rend "
                            "l'equivalence PLUS FACILE a prouver : ce verdict porte sur "
                            "MOINS de sorties que le programme n'en ecrit."
                            % _perdues_n) if (_r.valide and _perdues_n) else
                           ("Autant de cibles d'ecriture dans l'IR que nommees en source."
                            if _r.valide else
                            "PERTE DE CIBLES NON MESURABLE — %s. Ce n'est PAS « aucune "
                            "cible perdue »." % _r.raison),
            "note": ("%d verbe(s) de la source n'ont pas d'instruction correspondante "
                     "dans l'IR. Tout ce qui manque ici est INVISIBLE a l'encodeur ET "
                     "au generateur : les deux s'accorderaient sur l'amputation."
                     % manquants) if manquants else
                    "Autant d'instructions dans l'IR que de verbes vus dans la source."}


def couverture_preuve(program, provable, inputs, source: str = "") -> Dict[str, Any]:
    """L'ETENDUE de ce qu'un verdict favorable couvre. Derive, jamais redige.

    `couvertes / reelles` : combien des sorties que le programme ECRIT sont
    effectivement prouvees. Un EQUIVALENT a 1/11 ne dit pas ce qu'un lecteur
    comprend.
    `dependantes` : combien de sorties prouvees ont une valeur qui DEPEND d'une
    entree libre. Zero veut dire que la preuve est orthogonale au domaine."""
    reelles = _sorties_reelles(program)
    prouvees = {k.upper() for k in (provable or {})}
    libres = {k.upper() for k in (inputs or {})}
    dep = []
    for k, v in (provable or {}).items():
        try:
            import z3 as _z3
            if libres & {str(x).upper() for x in _z3.z3util.get_vars(_z3.simplify(v))}:
                dep.append(k.upper())
        except Exception:
            pass
    couvertes = sorted(prouvees & reelles)
    return {
        "real_outputs": sorted(reelles),
        "real_output_count": len(reelles),
        "proved_outputs": sorted(prouvees),
        "proved_real_outputs": couvertes,
        "coverage": ("%d/%d" % (len(couvertes), len(reelles))) if reelles else "0/0",
        "coverage_ratio": (len(couvertes) / len(reelles)) if reelles else 0.0,
        "proved_outputs_depending_on_a_free_input": sorted(dep),
        "denominator": _denominateur_incomplet(program, source),
        "note": ("Aucune sortie ECRITE par le programme n'est prouvee : le verdict "
                 "porte sur des variables que le programme ne calcule pas."
                 if not couvertes else
                 ("La preuve est ORTHOGONALE au domaine : aucune sortie prouvee ne "
                  "depend d'une entree libre." if not dep else
                  "Au moins une sortie ECRITE est prouvee et depend d'une entree.")),
    }


def _domaine_entrees(inputs, provable) -> Dict[str, Any]:
    """Sur quoi le quantificateur de `proof_statement` porte reellement."""
    noms = sorted(inputs or {})
    dep = []
    if provable:
        libres = set(noms)
        for k, v in provable.items():
            try:
                import z3 as _z3
                if libres & {str(x) for x in _z3.z3util.get_vars(_z3.simplify(v))}:
                    dep.append(k)
            except Exception:
                pass
    if inputs is None and provable is None:
        return {"measured": False,
                "note": "domaine non transmis par l'appelant -- non mesure"}
    return {
        "measured": True,
        "free_inputs": noms,
        "free_input_count": len(noms),
        "proved_outputs": sorted(provable or {}),
        "proved_outputs_depending_on_a_free_input": sorted(dep),
        "closed_program": len(noms) == 0,
        "note": ("PROGRAMME FERME : aucune entree libre. Le quantificateur de "
                 "`proof_statement` porte sur un domaine VIDE. L'equivalence vaut "
                 "pour l'UNIQUE execution de ce programme -- elle n'etablit rien "
                 "sur la traduction en general."
                 if not noms else
                 ("Aucune sortie prouvee ne depend d'une entree libre : la preuve "
                  "porte sur des constantes malgre un domaine non vide."
                  if not dep else
                  "Au moins une sortie prouvee depend d'une entree libre : le "
                  "quantificateur porte sur un domaine reel.")),
    }


def emit_certificate(program, cobol_src, python_src, results, feedback_loop=None,
                     overflow_results=None, inputs=None, provable=None,
                     coverage=None, parse_coverage=None):
    # ⚠️ LE CERTIFICAT EST LA SEULE SURFACE QUI SORT. Les trois verdicts etaient
    # poses en interne et se repliaient en DEUX ici -- c'est-a-dire a l'endroit ou
    # ca compte. Deux consequences mesurees le 2026-08-26 :
    #  - un `NON-EQUIVALENT` etait emis pour une simple NON-VERIFICATION ;
    #  - et `proof_statement` affirmait « ∃ input : cobol(input) ≠ python(input) »,
    #    donc le certificat ACCUSAIT alors qu'on n'avait pas pu lire une sortie.
    # Un tiers ne lit pas ca comme un perimetre : il lit une divergence prouvee.
    verdict = verdict_equivalence(results)
    all_proved = verdict == VERDICT_EQUIVALENT
    _dom = _domaine_entrees(inputs, provable)
    # Les deux phrases doivent VOISINER : un « ¬∃ input » seul invite le lecteur a
    # imaginer un domaine. Sur un programme FERME il n'y en a pas, et sur un domaine
    # non vide dont aucune sortie prouvee ne depend, il y en a un qui ne sert a rien.
    _restriction = ""
    if coverage:
        _d = coverage.get("denominator", {})
        if _d.get("reliable") is False:
            _restriction += (" — PORTEE NON VERIFIEE : le balayage de la source n'a "
                             "pas pu confirmer le denominateur de la couverture")
        elif _d.get("incomplete"):
            _restriction += (" — couverture %s, RATIO OPTIMISTE : %d declaration(s) "
                             "de la source echappent au parseur"
                             % (coverage["coverage"], _d.get("missing") or 0))
        else:
            _restriction += " — couverture %s des sorties ecrites" % coverage["coverage"]
        if not coverage["proved_real_outputs"]:
            _restriction += (", et AUCUNE sortie ecrite par le programme n'est parmi "
                             "les sorties prouvees")
    if _dom.get("measured"):
        if _dom["closed_program"]:
            _restriction = (" — sur un domaine VIDE : ce programme est FERME, "
                            "l'enonce vaut pour son UNIQUE execution et n'etablit "
                            "rien sur la traduction en general")
        elif not _dom["proved_outputs_depending_on_a_free_input"]:
            _restriction = (" — mais AUCUNE sortie prouvee ne depend d'une entree "
                            "libre : la preuve porte sur des constantes")
    _ENONCE = {
        VERDICT_EQUIVALENT: "¬∃ input : cobol(input) ≠ python(input)" + _restriction,
        VERDICT_NON_EQUIVALENT: "∃ input : cobol(input) ≠ python(input)",
        VERDICT_TRADUCTION_INVALIDE: (
            "la traduction emise ne s'execute pas. Ce n'est PAS une divergence "
            "COBOL/Python et aucun contre-exemple Z3 n'est invoque : c'est un defaut "
            "du GENERATEUR, il nous appartient."),
        VERDICT_ABSTENTION: ("aucune divergence trouvee, et la verification est "
                             "INCOMPLETE : au moins une sortie n'a pas pu etre "
                             "modelisee ou la traduction n'a pas pu etre executee. "
                             "Ni equivalence ni divergence n'est affirmee."),
    }
    cert = {
        "ironproof_cobol_certificate": {
            "version": "4.0",
            "issued_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "issuer": "IRONPROOF-COBOL / Ironproof",
            "program": program.name,
            "verdict": {VERDICT_EQUIVALENT: "EQUIVALENT",
                        VERDICT_NON_EQUIVALENT: "NON-EQUIVALENT",
                        VERDICT_TRADUCTION_INVALIDE: "TRADUCTION-INVALIDE",
                        VERDICT_ABSTENTION: "ABSTENTION"}[verdict],
            "cobol_sha256": hashlib.sha256(cobol_src.encode()).hexdigest(),
            "python_sha256": hashlib.sha256(python_src.encode()).hexdigest(),
            "method": "Z3 SMT Solver (Microsoft Research)",
            # ⚠️ L'IDENTITE DU PRODUCTEUR, sans quoi le certificat ne se re-derive
            # pas. « Z3 SMT Solver » sans numero de version ne dit pas quel solveur a
            # tranche, et deux versions ne repondent pas pareil (lane 6 : correctifs
            # Spacer entre 4.16 et 5.1 sur des traces malformees). Et sans empreinte
            # du code emetteur, deux certificats de part et d'autre d'un correctif
            # sont indiscernables -- c'est la lecon Gate-3, qui nous a coute une
            # journee : un garde qui compare deux inventaires ne peut pas tirer si
            # rien ne dit qu'ils viennent de producteurs differents.
            "produced_by": _identite_producteur(),
            # ⚠️ LE DOMAINE D'ENTREES, sans quoi « ¬∃ input » est indechiffrable.
            # Mesure du 2026-08-26 : 517 des 539 programmes prouves equivalents ont
            # ZERO entree libre -- toutes leurs variables portent une clause VALUE,
            # donc l'encodeur en fait des CONSTANTES. Le quantificateur porte alors
            # sur un domaine VIDE : l'enonce est vrai VACUEMENT, et un lecteur
            # imagine un domaine qui n'existe pas. Ce n'est pas faux -- un programme
            # FERME n'a qu'une execution, donc comparer les deux evaluations EST une
            # equivalence complete POUR LUI. Mais ce n'est pas une equivalence de
            # TRADUCTION : sur un domaine reduit a un point, la preuve EST le test,
            # et c'est exactement la distinction que le produit revendique.
            # Filtre plus dur encore : parmi les 22 a domaine non vide, 17 n'ont
            # AUCUNE sortie prouvee qui DEPENDE d'une entree. Restent 5 sur 2345.
            # Le compteur appartient au certificat, pas a un script d'audit.
            "input_domain": _domaine_entrees(inputs, provable),
            # ⚠️ INSEPARABLE DU VERDICT : un EQUIVALENT ne doit pas pouvoir
            # s'imprimer sans la mesure de ce qu'il couvre. Le ratio est AUSSI dans
            # `proof_statement`, donc on ne peut pas lire la conclusion sans lui.
            # ⚠️ L'ETAGE SOUS `proof_scope`. `couverture_preuve` mesure ce que le
            # verdict couvre PARMI CE QUE LE PARSEUR A LU ; si le parseur a ampute,
            # les deux consommateurs s'accordent sur le meme trou et la couverture
            # reste flatteuse. Sept amputations en 24 h, toutes trouvees par un
            # verdict en aval, aucune par un compteur. `NON_FIABLE` est l'etat qui
            # porte le poids : « rien recu » n'est pas « rien trouve ».
            "parse_scope": parse_coverage or {"checked": False, "reliable": False,
                                              "etat": "NON_FIABLE",
                                              "note": "non mesure (ce n'est pas un feu vert)"},
            "proof_scope": coverage or {"measured": False,
                                        "note": "portee non transmise -- NON mesuree"},
            # Un artefact qui ne DEMARRE PAS n'est pas refute par un contre-exemple
            # Z3 : aucune entree n'a ete trouvee, la traduction ne s'execute pas du
            # tout. Deux non-equivalences differentes, deux enonces differents --
            # sinon l'enonce affirme une preuve qui n'existe pas.
            "proof_statement": (
                "la traduction emise ne s'execute pas ; l'equivalence ne se pose "
                "pas, et aucun contre-exemple Z3 n'est invoque"
                if any(r.status == "NE_TOURNE_PAS" for r in results)
                and not any(r.status in ("REFUTED", "NO_MATCH") for r in results)
                else _ENONCE[verdict]),
            "constructs_detected": {
                "sql": program.has_sql,
                "file_io": program.has_file_io,
                "goto": program.has_goto,
                "paragraphs": len(program.paragraphs),
                "copy_books": program.copy_books,
            },
            "proof_results": [{"variable": r.output_var, "status": r.status,
                                "proof_time_ms": round(r.proof_time_ms, 2),
                                "details": r.details, "counterexample": r.counterexample,
                                "smt2_obligation": r.smt2}
                              for r in results],
        }
    }
    if feedback_loop:
        cert["ironproof_cobol_certificate"]["feedback_loop"] = {
            "iterations": feedback_loop.iterations,
            "converged": feedback_loop.proved,
            "history_length": len(feedback_loop.history),
        }
    if overflow_results:
        cert["ironproof_cobol_certificate"]["overflow_analysis"] = [
            {"variable": o.variable, "pic_range": list(o.pic_range),
             "can_overflow": o.can_overflow, "overflow_input": o.overflow_input,
             "details": o.details}
            for o in overflow_results
        ]
    return cert


# ─────────────────────────────────────────────────────────────────────────────
# Demo sources
# ─────────────────────────────────────────────────────────────────────────────

DEMO_COBOL = """\
       IDENTIFICATION DIVISION.
       PROGRAM-ID. QC-IMPOT-CALC.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 REVENU   PIC 9(8)V99.
       01 TAUX     PIC V9(4).
       01 IMPOT    PIC 9(8)V99.
       PROCEDURE DIVISION.
           EVALUATE TRUE
               WHEN REVENU <= 49275
                   COMPUTE TAUX = 0.14
               WHEN REVENU <= 98540
                   COMPUTE TAUX = 0.19
               WHEN REVENU <= 119910
                   COMPUTE TAUX = 0.24
               WHEN OTHER
                   COMPUTE TAUX = 0.2575
           END-EVALUATE
           COMPUTE IMPOT = REVENU * TAUX
           STOP RUN.
"""

DEMO_PYTHON_BUGGY = """\
def qc_impot_calc(revenu):
    if revenu < 49275:
        taux = 0.14
    elif revenu < 98540:
        taux = 0.19
    elif revenu < 119910:
        taux = 0.24
    else:
        taux = 0.2575
    impot = revenu * taux
    return impot
"""

DEMO_PYTHON_CORRECT = """\
def qc_impot_calc(revenu):
    if revenu <= 49275:
        taux = 0.14
    elif revenu <= 98540:
        taux = 0.19
    elif revenu <= 119910:
        taux = 0.24
    else:
        taux = 0.2575
    impot = revenu * taux
    return impot
"""

BANNER = """\
╔═══════════════════════════════════════════════════════════════════════╗
║  IRONPROOF-COBOL  Full Legacy Modernization Pipeline  v2.0              ║
║  COBOL → Python + Z3 Formal Proof + Certificate                      ║
║  IronProof — 2026                                              ║
╚═══════════════════════════════════════════════════════════════════════╝"""



def _ecrire_atomique(chemin: str, contenu: str) -> None:
    """Ecrire par fichier temporaire + `os.replace`, jamais `open(path, "w")`.

    ⚠️ MECANISME MESURE LE 2026-08-27. `open(chemin, "w")` TRONQUE le fichier a zero
    octet AVANT d'ecrire quoi que ce soit. Entre cette troncature et la fin de
    `json.dump`, le certificat existe, il est LISIBLE, et il est VIDE -- donc
    `os.path.exists()` rend True sur un artefact qui ne dit rien. Le contre-poids
    `metrics/mutation_cobol.py` est mort dessus par une pile brute
    (`JSONDecodeError: Expecting value: line 1 column 1`) : il avait relu le
    certificat d'un run TUE comme s'il etait celui du programme courant.
    C'est la panne #2 du 2026-08-26 (artefact perime lu comme frais) sur l'AUTRE
    fichier : le garde d'empreinte couvrait `_generated.py` et personne n'avait
    regarde le certificat. Un miroir non garde de plus.
    `os.replace` est atomique sur le meme systeme de fichiers : le lecteur voit soit
    l'ancien contenu entier, soit le nouveau, jamais un fichier a moitie ecrit.
    Regle du depot deja ecrite ailleurs (#67-ops) et non appliquee ici.
    """
    d = os.path.dirname(os.path.abspath(chemin)) or "."
    fd, tmp = tempfile.mkstemp(dir=d, prefix=".tmp_", suffix=".part")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(contenu)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, chemin)
    except BaseException:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def run_pipeline(cobol_src: str, python_src: Optional[str] = None,
                 bounds=None, output_path="ironproof_cobol_cert.json",
                 generate_python=True, feedback_loop: bool = False,
                 max_feedback_iterations: int = 3,
                 bounded: bool = False, check_overflow_flag: bool = False,
                 quiet: bool = False) -> Tuple[dict, List[ProofResult], str]:
    if not quiet:
        print(BANNER)
        print()

    # 1 — Parse COBOL
    if not quiet:
        print("[ 1/6 ]  Parsing COBOL (tous constructs)...")
    parser = IronproofParser()
    program = parser.parse(cobol_src)
    if not quiet:
        print(f"         Programme  : {program.name}")
        print(f"         Variables  : {len(program.variables)} ({', '.join(list(program.variables)[:5])}{'...' if len(program.variables) > 5 else ''})")
        print(f"         Paragraphes: {len(program.paragraphs)} ({', '.join(list(program.paragraphs)[:3])}{'...' if len(program.paragraphs) > 3 else ''})")
        flags = []
        if program.has_sql: flags.append("SQL")
        if program.has_file_io: flags.append("File I/O")
        if program.has_goto: flags.append("GO TO")
        if program.copy_books: flags.append(f"COPY({','.join(program.copy_books)})")
        if flags: print(f"         Constructs : {', '.join(flags)}")
        print()

    # 2 — Generate Python
    gen = PythonGen()
    if generate_python:
        if not quiet:
            print("[ 2/6 ]  Génération Python...")
        generated_python = gen.generate(program)
        if not quiet:
            print(f"         {len(generated_python.splitlines())} lignes générées")
            py_path = output_path.replace(".json", "_generated.py")
            _ecrire_atomique(py_path, generated_python)
            print(f"         → {py_path}")
            print()
    else:
        generated_python = ""

    # 3 — Z3 encode COBOL
    if not quiet:
        print("[ 3/6 ]  Encoding COBOL → Z3...")
    _enc_report: Dict[str, Any] = {}
    cobol_inputs, cobol_outputs, all_cobol_vars = _build_cobol_z3(program, report=_enc_report)
    # Les sorties retirees par l'encodeur DOIVENT bloquer le verdict (NON_VERIFIE).
    # Sans ca elles retombent dans HORS_PERIMETRE, qui ne bloque pas.
    _unverified = set(_enc_report.get("dropped_outputs", []))
    # 12e forme : une cible nommee dans la source et absente de l'IR est une sortie
    # ECRITE et non modelisee. Elle BLOQUE, comme toute autre sortie non verifiee --
    # sinon un EQUIVALENT s'imprime sur un modele dont on a mesure l'amputation.
    _perdues = cibles_perdues(program, cobol_src)
    _unverified |= _perdues
    # Les champs a PIC declare ailleurs (FD) sont des SORTIES ECRITES non modelisees :
    # meme statut que `dropped_outputs`, elles bloquent.
    _ventile = ventile_cibles(program, cobol_src)
    _unverified |= {x.upper().rstrip(",.").split("(")[0].strip()
                    for x in _ventile["non_lue"]}
    provable = {k: v for k, v in cobol_outputs.items() if is_expr(v)}
    if not quiet:
        if provable:
            for var, formula in sorted(provable.items()):
                print(f"         {var:8s} = {simplify(formula)}")
        else:
            print("         (sections non-pures: SQL/IO/loops — preuve limitée aux calculs purs)")
        print()

    # 4 — Feedback loop (LLM translate → Z3 verify → correct → repeat)
    fl_result = None
    if feedback_loop and python_src is None:
        if not quiet:
            print("[ 4/6 ]  Feedback Loop LLM↔Z3...")
        fl_result = translate_with_feedback_loop(
            cobol_src, program, cobol_inputs, cobol_outputs,
            max_iterations=max_feedback_iterations, verbose=not quiet,
            unverified=_unverified,
        )
        python_src = fl_result.final_python
        if not quiet:
            print(f"         Itérations: {fl_result.iterations}")
            print(f"         Convergé  : {'✅' if fl_result.proved else '❌'}")
            print()

    # 5 — Z3 encode Python
    proof_src = python_src or generated_python or DEMO_PYTHON_CORRECT
    if not quiet:
        print("[ 5/6 ]  Encoding Python → Z3...")
    python_outputs = _build_python_z3(proof_src, all_cobol_vars)
    py_upper = {k.upper(): v for k, v in python_outputs.items()}
    if not quiet:
        for var in sorted(provable.keys()):
            if var in py_upper:
                print(f"         {var:8s} = {simplify(py_upper[var])}")
        print()

    _cibles_mauvaises = cibles_non_declarees(program)
    _pic_source = pic_declares_dans_la_source(cobol_src)
    # 6 — Z3 proof
    if not quiet:
        print("[ 6/6 ]  Preuve Z3 d'équivalence...")
    if bounded:
        results = prove_equivalence(provable, python_outputs, cobol_inputs,
                                     unverified=_unverified,
                                     source_vars=set(program.variables),
                                     variables=program.variables,
                                     cibles_invalides=_cibles_mauvaises,
                                     pic_declares=_pic_source)
        if not quiet:
            print("         (PIC-bounded mode: input ranges from PIC clauses)")
    else:
        if bounds is None:
            bounds = {v: (0.0, 10_000_000.0) for v in cobol_inputs}
        results = prove_equivalence(provable, python_outputs, cobol_inputs, bounds=bounds,
                                    unverified=_unverified,
                                    source_vars=set(program.variables),
                                    cibles_invalides=_cibles_mauvaises,
                                    pic_declares=_pic_source)
    results += _obligation_smoke(proof_src)
    # ⛔ LA 12e FORME, FERMEE DANS LES DEUX SENS (2026-08-26). `MODELE_CORROMPU`
    # n'etait emis que dans la branche `sat` : il bloquait une ACCUSATION et se taisait
    # sur un `EQUIVALENT` reposant sur la MEME corruption. Or une cible perdue rend
    # l'equivalence PLUS FACILE a prouver -- le gate tirait dans le sens desagreable et
    # se taisait dans le sens agreable, l'asymetrie exacte que la serie existe pour
    # fermer. L'obligation est desormais emise quel que soit le resultat du solveur.
    _corr = _ventile["corrompue"]
    if _corr:
        results.append(ProofResult(
            status="MODELE_CORROMPU", output_var="(modele)",
            details=("Le modele SOURCE porte %d cible(s) d'ecriture qui ne sont ni des "
                     "variables declarees, ni des champs a PIC declares ailleurs, ni des "
                     "registres speciaux COBOL : %s. Le parseur a ramasse le mauvais "
                     "jeton. Aucun verdict -- ni favorable ni defavorable -- ne porte sur "
                     "ce modele."
                     % (len(_corr), ", ".join(sorted(_corr)[:6])))))

    # 6b — Overflow check (optional)
    overflow_results: List[OverflowResult] = []
    if check_overflow_flag:
        if not quiet:
            print("         Checking for PIC overflow...")
        overflow_results = check_overflow(provable, cobol_inputs, program.variables)

    if not quiet:
        print()
        print("─" * 71)
    all_proved = bool(results) and all(r.proved for r in results)
    if not quiet:
        for r in results:
            icon = "✅ PROUVÉ " if r.proved else ("❌ RÉFUTÉ " if r.status == "REFUTED" else "⚠️  " + r.status)
            print(f"  {icon}  [{r.output_var}]  ({r.proof_time_ms:.0f} ms)")
            for line in r.details.splitlines():
                print(f"           {line}")
            if r.counterexample:
                print(f"           Contre-exemple: {r.counterexample}")
            print()

        if overflow_results:
            overflows = [o for o in overflow_results if o.can_overflow]
            if overflows:
                print("  ⚠️  OVERFLOW DETECTED:")
                for o in overflows:
                    print(f"     {o.variable}: {o.details}")
                    if o.overflow_input:
                        print(f"       Input: {o.overflow_input}")
                print()
            else:
                print("  ✅ No overflow possible within PIC ranges")
                print()

        verdict = "ÉQUIVALENCE PROUVÉE ✅" if all_proved else "TRADUCTION NON ÉQUIVALENTE ❌"
        print(f"  VERDICT: {verdict}")
        if all_proved:
            print("  ¬∃ input : COBOL(input) ≠ Python(input)")
        if fl_result:
            print(f"  Feedback Loop: {fl_result.iterations} itération(s), convergé={fl_result.proved}")
        print("─" * 71)
        print()

    cert = emit_certificate(program, cobol_src, proof_src, results, feedback_loop=fl_result,
                            inputs=cobol_inputs, provable=provable,
                            coverage=couverture_preuve(program, provable, cobol_inputs,
                                                       source=cobol_src),
                            parse_coverage=couverture_parse(program, cobol_src),
                             overflow_results=overflow_results if check_overflow_flag else None)
    if not quiet:
        _ecrire_atomique(output_path,
                         json.dumps(cert, indent=2, ensure_ascii=False))
        print(f"  Certificat : {output_path}")
        if generate_python:
            py_path = output_path.replace(".json", "_generated.py")
            print(f"  Python     : {py_path}")

    return cert, results, proof_src if fl_result else generated_python


def main():
    ap = argparse.ArgumentParser(description="IRONPROOF-COBOL Full Legacy Pipeline v3.0")
    ap.add_argument("--cobol", help="Fichier COBOL source (.cbl)")
    ap.add_argument("--python", help="Fichier Python pour preuve Z3 (.py)")
    ap.add_argument("--translate", action="store_true", help="Traduire via Claude API")
    ap.add_argument("--feedback-loop", action="store_true",
                    help="Feedback loop: LLM traduit → Z3 vérifie → LLM corrige (max 3 itérations)")
    ap.add_argument("--max-iterations", type=int, default=3,
                    help="Max itérations du feedback loop (défaut: 3)")
    ap.add_argument("--demo-bug", action="store_true")
    ap.add_argument("--demo-ok", action="store_true")
    ap.add_argument("--output", default="ironproof_cobol_cert.json")
    ap.add_argument("--copy-dir", action="append", default=[], help="Répertoire COPY books")
    ap.add_argument("--bounded", action="store_true",
                    help="Use PIC-derived bounds for Z3 inputs (overflow-aware)")
    ap.add_argument("--check-overflow", action="store_true",
                    help="Check if output variables can overflow their PIC ranges")
    ap.add_argument("--quiet", action="store_true", help="Sortie minimale (pour benchmark)")
    args = ap.parse_args()

    cobol_src = open(args.cobol).read() if args.cobol else DEMO_COBOL

    python_src = None
    if args.feedback_loop:
        run_pipeline(cobol_src, python_src=None, output_path=args.output,
                     feedback_loop=True, max_feedback_iterations=args.max_iterations,
                     quiet=args.quiet)
        return
    elif args.translate:
        if not args.quiet:
            print("  Traduction via Claude API...")
        python_src = translate_with_claude(cobol_src)
        if not args.quiet:
            print(f"  Code:\n{'─'*60}\n{python_src}\n{'─'*60}\n")
    elif args.python:
        python_src = open(args.python).read()
    elif args.demo_bug:
        python_src = DEMO_PYTHON_BUGGY
        if not args.quiet:
            print("  Mode demo — BUG (< au lieu de <=)\n")
    elif args.demo_ok:
        python_src = DEMO_PYTHON_CORRECT

    run_pipeline(cobol_src, python_src=python_src, output_path=args.output,
                 bounded=args.bounded, check_overflow_flag=args.check_overflow,
                 quiet=args.quiet)


if __name__ == "__main__":
    main()
