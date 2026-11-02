"""Oráculos de #79: importes calculados a mano e invariantes de dominio."""
from datetime import date, datetime
from decimal import Decimal, ROUND_DOWN, localcontext

import pytest

from app.services.loan_schedule import MAX_PRINCIPAL, calcular_cronograma


def calcular(**cambios):
    datos = dict(principal=100_000, tea=Decimal('0'), meses=3, fecha_desembolso=date(2026, 1, 31))
    datos.update(cambios)
    return calcular_cronograma(**datos)


def test_tasa_cero_ultima_cuota_absorbe_residuo():
    c = calcular()
    assert [q.total for q in c.cuotas] == [33333, 33333, 33334]
    assert [q.saldo_pendiente for q in c.cuotas] == [66667, 33334, 0]
    assert c.total_intereses == 0
    assert c.total_pagar == c.principal == 100000
    assert c.tcea == 0


def test_medio_centimo_se_redondea_hacia_arriba():
    c = calcular(principal=101, meses=2)
    assert c.cuota_regular == 51
    assert [q.total for q in c.cuotas] == [51, 50]


def test_un_mes_interes_y_tcea_segun_pago_real():
    # TEA que corresponde exactamente a 1 % mensual; 150 * .01 = 1.5 céntimos.
    with localcontext() as ctx:
        ctx.prec = 50
        tea = Decimal('1.01') ** 12 - 1
        # El pago real es 152, de ahí la TCEA, no de la TEA original.
        esperada = ((Decimal(152) / 150) ** 12 - 1).quantize(Decimal('0.0000000000000001'))
    c = calcular(principal=150, tea=tea, meses=1)
    assert (c.cuotas[0].capital, c.cuotas[0].interes, c.cuotas[0].total) == (150, 2, 152)
    assert c.tcea == esperada
    assert c.tcea != tea


def test_dos_meses_al_uno_por_ciento_oraculo_manual():
    with localcontext() as ctx:
        ctx.prec = 50
        tea = Decimal('1.01') ** 12 - 1
    c = calcular(principal=10000, tea=tea, meses=2)
    # Cuota exacta 5075.124...; interés 100, luego 5025 * 1 % = 50.25.
    assert [(q.capital, q.interes, q.total) for q in c.cuotas] == [(4975, 100, 5075), (5025, 50, 5075)]
    assert c.total_pagar == 10150


@pytest.mark.parametrize('fecha,esperadas', [
    (date(2026, 1, 31), [date(2026, 2, 28), date(2026, 3, 31), date(2026, 4, 30)]),
    (date(2028, 1, 31), [date(2028, 2, 29), date(2028, 3, 31), date(2028, 4, 30)]),
    (date(2026, 12, 30), [date(2027, 1, 30), date(2027, 2, 28), date(2027, 3, 30)]),
])
def test_calendario_sin_arrastrar_recorte(fecha, esperadas):
    assert [q.vencimiento for q in calcular(fecha_desembolso=fecha).cuotas] == esperadas


@pytest.mark.parametrize('principal', [1000000, 10000001, MAX_PRINCIPAL])
@pytest.mark.parametrize('meses,tea', [(1, Decimal('0')), (12, Decimal('0')), (360, Decimal('0')), (1, Decimal('0.12')), (12, Decimal('0.12')), (360, Decimal('0.12')), (1, Decimal('10')), (12, Decimal('10'))])
def test_conserva_capital_y_reconcilia_flujos(principal, meses, tea):
    c = calcular(principal=principal, meses=meses, tea=tea)
    assert len(c.cuotas) == meses
    assert sum(q.capital for q in c.cuotas) == principal
    saldo = principal
    for n, q in enumerate(c.cuotas, 1):
        saldo -= q.capital
        assert q.numero == n
        assert q.capital > 0 and q.interes >= 0
        assert q.saldo_pendiente == saldo >= 0
        assert all(type(v) is int for v in (q.capital, q.interes, q.total))
    assert saldo == 0
    assert c.total_pagar == principal + c.total_intereses
    # Oráculo de TIR: descuento de pagos con la tasa publicada recupera el neto.
    with localcontext() as ctx:
        ctx.prec = 50
        mensual = (1 + c.tcea) ** (Decimal(1) / 12) - 1
        presente = sum(Decimal(q.total) / (1 + mensual) ** q.numero for q in c.cuotas)
    assert abs(presente - principal) < Decimal('1')


@pytest.mark.parametrize('cambios', [
    {'principal': 0}, {'principal': -1}, {'principal': True}, {'principal': 100.0},
    {'principal': MAX_PRINCIPAL + 1}, {'meses': 0}, {'meses': 361},
    {'meses': True}, {'meses': 1.0}, {'tea': 0.12}, {'tea': '0.12'},
    {'tea': Decimal('NaN')}, {'tea': Decimal('sNaN')}, {'tea': Decimal('Infinity')},
    {'tea': Decimal('-0.01')}, {'tea': Decimal('10.01')},
    {'fecha_desembolso': datetime(2026, 1, 1)}, {'fecha_desembolso': '2026-01-01'},
    {'fecha_desembolso': date(9999, 12, 1)},
    {'principal': 10000, 'meses': 360}, {'principal': 100001, 'meses': 360, 'tea': Decimal('0.12')},
    {'principal': 1, 'meses': 3}, {'principal': 2, 'meses': 3},
    {'principal': 10000, 'meses': 360, 'tea': Decimal('10')},
])
def test_entrada_invalida_o_no_representable(cambios):
    with pytest.raises(ValueError):
        calcular(**cambios)


def test_resultado_no_depende_del_contexto_decimal_ajeno():
    esperado = calcular(tea=Decimal('0.12'))
    with localcontext() as ctx:
        ctx.prec = 6
        ctx.rounding = ROUND_DOWN
        assert calcular(tea=Decimal('0.12')) == esperado
        assert ctx.prec == 6 and ctx.rounding == ROUND_DOWN


def test_tasa_muy_pequena_y_limite_calendario():
    c = calcular(tea=Decimal('1e-40'), meses=1, fecha_desembolso=date(9999, 11, 30))
    assert c.cuotas[0].vencimiento == date(9999, 12, 30)
    assert c.total_pagar == c.principal


def test_cuota_regular_medio_centimo_con_interes_no_pierde_el_empate():
    # A 10 % mensual: 105 * .1 / (1 - 1.1**-2) = 60.5 EXACTAMENTE.
    # La suma decimal de descuentos del parche original devolvía 60.4999... .
    c = calcular(principal=105, meses=2, tea=Decimal('2.138428376721'))
    assert c.cuota_regular == 61
    assert [(q.capital, q.interes, q.total) for q in c.cuotas] == [
        (50, 11, 61), (55, 6, 61),
    ]


@pytest.mark.parametrize('lado,esperado', [(-1, 1), (0, 2), (1, 2)])
def test_interes_justo_alrededor_del_medio_centimo(lado, esperado):
    with localcontext() as ctx:
        ctx.prec = 100
        tea = Decimal('1.01') ** 12 - 1 + lado * Decimal('1e-60')
    c = calcular(principal=150, meses=1, tea=tea)
    assert c.cuotas[0].interes == esperado
    assert c.cuota_regular == 150 + esperado


@pytest.mark.parametrize('lado,esperado', [(-1, 60), (0, 61), (1, 61)])
def test_cuota_justo_alrededor_del_medio_centimo(lado, esperado):
    with localcontext() as ctx:
        ctx.prec = 100
        tea = Decimal('2.138428376721') + lado * Decimal('1e-60')
    assert calcular(principal=105, meses=2, tea=tea).cuota_regular == esperado


def test_rechaza_precision_de_tasa_fuera_del_dominio():
    with pytest.raises(ValueError, match='120 posiciones'):
        calcular(tea=Decimal('1e-121'))


def test_limite_de_precision_de_tasa_y_dia_bisiesto_de_origen():
    c = calcular(tea=Decimal('1e-120'), fecha_desembolso=date(2028, 2, 29))
    assert [q.vencimiento for q in c.cuotas] == [
        date(2028, 3, 29), date(2028, 4, 29), date(2028, 5, 29),
    ]
    assert sum(q.capital for q in c.cuotas) == c.principal
