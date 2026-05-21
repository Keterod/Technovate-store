import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'digizone_utils.dart';

class DigizoneAdminScreen extends StatefulWidget {
  const DigizoneAdminScreen({super.key});

  @override
  State<DigizoneAdminScreen> createState() => _DigizoneAdminScreenState();
}

class _DigizoneAdminScreenState extends State<DigizoneAdminScreen> {
  final TextEditingController _titulo = TextEditingController();
  final TextEditingController _detalle = TextEditingController();
  final TextEditingController _fabricante = TextEditingController();
  final TextEditingController _costo = TextEditingController();
  final TextEditingController _inventario = TextEditingController();
  final TextEditingController _garantia = TextEditingController();
  final TextEditingController _puntuacion = TextEditingController();
  final TextEditingController _imagen = TextEditingController();
  final List<String> _categorias = [
    'Laptop',
    'Smartphone',
    'Tablet',
    'Monitor',
    'periférico',
    'equipo',
    'hardware',
    'software',
  ];
  String? _categoriaSeleccionada;
  bool _disponible = true;
  String? _idSeleccionado;
  String _busqueda = '';
  bool _ordenarPorPuntuacion = false;

  @override
  void dispose() {
    _titulo.dispose();
    _detalle.dispose();
    _fabricante.dispose();
    _costo.dispose();
    _inventario.dispose();
    _garantia.dispose();
    _puntuacion.dispose();
    _imagen.dispose();
    super.dispose();
  }

  String _garantiaDesdeData(Map<String, dynamic> data) {
    if (data['garantia'] != null) return data['garantia'].toString();
    final meses = data['garantiaMeses'];
    if (meses != null) return '$meses meses';
    return '';
  }

  bool _validarCampos() {
    if (_titulo.text.trim().isEmpty ||
        _costo.text.trim().isEmpty ||
        _inventario.text.trim().isEmpty ||
        _categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Campos obligatorios: título, costo, inventario y categoría',
          ),
        ),
      );
      return false;
    }

    final costo = double.tryParse(_costo.text);
    if (costo == null || costo <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El costo debe ser mayor a 0')),
      );
      return false;
    }

    final inventario = int.tryParse(_inventario.text);
    if (inventario == null || inventario < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El inventario debe ser mayor o igual a 0'),
        ),
      );
      return false;
    }

    final puntaje = double.tryParse(
      _puntuacion.text.isEmpty ? '0' : _puntuacion.text,
    );
    if (puntaje == null || puntaje < 0 || puntaje > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La puntuación debe estar entre 0 y 5')),
      );
      return false;
    }

    return true;
  }

  void _limpiarFormulario() {
    setState(() {
      _titulo.clear();
      _detalle.clear();
      _fabricante.clear();
      _costo.clear();
      _inventario.clear();
      _garantia.clear();
      _puntuacion.clear();
      _imagen.clear();
      _categoriaSeleccionada = null;
      _disponible = true;
      _idSeleccionado = null;
    });
  }

  Future<void> _guardarProducto() async {
    if (!_validarCampos()) return;
    final esEdicion = _idSeleccionado != null;

    final data = {
      'titulo': _titulo.text.trim(),
      'detalle': _detalle.text.trim(),
      'fabricante': _fabricante.text.trim(),
      'costo': double.parse(_costo.text),
      'inventario': int.parse(_inventario.text),
      'categoria': _categoriaSeleccionada,
      'disponible': _disponible,
      'garantia': _garantia.text.trim().isEmpty
          ? 'Sin garantía'
          : _garantia.text.trim(),
      'puntuacion': double.parse(
        _puntuacion.text.isEmpty ? '0' : _puntuacion.text,
      ),
      'imagen': _imagen.text.trim(),
    };

    try {
      if (_idSeleccionado == null) {
        await FirebaseFirestore.instance
            .collection(digizoneColeccion)
            .add(data);
      } else {
        await FirebaseFirestore.instance
            .collection(digizoneColeccion)
            .doc(_idSeleccionado!)
            .update(data);
      }
      _limpiarFormulario();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(esEdicion ? 'Producto actualizado' : 'Producto creado'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  Future<void> _eliminarProducto(String id) async {
    await FirebaseFirestore.instance
        .collection(digizoneColeccion)
        .doc(id)
        .delete();
    if (_idSeleccionado == id) _limpiarFormulario();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producto eliminado')),
    );
  }

  Future<void> _bajarStock(String id, int inventarioActual) async {
    if (inventarioActual <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se puede bajar más el stock (inventario en 0)'),
        ),
      );
      return;
    }
    await FirebaseFirestore.instance.collection(digizoneColeccion).doc(id).update({
      'inventario': inventarioActual - 1,
    });
  }

  void _cargarEdicion(String id, Map<String, dynamic> data) {
    setState(() {
      _idSeleccionado = id;
      _titulo.text = (data['titulo'] ?? '').toString();
      _detalle.text = (data['detalle'] ?? '').toString();
      _fabricante.text = (data['fabricante'] ?? '').toString();
      _costo.text = (data['costo'] ?? '').toString();
      _inventario.text = (data['inventario'] ?? '').toString();
      _categoriaSeleccionada = data['categoria']?.toString();
      _disponible = data['disponible'] == true;
      _garantia.text = _garantiaDesdeData(data);
      _puntuacion.text = (data['puntuacion'] ?? '0').toString();
      _imagen.text = (data['imagen'] ?? '').toString();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producto cargado para edición')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: tituloTechnovate(subtitulo: 'Admin'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titulo,
              decoration: const InputDecoration(
                labelText: 'Título',
                icon: Icon(Icons.label),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _detalle,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Detalle',
                icon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fabricante,
              decoration: const InputDecoration(
                labelText: 'Fabricante',
                icon: Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _costo,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Costo',
                icon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _inventario,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Inventario',
                icon: Icon(Icons.inventory_2),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _categoriaSeleccionada,
              items: _categorias
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => _categoriaSeleccionada = value),
              decoration: const InputDecoration(
                labelText: 'Categoría',
                icon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _garantia,
              decoration: const InputDecoration(
                labelText: 'Garantía (ej: 12 meses)',
                icon: Icon(Icons.verified),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _puntuacion,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Puntuación (0 a 5)',
                icon: Icon(Icons.star),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _imagen,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Enlace imagen (Google Drive)',
                icon: Icon(Icons.image),
              ),
            ),
            if (_imagen.text.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imagenProducto(_imagen.text, height: 120),
              ),
            ],
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text('Disponible'),
              value: _disponible,
              onChanged: (value) => setState(() => _disponible = value),
              secondary: Icon(
                _disponible ? Icons.check_circle : Icons.cancel,
                color: _disponible ? Colors.green : Colors.red,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _guardarProducto,
              icon: Icon(_idSeleccionado == null ? Icons.add : Icons.save),
              label: Text(_idSeleccionado == null ? 'Registrar' : 'Actualizar'),
            ),
            if (_idSeleccionado != null)
              TextButton.icon(
                onPressed: _limpiarFormulario,
                icon: const Icon(Icons.clear),
                label: const Text('Cancelar edición'),
              ),
            const Divider(height: 30),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar por nombre',
                icon: Icon(Icons.search),
              ),
              onChanged: (value) =>
                  setState(() => _busqueda = value.toLowerCase()),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Listado de productos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _ordenarPorPuntuacion = !_ordenarPorPuntuacion);
                  },
                  icon: Icon(
                    _ordenarPorPuntuacion ? Icons.star : Icons.swap_vert,
                    color: Colors.amber.shade800,
                  ),
                  tooltip: 'Ordenar por puntuación',
                ),
              ],
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(digizoneColeccion)
                  .orderBy('titulo')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final titulo =
                      (data['titulo'] ?? '').toString().toLowerCase();
                  return titulo.contains(_busqueda);
                }).toList();
                if (_ordenarPorPuntuacion) {
                  docs.sort((a, b) {
                    final da = a.data() as Map<String, dynamic>;
                    final db = b.data() as Map<String, dynamic>;
                    final pa = ((da['puntuacion'] ?? 0) as num).toDouble();
                    final pb = ((db['puntuacion'] ?? 0) as num).toDouble();
                    return pb.compareTo(pa);
                  });
                }
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No hay registros'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final item = docs[index];
                    final data = item.data() as Map<String, dynamic>;
                    final inventario =
                        ((data['inventario'] ?? 0) as num).toInt();
                    final stockCritico = inventario < 5;
                    return Card(
                      child: ListTile(
                        leading: SizedBox(
                          width: 56,
                          height: 56,
                          child: imagenProducto(
                            data['imagen']?.toString(),
                            height: 56,
                            width: 56,
                          ),
                        ),
                        title: Text((data['titulo'] ?? '').toString()),
                        subtitle: Text(
                          'Costo: S/. ${data['costo'] ?? 0} | Stock: $inventario'
                          '${stockCritico ? ' (crítico)' : ''}\n'
                          'Garantía: ${_garantiaDesdeData(data)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.orange,
                              ),
                              tooltip: 'Bajar stock',
                              onPressed: () =>
                                  _bajarStock(item.id, inventario),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _cargarEdicion(item.id, data),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarProducto(item.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
