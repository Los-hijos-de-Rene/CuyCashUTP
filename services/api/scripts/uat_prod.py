"""UAT HTTP con datos ficticios. Nunca imprime PIN, tokens ni respuestas crudas.

Requiere --allow-writes; producción requiere además --production-approved.
DNI 00001021/00001022 reservados SOLO para este ensayo en CuyCash (no RENIEC).
Si ya existen o KYC exige ticket, se detiene: no reutiliza identidades ni elude KYC.
"""
import argparse
import json
import secrets
import time
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import urlsplit

import httpx


class UATFailure(Exception):
    pass


def run(base_url, output, allow_writes=False, production_approved=False):
    parsed = urlsplit(base_url)
    production = parsed.hostname == "cuycashutp.onrender.com"
    if not allow_writes or (production and not production_approved):
        raise ValueError("Falta autorización explícita de escrituras para el destino")
    if parsed.hostname not in {"127.0.0.1", "localhost", "cuycashutp.onrender.com"}:
        raise ValueError("Destino no autorizado por este script")
    if production and parsed.scheme != "https":
        raise ValueError("Producción requiere HTTPS")
    report = {"utc": datetime.now(timezone.utc).isoformat(), "base_url": base_url,
              "environment": "production" if production else "local",
              "synthetic_dni": ["00001021", "00001022"], "steps": [],
              "status": "incomplete"}
    headers = []
    run_id = secrets.token_hex(6)
    pin = ""
    while len(set(pin)) < 5:
        pin = f"{secrets.randbelow(1000000):06d}"
    with httpx.Client(base_url=base_url, timeout=90, follow_redirects=False) as client:
        def request(label, method, path, expected, **kwargs):
            start = time.perf_counter()
            response = client.request(method, path, **kwargs)
            item = {"step": label, "expected_http": expected, "actual_http": response.status_code,
                    "latency_ms": round((time.perf_counter()-start)*1000, 2)}
            report["steps"].append(item)
            if response.status_code not in expected:
                try:
                    item["error_code"] = response.json().get("code", "unexpected_response")
                except (ValueError, AttributeError):
                    item["error_code"] = "non_json_response"
                raise UATFailure(label)
            return response.json() if response.content else {}

        def check(label, ok):
            report["steps"].append({"step": label, "passed": bool(ok)})
            if not ok:
                raise UATFailure(label)

        def accounts(h):
            return request("accounts", "GET", "/v1/accounts", [200], headers=h)["cuentas"]

        def movements(h):
            return request("movements", "GET", "/v1/movements", [200], headers=h)["movimientos"]

        try:
            report["deployed_version"] = request("health", "GET", "/health", [200]).get("version")
            for n, dni in enumerate(report["synthetic_dni"]):
                h = {"X-Device-Id": f"apf3-uat-{run_id}-{n}"}
                data = request(f"register synthetic {n+1}", "POST", "/v1/auth/register", [201], headers=h,
                               json={"dni": dni, "nombres": "Uat Alfa" if n == 0 else "Uat Beta",
                                     "apellidos": "Ensayo Sintetico", "email": f"cuycash-uat-{run_id}-{n}@example.org", "pin": pin})
                h["Authorization"] = "Bearer " + data["session_token"]
                headers.append(h)
            a, b = headers
            ca, cb = accounts(a)[0], accounts(b)[0]
            check("initial synthetic balances zero", ca["saldo_disponible"] == cb["saldo_disponible"] == 0)
            def topup(amount, suffix):
                return request("topup " + suffix, "POST", "/v1/topups", [201], headers=a,
                               json={"cuenta_id": ca["id"], "monto_centimos": amount, "idempotency_key": run_id+suffix})
            def transfer(amount, suffix, expected):
                return request("transfer " + suffix, "POST", "/v1/transfers", expected, headers=a,
                               json={"cuenta_origen_id": ca["id"], "cuenta_destino_id": cb["id"],
                                     "monto_centimos": amount, "pin": pin, "idempotency_key": run_id+suffix})
            # UAT-2 primero para conservar las precondiciones exactas usando solo dos usuarios.
            topup(5000, "uat2-topup")
            for _ in range(2):
                rejected = transfer(50000, "uat2-insufficient", [400, 409])
                check("UAT-2 insufficient funds", rejected.get("code") == "INSUFFICIENT_FUNDS")
            check("UAT-2 unchanged balances", accounts(a)[0]["saldo_disponible"] == 5000 and accounts(b)[0]["saldo_disponible"] == 0)
            check("UAT-2 no new movements", len(movements(a)) == 1 and len(movements(b)) == 0)
            topup(45000, "uat1-topup")
            directory = request("UAT-1 resolve", "GET", "/v1/directory/resolve", [200], headers=a, params={"dni": report["synthetic_dni"][1]})
            check("UAT-1 masked name", "***" in directory["nombre_enmascarado"])
            first = transfer(12550, "uat1-transfer", [201])
            retry = transfer(12550, "uat1-transfer", [200])
            check("UAT-1 idempotent transaction", first["transaction_id"] == retry["transaction_id"])
            check("UAT-1 balances", accounts(a)[0]["saldo_disponible"] == 37450 and accounts(b)[0]["saldo_disponible"] == 12550)
            check("UAT-1 debit and credit", movements(a)[0]["direccion"] == "debito" and movements(b)[0]["direccion"] == "credito")
            report["status"] = "passed"
        except UATFailure as error:
            report["blocked_at"] = str(error)
        except httpx.HTTPError:
            report["blocked_at"] = "transport_error"
        finally:
            for h in headers:
                try:
                    request("revoke UAT session", "DELETE", "/v1/auth/sessions/current", [204], headers=h)
                except (UATFailure, httpx.HTTPError):
                    report["session_cleanup"] = "incomplete"
            Path(output).write_text(json.dumps(report, indent=2)+"\n")
    return report["status"] == "passed"


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base-url", default="http://127.0.0.1:8001")
    parser.add_argument("--output", required=True)
    parser.add_argument("--allow-writes", action="store_true")
    parser.add_argument("--production-approved", action="store_true")
    args = parser.parse_args()
    raise SystemExit(0 if run(args.base_url, args.output, args.allow_writes, args.production_approved) else 1)
