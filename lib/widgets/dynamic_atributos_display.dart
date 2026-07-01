import 'package:flutter/material.dart';
import '../models/atributo_definicion.dart';

class DynamicAtributosDisplay extends StatelessWidget {
  final List<AtributoDefinicion> definiciones;
  final Map<String, dynamic> valores;

  const DynamicAtributosDisplay({
    super.key,
    required this.definiciones,
    required this.valores,
  });

  @override
  Widget build(BuildContext context) {
    final ordenadas = List<AtributoDefinicion>.from(definiciones)
      ..sort((a, b) => a.orden.compareTo(b.orden));

    final pares = ordenadas
        .where((a) => valores.containsKey(a.clave) && valores[a.clave] != null)
        .map((a) {
      final v = valores[a.clave];
      final display = v is bool ? (v ? 'Sí' : 'No') : v.toString();
      return MapEntry(a.nombre, display);
    }).toList();

    if (pares.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_suggest_outlined,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Especificaciones técnicas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...pares.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
