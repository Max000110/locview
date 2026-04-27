from locview.intel.scoring import classify_score

def test_score_labels():
    assert classify_score(90) == "Prime"
    assert classify_score(70) == "High Potential"
