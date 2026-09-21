import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

// Breakpoints definidos en AGENTS.md
const double kBreakpointMovil = 600;
const double kBreakpointTablet = 900;

/// Devuelve true si el ancho de pantalla es de móvil.
bool esMovil(BuildContext context) =>
    MediaQuery.of(context).size.width < kBreakpointMovil;

/// Devuelve true si el ancho de pantalla es de tablet.
bool esTablet(BuildContext context) {
  final ancho = MediaQuery.of(context).size.width;
  return ancho >= kBreakpointMovil && ancho < kBreakpointTablet;
}

/// Devuelve true si el ancho de pantalla es de escritorio.
bool esEscritorio(BuildContext context) =>
    MediaQuery.of(context).size.width >= kBreakpointTablet;

/// Devuelve true si la app corre en web.
bool get esWeb => kIsWeb;
