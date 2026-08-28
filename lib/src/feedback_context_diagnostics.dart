import 'package:flutter/material.dart';

/// Collects diagnostics that are scoped to a specific Flutter widget tree.
///
/// The resolved application locale and current view metrics cannot be inferred
/// reliably without a [BuildContext], particularly in multi-view apps.
Map<String, String> collectFeedbackContextDiagnostics(
  final BuildContext? context,
) {
  if (context == null) {
    return const {};
  }

  final values = <String, String>{};
  final appLocale = Localizations.maybeLocaleOf(context);
  if (appLocale != null) {
    values['App locale'] = appLocale.toLanguageTag();
  }

  final view = View.maybeOf(context);
  if (view != null) {
    final devicePixelRatio = view.devicePixelRatio;
    final logicalSize = view.physicalSize / devicePixelRatio;
    values['Window size (logical pixels)'] =
        '${logicalSize.width.round()}x${logicalSize.height.round()}';
    values['Device pixel ratio'] = devicePixelRatio.toStringAsFixed(2);
  }

  return values;
}
