"""Cálculo puro, sin DB ni reloj. Contrato y redondeo: idoneidad-funcional §4.1."""

from calendar import monthrange
from dataclasses import dataclass
from datetime import date
from decimal import Context, Decimal, ROUND_HALF_UP, localcontext
from fractions import Fraction

MAX_PRINCIPAL = 10**12  # céntimos; límite técnico, no política comercial
MAX_MESES = 360
MAX_DECIMALES_TEA = 120  # evita precisión/memoria sin cota en entradas externas
_CONTEXT = Context(prec=50, rounding=ROUND_HALF_UP)
_ONE = Decimal(1)


@dataclass(frozen=True)
class Cuota:
    numero: int
    vencimiento: date
    capital: int
    interes: int
    saldo_pendiente: int

    @property
    def total(self) -> int:
        return self.capital + self.interes


@dataclass(frozen=True)
class Cronograma:
    principal: int
    tea: Decimal
    tcea: Decimal
    cuota_regular: int
    cuotas: tuple[Cuota, ...]

    @property
    def total_intereses(self) -> int:
        return sum(c.interes for c in self.cuotas)

    @property
    def total_pagar(self) -> int:
        return sum(c.total for c in self.cuotas)


def _vencimiento(fecha: date, meses: int) -> date:
    indice = fecha.year * 12 + fecha.month - 1 + meses
    year, month = divmod(indice, 12)
    month += 1
    return date(year, month, min(fecha.day, monthrange(year, month)[1]))


def _centimos(valor: Decimal) -> int:
    return int(valor.quantize(_ONE, rounding=ROUND_HALF_UP))


def _centimos_exactos(valor: Fraction) -> int:
    """HALF_UP para importes no negativos, sin división decimal intermedia."""
    return (2 * valor.numerator + valor.denominator) // (2 * valor.denominator)


def _mensual_exacta(tea: Decimal, aproximada: Decimal) -> Fraction | None:
    """Reconoce raíces mensuales decimales sin tolerancias ni redondear la TEA.

    Una raíz racional de (1+TEA), con TEA decimal de hasta 120 posiciones,
    tiene como máximo 10 decimales: sus exponentes de 2 y 5 se dividen por 12.
    La candidata solo se usa si su potencia 12 coincide EXACTAMENTE con la
    entrada. Esto evita que una cuota exactamente x.5 caiga a x.4999... por
    la suma/división de factores de descuento aproximados.
    """
    candidata = Fraction(aproximada.quantize(Decimal('0.0000000001')))
    return candidata if (1 + candidata) ** 12 == 1 + Fraction(tea) else None


def _tcea(principal: int, cuotas: tuple[Cuota, ...]) -> Decimal:
    """TIR mensual de flujos redondeados; sin cargos y neto = principal.

    Para pagos positivos el valor presente es estrictamente decreciente.
    Bisección acotada, sin float, evita depender de una estimación de Newton.
    Solo la tasa de salida se redondea; nunca se usa para recalcular cuotas.
    """
    if sum(c.total for c in cuotas) == principal:
        return Decimal(0)

    def valor_presente(tasa: Decimal) -> Decimal:
        descuento = _ONE / (_ONE + tasa)
        factor = descuento
        total = Decimal(0)
        for cuota in cuotas:
            total += cuota.total * factor
            factor *= descuento
        return total

    inferior, superior = Decimal(0), _ONE
    # El dominio de entrada limita la tasa mensual muy por debajo del 100 %.
    if valor_presente(superior) > principal:
        raise ValueError("Los flujos superan el dominio de cálculo de TCEA")
    for _ in range(140):
        medio = (inferior + superior) / 2
        if valor_presente(medio) > principal:
            inferior = medio
        else:
            superior = medio
    tasa = (inferior + superior) / 2
    return ((_ONE + tasa) ** 12 - 1).quantize(Decimal("0.0000000000000001"))


def calcular_cronograma(
    *, principal: int, tea: Decimal, meses: int, fecha_desembolso: date
) -> Cronograma:
    """Francés mensual: capital + interés en céntimos, última cuota ajustada.

    `tea` es una fracción anual (Decimal('0.12') = 12 %), no porcentaje ni
    TCEA. Las entradas inválidas o no representables en céntimos dan ValueError.
    Los vencimientos siempre se calculan desde la fecha original.
    """
    if type(principal) is not int or not 0 < principal <= MAX_PRINCIPAL:
        raise ValueError("Principal fuera de rango o no entero de céntimos")
    if type(meses) is not int or not 1 <= meses <= MAX_MESES:
        raise ValueError("El plazo debe ser un entero entre 1 y 360 meses")
    if not isinstance(tea, Decimal) or not tea.is_finite() or not 0 <= tea <= 10:
        raise ValueError("TEA debe ser Decimal finito entre 0 y 10")
    if not tea.is_zero() and tea.as_tuple().exponent < -MAX_DECIMALES_TEA:
        raise ValueError("TEA admite como máximo 120 posiciones decimales")
    if type(fecha_desembolso) is not date:
        raise ValueError("La fecha de desembolso debe ser date, sin hora")
    if fecha_desembolso.year * 12 + fecha_desembolso.month - 1 + meses > 119999:
        raise ValueError("Los vencimientos exceden el calendario admitido")

    with localcontext(_CONTEXT) as ctx:
        # Conserva también entradas apenas por encima/debajo de medio céntimo.
        # Una precisión fija puede borrar esa diferencia antes del HALF_UP.
        ctx.prec = max(_CONTEXT.prec, -tea.as_tuple().exponent + 40) if tea else _CONTEXT.prec
        tasa = (_ONE + tea) ** (_ONE / 12) - 1
        exacta = _mensual_exacta(tea, tasa)
        # Sumar descuentos evita la cancelación (1 - (1+i)^-n) cerca de i=0.
        descuento = _ONE / (_ONE + tasa)
        factor, suma = descuento, Decimal(0)
        for _ in range(meses):
            suma += factor
            factor *= descuento
        if exacta is not None:
            suma_exacta = (1 - (1 + exacta) ** -meses) / exacta if exacta else Fraction(meses)
            regular = _centimos_exactos(Fraction(principal) / suma_exacta)
        else:
            regular = _centimos(Decimal(principal) / suma)
        saldo = principal
        filas = []
        for numero in range(1, meses + 1):
            interes = (_centimos_exactos(saldo * exacta) if exacta is not None
                       else _centimos(Decimal(saldo) * tasa))
            capital = saldo if numero == meses else regular - interes
            if capital <= 0 or (numero < meses and capital >= saldo):
                raise ValueError("El monto y plazo no permiten amortización mensual en céntimos")
            saldo -= capital
            filas.append(Cuota(numero, _vencimiento(fecha_desembolso, numero), capital, interes, saldo))
        cuotas = tuple(filas)
        return Cronograma(principal, tea, _tcea(principal, cuotas), regular, cuotas)
