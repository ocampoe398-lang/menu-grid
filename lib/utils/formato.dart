/// Formatea un precio entero en centavos a string con símbolo $.
/// Ejemplo: formatPrecio(1250) → "$12.50"
/// Ejemplo: formatPrecio(0) → "$0.00"
String formatPrecio(int centavos) {
  if (centavos < 0) centavos = 0;
  final double valor = centavos / 100;
  return '\$${valor.toStringAsFixed(2)}';
}

/// Formatea una fecha DateTime a string legible.
/// Ejemplo: formatFecha(DateTime(2024, 3, 15)) → "15/03/2024"
String formatFecha(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final anio = fecha.year.toString();
  return '$dia/$mes/$anio';
}
