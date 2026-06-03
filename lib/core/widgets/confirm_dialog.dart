import 'package:flutter/material.dart';

Future<bool> mostrarConfirmacion(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  String confirmar = 'Eliminar',
  String cancelar = 'Cancelar',
  IconData icono = Icons.warning_rounded,
  Color? colorConfirmar,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(icono, color: colorConfirmar ?? Colors.red, size: 24),
          const SizedBox(width: 8),
          Expanded(child: Text(titulo)),
        ],
      ),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelar),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: colorConfirmar ?? Colors.red,
          ),
          child: Text(confirmar),
        ),
      ],
    ),
  );
  return result ?? false;
}
