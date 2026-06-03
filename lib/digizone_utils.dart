import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const String digizoneColeccion = 'digizone_productos';
const String technovateLogoAsset = 'assets/images/technovate_logo.png';
const String technovateNombre = 'TECHNOVATE';

final _formatoPrecio = NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);

String formatoPrecio(dynamic precio) {
  final valor = (precio is num) ? precio.toDouble() : 0.0;
  return _formatoPrecio.format(valor);
}

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

class SearchFilters {
  final String query;
  final double? precioMin;
  final double? precioMax;

  const SearchFilters({this.query = '', this.precioMin, this.precioMax});

  bool get tieneFiltros => query.isNotEmpty || precioMin != null || precioMax != null;

  String get descripcion {
    final parts = <String>[];
    if (query.isNotEmpty) parts.add('"$query"');
    if (precioMin != null && precioMax != null) {
      parts.add('S/ ${precioMin!.toStringAsFixed(0)} - S/ ${precioMax!.toStringAsFixed(0)}');
    } else if (precioMin != null) {
      parts.add('desde S/ ${precioMin!.toStringAsFixed(0)}');
    } else if (precioMax != null) {
      parts.add('hasta S/ ${precioMax!.toStringAsFixed(0)}');
    }
    return 'Filtros: ${parts.join(", ")}';
  }
}

String convertirEnlaceDriveADirecto(String enlaceDrive) {
  final regExp = RegExp(r'/d/([a-zA-Z0-9_-]+)');
  final match = regExp.firstMatch(enlaceDrive);
  if (match != null && match.groupCount >= 1) {
    return 'https://drive.google.com/uc?export=view&id=${match.group(1)}';
  }
  return enlaceDrive;
}

Widget imagenProducto(String? url, {double height = 120, double? width}) {
  final enlace = (url ?? '').trim();
  if (enlace.isEmpty) {
    return _placeholder(height, width);
  }
  final directo = convertirEnlaceDriveADirecto(enlace);
  return CachedNetworkImage(
    imageUrl: directo,
    height: height,
    width: width ?? height,
    fit: BoxFit.cover,
    placeholder: (_, _) => _placeholder(height, width),
    errorWidget: (_, _, _) => _placeholder(height, width, icon: Icons.broken_image),
  );
}

Widget _placeholder(double height, double? width, {IconData icon = Icons.image_not_supported}) {
  return Container(
    height: height,
    width: width ?? height,
    color: Colors.grey.shade200,
    child: Icon(icon, size: 48, color: Colors.grey),
  );
}
