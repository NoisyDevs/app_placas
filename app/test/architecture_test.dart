// Test de arquitectura: verifica mecánicamente la separación de marca de
// ARCHITECTURE.md §2 ("Separación de marca, forzada mecánicamente") en vez
// de confiar en que nadie la rompa sin querer en una revisión de código.
// Es Dart puro (dart:io + package:test, sin bindings de Flutter) — corre
// con `dart test test/architecture_test.dart`, igual que domain/.

import 'dart:io';

import 'package:test/test.dart';

Iterable<File> _dartFilesIn(String dirPath) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return const [];
  return dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
}

final _importRegex = RegExp(r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''', multiLine: true);

/// Busca imports/exports cuya ruta contenga [forbiddenSubstring], en todos
/// los archivos .dart bajo cada carpeta de [scanDirs].
List<String> _findForbiddenImports({
  required List<String> scanDirs,
  required String forbiddenSubstring,
}) {
  final offenders = <String>[];
  for (final dirPath in scanDirs) {
    for (final file in _dartFilesIn(dirPath)) {
      for (final match in _importRegex.allMatches(file.readAsStringSync())) {
        final importPath = match.group(1)!;
        if (importPath.contains(forbiddenSubstring)) {
          offenders.add('${file.path} -> "$importPath"');
        }
      }
    }
  }
  return offenders;
}

final _literalColorPatterns = [
  RegExp(r'Color\(0x'),
  RegExp(r'Color\.fromARGB\('),
  RegExp(r'Color\.fromRGBO\('),
  RegExp(r'\bColors\.\w'),
];

void main() {
  test('lib/app/** y lib/features/** nunca importan lib/placas/packs/**', () {
    final offenders = _findForbiddenImports(
      scanDirs: ['lib/app', 'lib/features'],
      forbiddenSubstring: 'placas/packs/',
    );
    expect(
      offenders,
      isEmpty,
      reason: 'La app-shell y las features deben resolver templates vía '
          'placas/registry.dart, nunca importando un pack de marca '
          'directo:\n${offenders.join('\n')}',
    );
  });

  test('lib/placas/** nunca importa lib/app/theme/**', () {
    final offenders = _findForbiddenImports(
      scanDirs: ['lib/placas'],
      forbiddenSubstring: 'app/theme/',
    );
    expect(
      offenders,
      isEmpty,
      reason: 'El motor de placas es agnóstico del design system de la app '
          '(y viceversa) — recibe un BrandTheme, no importa el tema de la '
          'app:\n${offenders.join('\n')}',
    );
  });

  test('lib/placas/kit/** no tiene colores hardcodeados', () {
    final offenders = <String>[];
    for (final file in _dartFilesIn('lib/placas/kit')) {
      final content = file.readAsStringSync();
      if (_literalColorPatterns.any((p) => p.hasMatch(content))) {
        offenders.add(file.path);
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'El kit es agnóstico de marca: los colores vienen de un '
          'BrandTheme inyectado, nunca como literal — encontrados '
          'en:\n${offenders.join('\n')}',
    );
  });

  test('lib/app/** y lib/features/** nunca mencionan "remax"', () {
    final offenders = <String>[];
    for (final dirPath in ['lib/app', 'lib/features']) {
      for (final file in _dartFilesIn(dirPath)) {
        if (file.readAsStringSync().toLowerCase().contains('remax')) {
          offenders.add(file.path);
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'La app-shell debe poder servir cualquier brand pack — '
          'RE/MAX es el primer pack, no el tema de la app (ver '
          'ARCHITECTURE.md §0). Mención encontrada en:\n${offenders.join('\n')}',
    );
  });
}
