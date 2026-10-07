/// Un nombre como se muestra: mayúscula al inicio de cada palabra (y de cada
/// parte de un apellido compuesto con guion), el resto en minúsculas.
///
/// El backend guarda los nombres en minúsculas; esto es solo presentación.
/// Un nombre enmascarado (`J*** M***`) sale igual.
String formatNombre(String crudo) => crudo
    .split(RegExp(r'\s+'))
    .where((palabra) => palabra.isNotEmpty)
    .map((palabra) => palabra.split('-').map(_capitalizar).join('-'))
    .join(' ');

String _capitalizar(String parte) => parte.isEmpty
    ? parte
    : parte[0].toUpperCase() + parte.substring(1).toLowerCase();
