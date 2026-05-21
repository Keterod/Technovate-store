import 'package:flutter/material.dart';

const String digizoneColeccion = 'digizone_productos';
const String technovateLogoAsset = 'assets/images/technovate_logo.png';
const String technovateNombre = 'TECHNOVATE';

/// Logo desde asset. Usar cuando exista `assets/images/technovate_logo.png`.
Widget logoTechnovate({double height = 28}) {
  return Image.asset(
    technovateLogoAsset,
    height: height,
    errorBuilder: (context, error, stackTrace) => Icon(
      Icons.memory,
      size: height,
      color: Colors.indigo,
    ),
  );
}

/// Título de AppBar con logo TECHNOVATE.
Widget tituloTechnovate({String? subtitulo}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      logoTechnovate(height: 26),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          subtitulo == null ? technovateNombre : '$technovateNombre - $subtitulo',
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

String convertirEnlaceDriveADirecto(String enlaceDrive) {
  final regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
  final match = regExp.firstMatch(enlaceDrive);

  if (match != null && match.groupCount >= 1) {
    final id = match.group(1);
    return 'https://drive.google.com/uc?export=view&id=$id';
  } else {
    return enlaceDrive;
  }
}

Widget imagenProducto(String? url, {double height = 120, double? width}) {
  final enlace = (url ?? '').trim();
  if (enlace.isEmpty) {
    return SizedBox(
      height: height,
      width: width ?? height,
      child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
    );
  }
  final directo = convertirEnlaceDriveADirecto(enlace);
  return Image.network(
    directo,
    height: height,
    width: width,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => SizedBox(
      height: height,
      width: width ?? height,
      child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
    ),
  );
}
