import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

const String _localeEs = 'es_ES';

enum ComandoVoz {
  buscar,
  agregarCarrito,
  irCarrito,
  limpiarCarrito,
  eliminarCarrito,
  irUbicacion,
  irHistorial,
  ayuda,
  desconocido,
}

class ComandoParseado {
  final ComandoVoz tipo;
  final String? termino;
  final double? precioMin;
  final double? precioMax;

  ComandoParseado({
    required this.tipo,
    this.termino,
    this.precioMin,
    this.precioMax,
  });
}

class AsistenteVoz {
  final SpeechToText _speech = SpeechToText();
  bool _inicializado = false;
  String _ultimoError = '';

  String get ultimoError => _ultimoError;

  Future<bool> inicializar() async {
    if (_inicializado) return true;
    _ultimoError = '';
    try {
      _inicializado = await _speech.initialize(
        onError: (error) {
          _ultimoError = error.errorMsg;
        },
      );
      if (!_inicializado) {
        final permiso = await _speech.hasPermission;
        if (!permiso) {
          _ultimoError =
              'Permiso de micrófono denegado. Ve a Ajustes > Aplicaciones > '
              'TECHNOVATE > Permisos y activa el micrófono.';
        } else {
          _ultimoError =
              'Reconocimiento de voz no disponible. '
              'Asegúrate de tener instalado el servicio de Google Speech '
              'en tu dispositivo.';
        }
      }
      return _inicializado;
    } catch (e) {
      _ultimoError = 'Error al inicializar: $e';
      _inicializado = false;
      return false;
    }
  }

  bool get disponible => _speech.isAvailable;
  bool get escuchando => _speech.isListening;

  void escuchar({
    required void Function(String texto, bool esFinal) alResultado,
    required VoidCallback alIniciar,
    required void Function(String error) alError,
    void Function(double nivel)? alCambiarNivel,
  }) {
    if (_speech.isListening) return;
    _speech.listen(
      onResult: (result) {
        alResultado(result.recognizedWords, result.finalResult);
      },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 2),
        localeId: _localeEs,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      ),
      onSoundLevelChange: (level) => alCambiarNivel?.call(level),
    );
    alIniciar();
  }

  void detener() {
    if (_speech.isListening) _speech.stop();
  }

  void cancelar() {
    if (_speech.isListening) _speech.cancel();
  }

  void dispose() {
    _speech.cancel();
  }

  static ComandoParseado parsear(String texto) {
    final t = texto.toLowerCase().trim();
    RegExpMatch? match;
    String? term;
    double? pMin, pMax;

    match = RegExp(
      r'(?:entre|de)\s+(\d+(?:\.\d+)?)\s*(?:y|a)\s+(\d+(?:\.\d+)?)\s*(?:soles)?',
    ).firstMatch(t);
    if (match != null) {
      pMin = double.parse(match.group(1)!);
      pMax = double.parse(match.group(2)!);
      term = _extraerTermino(t.substring(0, match.start));
      return ComandoParseado(
        tipo: ComandoVoz.buscar,
        termino: term,
        precioMin: pMin,
        precioMax: pMax,
      );
    }

    match = RegExp(
      r'(?:menos\s+de|debajo\s+de|inferior\s+a|máximo)\s+(\d+(?:\.\d+)?)\s*(?:soles)?',
    ).firstMatch(t);
    if (match != null) {
      pMax = double.parse(match.group(1)!);
      term = _extraerTermino(t.substring(0, match.start));
      return ComandoParseado(
          tipo: ComandoVoz.buscar, termino: term, precioMax: pMax);
    }

    match = RegExp(
      r'(?:más\s+de|mayor\s+(?:de|a|que)|superior\s+a|mínimo)\s+(\d+(?:\.\d+)?)\s*(?:soles)?',
    ).firstMatch(t);
    if (match != null) {
      pMin = double.parse(match.group(1)!);
      term = _extraerTermino(t.substring(0, match.start));
      return ComandoParseado(
          tipo: ComandoVoz.buscar, termino: term, precioMin: pMin);
    }

    match = RegExp(
      r'(?:agrega|añade|pon|mete|agregar)\s+(.+?)\s+(?:al\s+)?carrito',
    ).firstMatch(t);
    if (match != null) {
      return ComandoParseado(
          tipo: ComandoVoz.agregarCarrito, termino: match.group(1)!.trim());
    }

    match = RegExp(
      r'(?:quita|elimina|saca|remueve|quitar)\s+(.+?)\s+(?:del\s+)?carrito',
    ).firstMatch(t);
    if (match != null) {
      return ComandoParseado(
          tipo: ComandoVoz.eliminarCarrito, termino: match.group(1)!.trim());
    }

    if (RegExp(r'(?:a|el|al|mi)\s+carrito$').hasMatch(t) ||
        RegExp(
                r'^(?:ir|muestra|ver|abrir|enseña)\s+(?:al\s+)?(?:el\s+)?(?:mi\s+)?carrito$')
            .hasMatch(t)) {
      return ComandoParseado(tipo: ComandoVoz.irCarrito);
    }

    if (RegExp(r'(?:limpia|vacía|limpiar|vaciar)\s+(?:el\s+)?carrito')
        .hasMatch(t)) {
      return ComandoParseado(tipo: ComandoVoz.limpiarCarrito);
    }

    if (RegExp(
            r'(?:ir|muestra|ver|abrir)\s+(?:a\s+)?(?:la\s+)?(?:ubicación|ubicacion|mapa|tienda)')
        .hasMatch(t)) {
      return ComandoParseado(tipo: ComandoVoz.irUbicacion);
    }

    if (RegExp(
            r'(?:ir|muestra|ver|abrir)\s+(?:al?\s+)?(?:historial|pedidos|órdenes|ordenes|compras)')
        .hasMatch(t)) {
      return ComandoParseado(tipo: ComandoVoz.irHistorial);
    }

    if (RegExp(
            r'^(?:ayuda|comandos|qué puedes hacer|help|qué haces|funciones)')
        .hasMatch(t)) {
      return ComandoParseado(tipo: ComandoVoz.ayuda);
    }

    match = RegExp(
            r'(?:busca|muestra|encuentra|enseña|mostrar|buscar|ver|quiero|necesito|dame|listar|filtrar|enséñame)\s+(.+)')
        .firstMatch(t);
    if (match != null) {
      return ComandoParseado(
          tipo: ComandoVoz.buscar, termino: match.group(1)!.trim());
    }

    if (t.length >= 3) {
      return ComandoParseado(tipo: ComandoVoz.buscar, termino: t);
    }

    return ComandoParseado(tipo: ComandoVoz.desconocido);
  }

  static String? _extraerTermino(String texto) {
    final t = texto.trim();
    final limpio = t.replaceAll(
      RegExp(
        r'^(?:busca|muestra|muéstrame|quiero|necesito|ver|mostrar|enseña|encuentra|dame|listar|enséñame|filtrar|qué\s+tal)\s+',
      ),
      '',
    );
    return limpio.trim().isNotEmpty ? limpio.trim() : null;
  }
}
