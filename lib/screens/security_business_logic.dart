class PaymentDisclaimerLogic {
  /// Analiza si el precio actual dictamina un cobro externo y requiere aviso legal.
  static bool necesitaMostrarAviso(dynamic price) {
    if (price == null) return false;

    // Si viene como número directamente
    if (price is num) {
      return price > 0;
    }

    // Si viene como String (ej: "$2000 COP" o "2000") limpiamos caracteres
    final cleanString = price.toString().replaceAll(RegExp(r'[^0-9]'), '');
    final parsedPrice = int.tryParse(cleanString) ?? 0;

    return parsedPrice > 0;
  }
}

class TermsAndConditionsLogic {
  /// Determina matemáticamente si el usuario ha leído el texto legal completo hasta el final.
  static bool haLlegadoAlFinal({
    required double pixelsActuales,
    required double scrollMaximo,
    double margenTolerancia = 10.0,
  }) {
    if (scrollMaximo <= 0) return false;
    // Si la posición actual está dentro del margen del final del documento
    return pixelsActuales >= (scrollMaximo - margenTolerancia);
  }
}
