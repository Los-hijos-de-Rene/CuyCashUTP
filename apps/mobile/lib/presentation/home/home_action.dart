/// Las cuatro acciones rápidas del inicio.
///
/// Es un enum y no el texto del botón: `QuickActionsRow` notificaba antes con
/// el copy traducido, así que renombrar una cadena en el ARB habría roto la
/// navegación sin que el compilador dijera nada.
enum HomeAction { send, charge, topUp, withdraw }
