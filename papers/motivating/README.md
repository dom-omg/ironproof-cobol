Motivating example of the paper (Listings 1-3).

    PYTHONHASHSEED=0 python3 ironproof_core.py \
        --cobol papers/motivating/fed_tax_calc.cbl \
        --python papers/motivating/fed_tax_calc_boundary_error.py

The Python file is written by hand to illustrate a boundary-operator error;
it is not LLM output. Listing 3 of the paper is condensed from this command's
output (TAX-AMT 46068 vs 61424, TAX-RATE 0.24 vs 0.32, INCOME = 191950).
