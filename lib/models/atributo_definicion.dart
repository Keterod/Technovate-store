class AtributoDefinicion {
  final String clave;
  final String nombre;
  final String tipo; // text, number, select, boolean, textarea
  final bool requerido;
  final bool enFiltro;
  final bool enListado;
  final int orden;
  final List<String> opciones;
  final String? opcionesRef;
  final Map<String, dynamic> validacion;

  const AtributoDefinicion({
    required this.clave,
    required this.nombre,
    this.tipo = 'text',
    this.requerido = false,
    this.enFiltro = false,
    this.enListado = false,
    this.orden = 0,
    this.opciones = const [],
    this.opcionesRef,
    this.validacion = const {},
  });

  factory AtributoDefinicion.fromMap(Map<String, dynamic> map) {
    return AtributoDefinicion(
      clave: map['clave'] as String? ?? '',
      nombre: map['nombre'] as String? ?? '',
      tipo: map['tipo'] as String? ?? 'text',
      requerido: map['requerido'] as bool? ?? false,
      enFiltro: map['enFiltro'] as bool? ?? false,
      enListado: map['enListado'] as bool? ?? false,
      orden: map['orden'] as int? ?? 0,
      opciones: (map['opciones'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      opcionesRef: map['opcionesRef'] as String?,
      validacion: Map<String, dynamic>.from(
          map['validacion'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toMap() => {
        'clave': clave,
        'nombre': nombre,
        'tipo': tipo,
        'requerido': requerido,
        'enFiltro': enFiltro,
        'enListado': enListado,
        'orden': orden,
        if (opciones.isNotEmpty) 'opciones': opciones,
        if (opcionesRef != null) 'opcionesRef': opcionesRef,
        if (validacion.isNotEmpty) 'validacion': validacion,
      };
}
