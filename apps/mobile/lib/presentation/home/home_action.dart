/// Las cuatro acciones rápidas del inicio.
///
/// Es un enum y no el texto del botón: `QuickActionsRow` notificaba antes con
/// el copy traducido, así que renombrar una cadena en el ARB habría roto la
/// navegación sin que el compilador dijera nada.
enum HomeAction {
  send(ready: true),
  charge(ready: false),
  topUp(ready: true),
  withdraw(ready: false);

  const HomeAction({required this.ready});

  /// Tiene pantalla detrás. Las que no, se ocultan del inicio en vez de
  /// mostrarse para avisar "próximamente": se vuelven visibles cambiando esto.
  final bool ready;
}
