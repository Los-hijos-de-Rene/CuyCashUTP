import 'package:flutter/material.dart';

/// Datos de fachada para Inicio.
///
/// El motor transaccional es del Sprint 2: hoy NO existe saldo ni movimientos
/// reales. Esto es una maqueta para validar el layout, y la pantalla lo dice
/// con el sello "Datos de demostración" para que nadie lo lea como su dinero.
/// Cuando llegue la feature de cuentas, esto se borra y entra un bloc.

/// Día relativo de un movimiento. Enum y no texto: el copy vive en el ARB.
enum MovementDay { today, yesterday }

/// Naturaleza del movimiento: decide color y signo.
enum MovementKind { income, expense }

/// Una fila de "Últimos movimientos".
class DemoMovement {
  const DemoMovement({
    required this.title,
    required this.amount,
    required this.kind,
    required this.day,
    required this.time,
    required this.icon,
  });

  final String title;
  final double amount;
  final MovementKind kind;
  final MovementDay day;
  final String time;
  final IconData icon;
}

/// La billetera inventada que pinta la pantalla.
abstract final class DemoWallet {
  static const balance = 1250.40;
  static const walletLast4 = '4521';

  static const movements = <DemoMovement>[
    DemoMovement(
      title: 'Bodega Don Aurelio',
      amount: 45.00,
      kind: MovementKind.expense,
      day: MovementDay.today,
      time: '14:30',
      icon: Icons.storefront_outlined,
    ),
    DemoMovement(
      title: 'Jenny Marisol Ruiz',
      amount: 1200.00,
      kind: MovementKind.income,
      day: MovementDay.today,
      time: '09:15',
      icon: Icons.south_west,
    ),
    DemoMovement(
      title: 'Menú La Cuchara',
      amount: 18.50,
      kind: MovementKind.expense,
      day: MovementDay.yesterday,
      time: '13:05',
      icon: Icons.restaurant_outlined,
    ),
  ];
}
