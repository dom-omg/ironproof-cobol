def fed_tax_calc(income):
    if income < 47150:
        tax_rate = 0.12
    elif income < 100525:
        tax_rate = 0.22
    elif income < 191950:
        tax_rate = 0.24
    else:
        tax_rate = 0.32
    tax_amt = income * tax_rate
    return tax_amt
