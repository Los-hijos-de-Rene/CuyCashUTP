import json

import httpx
import pytest

from scripts.uat_prod import run


@pytest.mark.parametrize('url,write,production', [
    ('http://127.0.0.1:8001', False, False),
    ('https://cuycashutp.onrender.com', True, False),
    ('https://third-party.example.org', True, True),
    ('http://cuycashutp.onrender.com', True, True),
])
def test_uat_requires_approved_target_and_writes(tmp_path, url, write, production):
    with pytest.raises(ValueError):
        run(url, tmp_path/'report.json', write, production)


def test_uat_records_kyc_block_without_credentials(tmp_path, monkeypatch):
    original = httpx.Client
    def handle(request):
        if request.url.path == '/health':
            return httpx.Response(200, json={'version': 'test-version'})
        return httpx.Response(403, json={'code': 'KYC_REQUIRED', 'session_token': 'secret-never-record'})
    monkeypatch.setattr(httpx, 'Client', lambda **kw: original(**kw, transport=httpx.MockTransport(handle)))
    output = tmp_path/'report.json'
    assert run('https://cuycashutp.onrender.com', output, True, True) is False
    report = json.loads(output.read_text())
    assert report['status'] == 'incomplete'
    assert report['steps'][-1]['error_code'] == 'KYC_REQUIRED'
    assert 'secret-never-record' not in output.read_text()
