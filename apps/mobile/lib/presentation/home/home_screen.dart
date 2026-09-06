import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Home placeholder del Sprint 1 (las features de billetera llegan después).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.homeTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(CuyCashSpacing.containerPadding),
          child: Text(l10n.homePlaceholder,
              textAlign: TextAlign.center, style: CuyCashTypography.bodyLg),
        ),
      ),
    );
  }
}
