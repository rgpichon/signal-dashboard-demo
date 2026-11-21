"""
Factor-to-instrument mapping for E1/E2. Used by /api/factors (primary_instrument)
and /api/factor-map. Factor IDs must match signals.research.factor_model (f_rates, f_dollar, etc.).
Instruments are SIGNAL IDs from universe (market_data series_id or universe id).
"""
# Factor IDs match factor_model.FACTOR_SERIES keys exactly.
FACTOR_INSTRUMENTS = {
    "f_market": {
        "name": "Market Beta",
        "instruments": ["ETF.SPY", "ETF.QQQ", "ETF.IWM", "ETF.DIA", "ETF.EZU"],
        "primary_instrument": "EQ.SPX",
    },
    "f_rates": {
        "name": "Rates",
        "instruments": [
            "RATES.US10Y",
            "FI.US10Y",
            "IR.US10Y",
            "IR.US2Y",
            "IR.US30Y",
            "ETF.TLT",
            "ETF.SHY",
            "ETF.XLF",
        ],
        "primary_instrument": "RATES.US10Y",
    },
    "f_dollar": {
        "name": "Dollar",
        "instruments": ["FX.DXY", "FX.EURUSD", "FX.GBPUSD", "FX.USDJPY"],
        "primary_instrument": "FX.DXY",
    },
    "f_risk": {
        "name": "Risk Appetite",
        "instruments": ["EQ.VIX", "VX.VIX", "EQ.SPX", "EQ.NDX", "EQ.DAX", "EQ.FTSE", "EQ.NKY"],
        "primary_instrument": "EQ.VIX",
    },
    "f_growth": {
        "name": "Growth",
        "instruments": [
            "CM.COPPER",
            "CM.BRENT",
            "CM.WTI",
            "CM.GOLD",
            "CM.NATGAS",
            "CM.SILVER",
            "CM.WHEAT",
            "ETF.XLE",
            "ETF.USO",
            "ETF.GLD",
            "ETF.XLB",
        ],
        "primary_instrument": "CM.COPPER",
    },
    "f_credit": {
        "name": "Credit",
        "instruments": ["CREDIT.HY_OAS", "ETF.LQD", "ETF.HYG"],
        "primary_instrument": "CREDIT.HY_OAS",
    },
    "f_inflation": {
        "name": "Inflation",
        "instruments": ["RATES.BREAKEVEN"],
        "primary_instrument": "RATES.BREAKEVEN",
    },
}

# Reverse mapping: SIGNAL instrument ID -> factor ID (for shock routing in E2).
INSTRUMENT_TO_FACTOR = {}
for _fid, _meta in FACTOR_INSTRUMENTS.items():
    for _instr in _meta["instruments"]:
        INSTRUMENT_TO_FACTOR[_instr] = _fid
