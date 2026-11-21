# Structure: { from_series_prefix: [ { to_series_prefix, direction, strength, condition } ] }
# direction: "positive" | "negative" | "conditional"
# strength: "direct" | "indirect" | "speculative"
# condition: plain-language condition string or None

STATIC_RELATIONSHIPS = {
    "CM.BRENT": [
        {"to": "RATES.BREAKEVEN", "direction": "positive", "strength": "direct", "condition": None},
        {"to": "FX.DXY", "direction": "negative", "strength": "direct", "condition": "if supply shock not demand"},
        {"to": "EQ.XLE", "direction": "positive", "strength": "direct", "condition": None},
        {"to": "MACRO.CPI", "direction": "positive", "strength": "direct", "condition": None},
    ],
    "CM.WTI": [
        {"to": "RATES.BREAKEVEN", "direction": "positive", "strength": "direct", "condition": None},
        {"to": "FX.DXY", "direction": "negative", "strength": "indirect", "condition": None},
    ],
    "RATES.US10Y": [
        {"to": "FX.DXY", "direction": "positive", "strength": "direct", "condition": "if rate differential widens"},
        {"to": "EQ.SPX", "direction": "negative", "strength": "indirect", "condition": "if real rates rise"},
        {"to": "CREDIT.HY_OAS", "direction": "positive", "strength": "indirect", "condition": None},
    ],
    "FX.DXY": [
        {"to": "CM.GOLD", "direction": "negative", "strength": "direct", "condition": None},
        {"to": "CM.BRENT", "direction": "negative", "strength": "direct", "condition": None},
        {"to": "EQ.EEM", "direction": "negative", "strength": "direct", "condition": "if EM has dollar-denominated debt"},
    ],
    "EQ.VIX": [
        {"to": "CM.GOLD", "direction": "positive", "strength": "direct", "condition": None},
        {"to": "FX.DXY", "direction": "positive", "strength": "direct", "condition": "flight to safety"},
        {"to": "CREDIT.HY_OAS", "direction": "positive", "strength": "direct", "condition": None},
        {"to": "EQ.SPX", "direction": "negative", "strength": "direct", "condition": None},
    ],
    "RATES.BREAKEVEN": [
        {"to": "RATES.US10Y", "direction": "positive", "strength": "direct", "condition": None},
        {"to": "CM.GOLD", "direction": "positive", "strength": "indirect", "condition": None},
    ],
}

# Known tension pairs — used by tension_detector as a first-pass lookup
KNOWN_TENSIONS = [
    ("RATES.US10Y", "EQ.SPX", "Rising rates typically compress equity multiples — do earnings growth expectations dominate?"),
    ("FX.DXY", "CM.BRENT", "Dollar strength and oil price rise are inversely correlated — which force dominates?"),
    ("FX.DXY", "CM.GOLD", "Dollar strength suppresses gold — are both in your thesis and if so, which wins?"),
    ("CREDIT.HY_OAS", "EQ.SPX", "Credit spread widening and equity stability is a decoupling risk — which is leading?"),
    ("RATES.BREAKEVEN", "RATES.US2Y", "Inflation expectations and short-rate expectations can diverge — do you have a CB reaction function view?"),
]
