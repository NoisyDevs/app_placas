/// "los campos vacíos no se muestran en la placa" (Historia 2.1). Cada
/// campo es nullable y null significa exactamente eso: no se carga, no se
/// renderiza. El resolver convierte esto en una lista de chips ya filtrada
/// — ver placa_resolver.dart — así el template nunca necesita un `if` para
/// decidir qué mostrar.
class Caracteristicas {
  const Caracteristicas({
    this.ambientes,
    this.dormitorios,
    this.banos,
    this.superficieM2,
    this.cochera,
  });

  final int? ambientes;
  final int? dormitorios;
  final int? banos;
  final num? superficieM2;

  /// `null` = no se preguntó / no aplica. `false` = tiene, no cuenta con
  /// cochera. Solo `true` genera un chip.
  final bool? cochera;

  bool get isEmpty =>
      ambientes == null &&
      dormitorios == null &&
      banos == null &&
      superficieM2 == null &&
      cochera == null;
}
