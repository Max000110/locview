from locview.intel.risk import classify_risk

def test_risk_levels():
    assert classify_risk(90) == "Low Risk"
