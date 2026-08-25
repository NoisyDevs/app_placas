import 'property_enums.dart';

/// "puedo ingresar precio (con opción de ocultarlo / mostrar 'Consultar')"
/// (Historia 2.1). Sealed a propósito: el resolver y la UI se resuelven con
/// un `switch` exhaustivo, sin un `bool ocultar` + un `num?` que puedan
/// quedar inconsistentes entre sí.
sealed class Precio {
  const Precio();
}

class PrecioMonto extends Precio {
  const PrecioMonto({required this.monto, required this.moneda}) : assert(monto > 0);

  final num monto;
  final Moneda moneda;
}

class PrecioConsultar extends Precio {
  const PrecioConsultar();
}
