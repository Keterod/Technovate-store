import 'package:flutter/material.dart';
import '../models/atributo_definicion.dart';

class DynamicAtributosForm extends StatelessWidget {
  final List<AtributoDefinicion> definiciones;
  final Map<String, dynamic> valores;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const DynamicAtributosForm({
    super.key,
    required this.definiciones,
    required this.valores,
    required this.onChanged,
  });

  void _setValor(String clave, dynamic valor) {
    final nuevos = Map<String, dynamic>.from(valores);
    if (valor == null || (valor is String && valor.trim().isEmpty)) {
      nuevos.remove(clave);
    } else {
      nuevos[clave] = valor;
    }
    onChanged(nuevos);
  }

  @override
  Widget build(BuildContext context) {
    final ordenadas = List<AtributoDefinicion>.from(definiciones)
      ..sort((a, b) => a.orden.compareTo(b.orden));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ordenadas.map((attr) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildField(attr),
        );
      }).toList(),
    );
  }

  Widget _buildField(AtributoDefinicion attr) {
    final valor = valores[attr.clave];

    switch (attr.tipo) {
      case 'select':
        return _buildDropdown(attr, valor);
      case 'boolean':
        return _buildSwitch(attr, valor);
      case 'textarea':
        return _buildTextField(attr, valor, maxLines: 4);
      default:
        return _buildTextField(attr, valor);
    }
  }

  Widget _buildTextField(AtributoDefinicion attr, dynamic valor,
      {int maxLines = 1}) {
    final label = attr.requerido ? '${attr.nombre} *' : attr.nombre;
    final texto = valor?.toString() ?? '';
    return TextField(
      controller: TextEditingController(text: texto)
        ..selection = TextSelection.collapsed(offset: texto.length),
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Ingrese ${attr.nombre.toLowerCase()}',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (v) => _setValor(attr.clave, v),
    );
  }

  Widget _buildDropdown(AtributoDefinicion attr, dynamic valor) {
    final opciones = attr.opciones;
    final label = attr.requerido ? '${attr.nombre} *' : attr.nombre;

    return DropdownButtonFormField<String>(
      value: opciones.contains(valor?.toString()) ? valor.toString() : null,
      items: [
        const DropdownMenuItem(value: null, child: Text('Seleccione...')),
        ...opciones.map((o) => DropdownMenuItem(value: o, child: Text(o))),
      ],
      onChanged: (v) => _setValor(attr.clave, v),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      ),
    );
  }

  Widget _buildSwitch(AtributoDefinicion attr, dynamic valor) {
    return Card(
      child: SwitchListTile(
        title: Text(attr.nombre),
        subtitle: Text(valor == true ? 'Sí' : 'No'),
        value: valor == true,
        onChanged: (v) => _setValor(attr.clave, v),
      ),
    );
  }
}
