import 'package:flutter/material.dart';
import '../../core/widgets/technovate_widgets.dart';
import '../../models/product_model.dart';
import '../../viewmodels/admin_view_model.dart';

class DigizoneAdminScreen extends StatefulWidget {
  const DigizoneAdminScreen({super.key});

  @override
  State<DigizoneAdminScreen> createState() => _DigizoneAdminScreenState();
}

class _DigizoneAdminScreenState extends State<DigizoneAdminScreen> {
  final AdminViewModel _viewModel = AdminViewModel();

  final TextEditingController _titulo = TextEditingController();
  final TextEditingController _detalle = TextEditingController();
  final TextEditingController _fabricante = TextEditingController();
  final TextEditingController _costo = TextEditingController();
  final TextEditingController _inventario = TextEditingController();
  final TextEditingController _garantia = TextEditingController();
  final TextEditingController _puntuacion = TextEditingController();
  final TextEditingController _imagen = TextEditingController();

  // Nuevos campos técnicos
  final TextEditingController _ram = TextEditingController();
  final TextEditingController _procesador = TextEditingController();
  final TextEditingController _gpu = TextEditingController();
  final TextEditingController _almacenamiento = TextEditingController();
  final TextEditingController _socket = TextEditingController();
  final TextEditingController _tipoRam = TextEditingController();
  final TextEditingController _potenciaFuente = TextEditingController();

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
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _titulo.dispose();
    _detalle.dispose();
    _fabricante.dispose();
    _costo.dispose();
    _inventario.dispose();
    _garantia.dispose();
    _puntuacion.dispose();
    _imagen.dispose();

    _ram.dispose();
    _procesador.dispose();
    _gpu.dispose();
    _almacenamiento.dispose();
    _socket.dispose();
    _tipoRam.dispose();
    _potenciaFuente.dispose();

    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
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

      _ram.clear();
      _procesador.clear();
      _gpu.clear();
      _almacenamiento.clear();
      _socket.clear();
      _tipoRam.clear();
      _potenciaFuente.clear();
    });
  }

  Future<void> _guardarProducto() async {
    if (!_validarCampos()) return;
    final esEdicion = _idSeleccionado != null;

    final especificaciones = {
      if (_ram.text.trim().isNotEmpty) 'ram': _ram.text.trim(),
      if (_procesador.text.trim().isNotEmpty) 'procesador': _procesador.text.trim(),
      if (_gpu.text.trim().isNotEmpty) 'gpu': _gpu.text.trim(),
      if (_almacenamiento.text.trim().isNotEmpty) 'almacenamiento': _almacenamiento.text.trim(),
      if (_socket.text.trim().isNotEmpty) 'socket': _socket.text.trim(),
      if (_tipoRam.text.trim().isNotEmpty) 'tipoRam': _tipoRam.text.trim(),
      if (_potenciaFuente.text.trim().isNotEmpty)
        'potenciaFuente': int.tryParse(_potenciaFuente.text.trim()) ?? 0,
    };

    // Auto-generación de tags básicos para mejorar el recomendador de Gemini
    final tags = <String>[];
    if (_categoriaSeleccionada != null) tags.add(_categoriaSeleccionada!.toLowerCase());
    if (_fabricante.text.isNotEmpty) tags.add(_fabricante.text.toLowerCase());
    if (_socket.text.isNotEmpty) tags.add(_socket.text.toLowerCase());
    if (_tipoRam.text.isNotEmpty) tags.add(_tipoRam.text.toLowerCase());

    final usoRecomendado = <String>[];
    final tituloLower = _titulo.text.toLowerCase();
    final detalleLower = _detalle.text.toLowerCase();
    if (tituloLower.contains('gaming') || _gpu.text.isNotEmpty) {
      usoRecomendado.add('gaming');
    }
    if (tituloLower.contains('laptop') || detalleLower.contains('portatil')) {
      usoRecomendado.add('oficina/estudio');
    }
    if (_ram.text.contains('16') || _ram.text.contains('32') || _procesador.text.contains('Ryzen 7') || _procesador.text.contains('i7')) {
      usoRecomendado.add('programacion');
      usoRecomendado.add('diseno grafico');
    }

    try {
      await _viewModel.guardarProducto(
        id: _idSeleccionado,
        titulo: _titulo.text.trim(),
        detalle: _detalle.text.trim(),
        fabricante: _fabricante.text.trim(),
        costo: double.parse(_costo.text),
        inventario: int.parse(_inventario.text),
        categoria: _categoriaSeleccionada!,
        disponible: _disponible,
        garantia: _garantia.text.trim(),
        puntuacion: double.parse(_puntuacion.text.isEmpty ? '0' : _puntuacion.text),
        imagen: _imagen.text.trim(),
        especificaciones: especificaciones,
        tags: tags,
        usoRecomendado: usoRecomendado,
      );

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

  void _cargarEdicion(ProductModel product) {
    setState(() {
      _idSeleccionado = product.id;
      _titulo.text = product.titulo;
      _detalle.text = product.detalle;
      _fabricante.text = product.fabricante;
      _costo.text = product.costo.toString();
      _inventario.text = product.inventario.toString();
      _categoriaSeleccionada = product.categoria;
      _disponible = product.disponible;
      _garantia.text = product.garantia;
      _puntuacion.text = product.puntuacion.toString();
      _imagen.text = product.imagen;

      _ram.text = product.ram;
      _procesador.text = product.procesador;
      _gpu.text = product.gpu;
      _almacenamiento.text = product.almacenamiento;
      _socket.text = product.socket;
      _tipoRam.text = product.tipoRam;
      _potenciaFuente.text = product.potenciaFuente > 0 ? product.potenciaFuente.toString() : '';
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
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Sección Formulario
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Detalle / Descripción corta',
                        icon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _fabricante,
                            decoration: const InputDecoration(
                              labelText: 'Fabricante',
                              icon: Icon(Icons.business),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _categoriaSeleccionada,
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
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _costo,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Costo (S/.)',
                              icon: Icon(Icons.attach_money),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _inventario,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Inventario',
                              icon: Icon(Icons.inventory_2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _garantia,
                            decoration: const InputDecoration(
                              labelText: 'Garantía (ej: 12 meses)',
                              icon: Icon(Icons.verified),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _puntuacion,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                              labelText: 'Puntuación (0 a 5)',
                              icon: Icon(Icons.star),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _imagen,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Enlace imagen (Google Drive / URL)',
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
                    // Expander para las especificaciones técnicas solicitadas
                    ExpansionTile(
                      leading: const Icon(Icons.settings_suggest, color: Colors.blueGrey),
                      title: const Text(
                        'Especificaciones Técnicas (Compatibilidad)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _procesador,
                                decoration: const InputDecoration(labelText: 'Procesador (CPU)'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _socket,
                                decoration: const InputDecoration(labelText: 'Socket (ej. AM4, LGA1700)'),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _ram,
                                decoration: const InputDecoration(labelText: 'RAM (ej: 16 GB)'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _tipoRam,
                                decoration: const InputDecoration(labelText: 'Tipo RAM (DDR4 / DDR5)'),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _gpu,
                                decoration: const InputDecoration(labelText: 'GPU / Tarjeta Gráfica'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _almacenamiento,
                                decoration: const InputDecoration(labelText: 'Almacenamiento'),
                              ),
                            ),
                          ],
                        ),
                        TextField(
                          controller: _potenciaFuente,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Potencia Fuente Requerida/Suministrada (Watts)',
                          ),
                        ),
                      ],
                    ),

                    SwitchListTile(
                      title: const Text('Disponible para la venta'),
                      value: _disponible,
                      onChanged: (value) => setState(() => _disponible = value),
                      secondary: Icon(
                        _disponible ? Icons.check_circle : Icons.cancel,
                        color: _disponible ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _viewModel.isSaving ? null : _guardarProducto,
                          icon: Icon(_idSeleccionado == null ? Icons.add : Icons.save),
                          label: Text(_idSeleccionado == null ? 'Registrar' : 'Actualizar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueGrey.shade800,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        if (_idSeleccionado != null)
                          TextButton.icon(
                            onPressed: _limpiarFormulario,
                            icon: const Icon(Icons.clear),
                            label: const Text('Cancelar edición'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
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
            StreamBuilder<List<ProductModel>>(
              stream: _viewModel.watchAllProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var products = snapshot.data!.where((product) {
                  return product.titulo.toLowerCase().contains(_busqueda);
                }).toList();

                if (_ordenarPorPuntuacion) {
                  products.sort((a, b) => b.puntuacion.compareTo(a.puntuacion));
                }

                if (products.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('No hay registros'),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final stockCritico = product.inventario < 5;
                    return Card(
                      child: ListTile(
                        leading: SizedBox(
                          width: 56,
                          height: 56,
                          child: imagenProducto(
                            product.imagen,
                            height: 56,
                            width: 56,
                          ),
                        ),
                        title: Text(product.titulo),
                        subtitle: Text(
                          'Costo: S/. ${product.costo} | Stock: ${product.inventario}'
                          '${stockCritico ? ' (crítico)' : ''}\n'
                          'Garantía: ${product.garantia}',
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
                                  _viewModel.bajarStock(product.id, product.inventario),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _cargarEdicion(product),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _viewModel.eliminarProducto(product.id),
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
