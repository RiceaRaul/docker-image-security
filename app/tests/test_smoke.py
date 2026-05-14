from app.main import create_app


def test_healthz():
    client = create_app().test_client()
    r = client.get("/healthz")
    assert r.status_code == 200
    assert r.get_json() == {"status": "ok"}


def test_index_lists_endpoints():
    client = create_app().test_client()
    r = client.get("/")
    body = r.get_json()
    assert "/healthz" in body["endpoints"]


def test_sqli_demonstrates_concat():
    client = create_app().test_client()
    r = client.get("/api/user?id=1 OR 1=1")
    body = r.get_json()
    assert len(body["rows"]) >= 2  # injection returns all rows
