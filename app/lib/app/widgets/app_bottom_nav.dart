import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Barra inferior "Inicio / crear (FAB central) / Historial" del mockup
/// (pantalla Home).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.onHome,
    required this.onCreate,
    required this.onHistory,
    this.currentIsHome = true,
  });

  final VoidCallback onHome;
  final VoidCallback onCreate;
  final VoidCallback onHistory;
  final bool currentIsHome;

  /// Alto total fijo (contenido ~54px + padding vertical 8+14). Necesario
  /// para que este widget se pueda usar como `Scaffold.bottomNavigationBar`
  /// — ver el comentario largo más abajo.
  static const double _height = 76;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height,
      padding: const EdgeInsets.fromLTRB(30, 8, 30, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Row(
        children: [
          Expanded(child: _navItem(Icons.home_rounded, 'Inicio', currentIsHome, onHome)),
          Expanded(
            child: Center(
              // Transform.translate en vez de un margin negativo: Container
              // traduce `margin` a un Padding internamente, y Padding no
              // admite valores negativos (asserted en debug — en release el
              // assert se descarta y el layout entero de este Row se rompe
              // en silencio, tirando la barra completa fuera de posición).
              child: Transform.translate(
                offset: const Offset(0, -8),
                child: InkWell(
                  onTap: onCreate,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.add_rounded, color: AppColors.white, size: 24),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: _navItem(Icons.grid_view_rounded, 'Historial', !currentIsHome, onHistory)),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool active, VoidCallback onTap) {
    final color = active ? AppColors.primary : AppColors.textSubtle;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

// Por qué `height: _height` en el Container de arriba NO es opcional:
//
// `Scaffold.bottomNavigationBar` recibe un widget y necesita saber cuánto
// espacio reservarle en la parte de abajo. Si ese widget (o cualquier
// ancestro directo de un `Row`/`Column` con hijos `Expanded`/`Flexible`) no
// tiene una altura EXPLÍCITA, en algún punto del pipeline de layout se
// termina pidiendo el alto intrínseco de ese `Row` — y un `RenderFlex` con
// hijos de flex no-cero NO PUEDE responder eso (es una limitación conocida
// y documentada de Flutter: "Flexible/Expanded does not support returning
// intrinsic dimensions"). El resultado no es una excepción ruidosa: el
// `Scaffold` entero (body y bottomNavigationBar) queda con la altura
// colapsada a la mitad de la pantalla, sin ningún error en consola. Un
// `Row` sin `Expanded` (con `MainAxisAlignment.spaceAround`) no rompe, pero
// pierde el centrado exacto del FAB entre "Inicio" e "Historial" (que
// tienen ancho de texto distinto). Darle una altura fija al `Container` es
// lo que evita que se necesite consultar el alto intrínseco del `Row`.
