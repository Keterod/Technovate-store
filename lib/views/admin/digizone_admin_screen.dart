import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/session/session_manager.dart';
import '../../core/widgets/technovate_widgets.dart';
import '../../models/admin_order_item.dart';
import '../../models/categoria_model.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../services/categoria_service.dart';
import '../../services/seed_service.dart';
import '../../viewmodels/admin_view_model.dart';

class DigizoneAdminScreen extends StatefulWidget {
  const DigizoneAdminScreen({super.key});

  @override
  State<DigizoneAdminScreen> createState() => _DigizoneAdminScreenState();
}

class _DigizoneAdminScreenState extends State<DigizoneAdminScreen>
    with SingleTickerProviderStateMixin {
  final AdminViewModel _viewModel = AdminViewModel();
  final CategoriaService _categoriaService = CategoriaService();
  late final Stream<List<AdminOrderItem>> _ordersStream;

  final TextEditingController _titulo = TextEditingController();
  final TextEditingController _detalle = TextEditingController();
  final TextEditingController _fabricante = TextEditingController();
  final TextEditingController _costo = TextEditingController();
  final TextEditingController _inventario = TextEditingController();
  final TextEditingController _garantia = TextEditingController();
  final TextEditingController _puntuacion = TextEditingController();
  final TextEditingController _imagen = TextEditingController();
  final TextEditingController _busquedaCtrl = TextEditingController();
  final TextEditingController _especificacionesCtrl = TextEditingController();

  List<CategoriaModel> _categorias = [];
  Map<String, dynamic> _atributosActuales = {};
  String? _categoriaSeleccionada;
  String? _filtroCategoria;
  bool _disponible = true;
  String? _idSeleccionado;
  TabController? _tabController;
  String _busqueda = '';
  String _sortField = '';
  bool _sortAsc = true;
  int _seccionIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _ordersStream = _viewModel.watchAllOrders();
    _viewModel.addListener(_onViewModelChanged);
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final cats = await _categoriaService.getCategorias();
      if (mounted) {
        setState(() => _categorias = cats);
        if (cats.isEmpty) {
          _mostrarSnack(
            'No hay categorías. Usa el menú ⋮ → Importar categorías',
          );
        }
      }
    } catch (e) {
      if (mounted) _mostrarSnack('Error al cargar categorías: $e');
    }
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
    _busquedaCtrl.dispose();
    _especificacionesCtrl.dispose();
    _tabController?.dispose();
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
      _mostrarSnack(
        'Campos obligatorios: título, costo, inventario y categoría',
      );
      return false;
    }

    final costo = double.tryParse(_costo.text);
    if (costo == null || costo <= 0) {
      _mostrarSnack('El costo debe ser mayor a 0');
      return false;
    }

    final inventario = int.tryParse(_inventario.text);
    if (inventario == null || inventario < 0) {
      _mostrarSnack('El inventario debe ser mayor o igual a 0');
      return false;
    }

    final puntaje = double.tryParse(
      _puntuacion.text.isEmpty ? '0' : _puntuacion.text,
    );
    if (puntaje == null || puntaje < 0 || puntaje > 5) {
      _mostrarSnack('La puntuación debe estar entre 0 y 5');
      return false;
    }

    return true;
  }

  void _mostrarSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
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
      _atributosActuales = {};
      _especificacionesCtrl.clear();
    });
  }

  Future<void> _guardarProducto() async {
    if (!_validarCampos()) return;
    final esEdicion = _idSeleccionado != null;

    final tags = <String>[];
    if (_categoriaSeleccionada != null) {
      tags.add(_categoriaSeleccionada!.toLowerCase());
    }
    if (_fabricante.text.isNotEmpty) tags.add(_fabricante.text.toLowerCase());

    final usoRecomendado = <String>[];
    final tituloLower = _titulo.text.toLowerCase();
    final detalleLower = _detalle.text.toLowerCase();
    final gpuVal = _atributosActuales['gpu']?.toString().toLowerCase() ?? '';
    final ramVal = _atributosActuales['ram']?.toString().toLowerCase() ?? '';
    final procVal =
        _atributosActuales['procesador']?.toString().toLowerCase() ?? '';

    if (tituloLower.contains('gaming') || gpuVal.isNotEmpty) {
      usoRecomendado.add('gaming');
    }
    if (tituloLower.contains('laptop') || detalleLower.contains('portatil')) {
      usoRecomendado.add('oficina/estudio');
    }
    if (ramVal.contains('16') ||
        ramVal.contains('32') ||
        procVal.contains('ryzen 7') ||
        procVal.contains('i7')) {
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
        puntuacion: double.parse(
          _puntuacion.text.isEmpty ? '0' : _puntuacion.text,
        ),
        imagen: _imagen.text.trim(),
        especificaciones: {'especificaciones': _especificacionesCtrl.text},
        tags: tags,
        usoRecomendado: usoRecomendado,
      );

      _limpiarFormulario();
      _mostrarSnack(esEdicion ? 'Producto actualizado' : 'Producto creado');
    } catch (e) {
      _mostrarSnack('Error al guardar: $e');
    }
  }

  void _irAFormulario() => _tabController?.animateTo(0);

  void _cargarEdicion(ProductModel product) {
    try {
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
        _atributosActuales = Map<String, dynamic>.from(
          product.especificaciones,
        );
        _especificacionesCtrl.text =
            product.especificaciones['especificaciones']?.toString() ?? '';
      });
    } catch (e) {
      _mostrarSnack('Error al cargar producto: $e');
    }
  }

  Future<bool> _confirmarEliminacion(ProductModel product) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${product.titulo}" permanentemente?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SessionManager.resetNavigationToRoot();
      });
      return const Scaffold(body: Center(child: Text('Sesión cerrada')));
    }

    if (kIsWeb) {
      final theme = Theme.of(context);
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _seccionIndex,
              onDestinationSelected: (i) => setState(() => _seccionIndex = i),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: tituloTechnovate(subtitulo: 'Admin'),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: Text('Productos'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: Text('Pedidos'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(_tituloSeccion, style: theme.textTheme.titleLarge),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (v) async {
                            if (v == 'seed') {
                              try {
                                final count = await SeedService()
                                    .importarCategorias();
                                _mostrarSnack('$count categorías importadas');
                                _cargarCategorias();
                              } catch (e) {
                                _mostrarSnack('Error: $e');
                              }
                            } else if (v == 'seed_sucursales') {
                              try {
                                final count = await SeedService()
                                    .importarSucursales();
                                _mostrarSnack('$count sucursales importadas');
                              } catch (e) {
                                _mostrarSnack('Error: $e');
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'seed',
                              child: Text('Importar categorías'),
                            ),
                            const PopupMenuItem(
                              value: 'seed_sucursales',
                              child: Text('Importar sucursales'),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout),
                          tooltip: 'Cerrar sesión',
                          onPressed: _cerrarSesion,
                        ),
                        if (_seccionIndex == 1)
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: OutlinedButton.icon(
                              onPressed: _limpiarFormulario,
                              icon: const Icon(Icons.add),
                              label: const Text('Nuevo Producto'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildWebContent(context)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: tituloTechnovate(subtitulo: 'Admin'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) async {
              if (v == 'seed') {
                try {
                  final count = await SeedService().importarCategorias();
                  _mostrarSnack('$count categorías importadas');
                  _cargarCategorias();
                } catch (e) {
                  _mostrarSnack('Error: $e');
                }
              } else if (v == 'seed_sucursales') {
                try {
                  final count = await SeedService().importarSucursales();
                  _mostrarSnack('$count sucursales importadas');
                } catch (e) {
                  _mostrarSnack('Error: $e');
                }
              } else if (v == 'logout') {
                await _cerrarSesion();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'seed',
                child: Text('Importar categorías'),
              ),
              const PopupMenuItem(
                value: 'seed_sucursales',
                child: Text('Importar sucursales'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar sesión'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_box_outlined), text: 'Formulario'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Productos'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Pedidos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildForm(context),
          ),
          Column(
            children: [
              _buildMobileFilters(context),
              Expanded(child: _buildProductList(context)),
            ],
          ),
          _buildOrdersSection(context),
        ],
      ),
    );
  }

  // ─── FORMULARIO ───────────────────────────────────────────────

  String get _tituloSeccion {
    switch (_seccionIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Productos';
      case 2:
        return 'Pedidos';
      default:
        return '';
    }
  }

  Widget _buildWebContent(BuildContext context) {
    switch (_seccionIndex) {
      case 0:
        return _buildDashboard(context);
      case 1:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 420,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildForm(context),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  _buildWebFilters(context),
                  Expanded(child: _buildProductList(context)),
                ],
              ),
            ),
          ],
        );
      case 2:
        return _buildOrdersSection(context);
      default:
        return const SizedBox();
    }
  }

  Widget _buildForm(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = _idSeleccionado != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _formSectionHeader(theme, Icons.info_outline, 'Información básica'),
        const SizedBox(height: 12),
        TextField(
          controller: _titulo,
          decoration: const InputDecoration(
            labelText: 'Título del producto',
            hintText: 'Ej: Laptop Gamer XYZ 2025',
            prefixIcon: Icon(Icons.label_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _detalle,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            hintText: 'Describe las características principales...',
            prefixIcon: Icon(Icons.description_outlined),
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _fabricante,
                decoration: const InputDecoration(
                  labelText: 'Fabricante',
                  prefixIcon: Icon(Icons.business_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _categoriaSeleccionada,
                items: _categorias
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.nombre,
                        child: Text(c.nombre),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() {
                  _categoriaSeleccionada = v;
                  _atributosActuales = {};
                }),
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _formSectionHeader(theme, Icons.payments_outlined, 'Precio y Stock'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _costo,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Costo (S/.)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _inventario,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Inventario',
                  prefixIcon: Icon(Icons.inventory_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _garantia,
                decoration: const InputDecoration(
                  labelText: 'Garantía',
                  hintText: 'Ej: 12 meses',
                  prefixIcon: Icon(Icons.verified_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _puntuacion,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Puntuación (0-5)',
                  prefixIcon: Icon(Icons.star_outline),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _formSectionHeader(theme, Icons.image_outlined, 'Imagen'),
        const SizedBox(height: 12),
        TextField(
          controller: _imagen,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'URL de imagen',
            hintText: 'Google Drive / URL directa',
            prefixIcon: Icon(Icons.image_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        if (_imagen.text.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imagenProducto(_imagen.text, height: 130),
          ),
        ],
        const SizedBox(height: 20),
        _formSectionHeader(
          theme,
          Icons.settings_suggest_outlined,
          'Especificaciones Técnicas',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _especificacionesCtrl,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: 'Especificaciones técnicas',
            hintText: 'Describe las especificaciones del producto...',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: theme.colorScheme.surfaceContainerHighest,
          child: SwitchListTile(
            secondary: const Icon(Icons.check_circle_outline),
            title: const Text('Disponible para venta'),
            value: _disponible,
            onChanged: (v) => setState(() => _disponible = v),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _viewModel.isSaving ? null : _guardarProducto,
                icon: Icon(
                  isEditing ? Icons.save_outlined : Icons.add_circle_outline,
                ),
                label: Text(
                  isEditing ? 'Actualizar Producto' : 'Registrar Producto',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 15),
                ),
              ),
            ),
            if (isEditing) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _limpiarFormulario,
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _formSectionHeader(ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ─── FILTROS ──────────────────────────────────────────────────

  Widget _buildWebFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              controller: _busquedaCtrl,
              decoration: const InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: Icon(Icons.search, size: 20),
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
              onChanged: (v) => setState(() => _busqueda = v.toLowerCase()),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              value: _filtroCategoria,
              items: const [
                DropdownMenuItem(value: null, child: Text('Todas')),
                DropdownMenuItem(value: 'Laptop', child: Text('Laptop')),
                DropdownMenuItem(
                  value: 'Smartphone',
                  child: Text('Smartphone'),
                ),
                DropdownMenuItem(value: 'Tablet', child: Text('Tablet')),
                DropdownMenuItem(value: 'Monitor', child: Text('Monitor')),
                DropdownMenuItem(
                  value: 'periférico',
                  child: Text('Periféricos'),
                ),
                DropdownMenuItem(value: 'hardware', child: Text('Componentes')),
                DropdownMenuItem(value: 'equipo', child: Text('Equipos')),
                DropdownMenuItem(value: 'software', child: Text('Software')),
              ],
              onChanged: (v) => setState(() => _filtroCategoria = v),
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _sortButton(Icons.star, 'Puntuación', 'puntuacion'),
          const Spacer(),
          _buildStatsChip(context),
        ],
      ),
    );
  }

  Widget _buildMobileFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: _busquedaCtrl,
            decoration: const InputDecoration(
              hintText: 'Buscar producto...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _busqueda = v.toLowerCase()),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtroCategoria,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    ..._categorias.map(
                      (c) => DropdownMenuItem(
                        value: c.nombre,
                        child: Text(c.nombre),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _filtroCategoria = v),
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _sortButton(Icons.star, 'Ordenar', 'puntuacion'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sortButton(IconData icon, String tooltip, String field) {
    final active = _sortField == field;
    return IconButton(
      onPressed: () {
        setState(() {
          if (_sortField == field) {
            _sortAsc = !_sortAsc;
          } else {
            _sortField = field;
            _sortAsc = false;
          }
        });
      },
      icon: Icon(active ? Icons.sort : icon),
      isSelected: active,
      selectedIcon: Icon(_sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
      tooltip: tooltip,
    );
  }

  Widget _buildStatsChip(BuildContext context) {
    return StreamBuilder<List<ProductModel>>(
      stream: _viewModel.watchAllProducts(),
      builder: (context, snapshot) {
        final products = snapshot.data ?? [];
        final total = products.length;
        final lowStock = products
            .where((p) => p.inventario > 0 && p.inventario <= 5)
            .length;
        final sinStock = products
            .where((p) => !p.disponible || p.inventario == 0)
            .length;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _chip(
              Icons.inventory_2_outlined,
              '$total total',
              Colors.blue,
              context,
            ),
            const SizedBox(width: 6),
            _chip(
              Icons.warning_amber_outlined,
              '$lowStock stock bajo',
              Colors.orange,
              context,
            ),
            const SizedBox(width: 6),
            _chip(
              Icons.block_flipped,
              '$sinStock agotados',
              Colors.red,
              context,
            ),
          ],
        );
      },
    );
  }

  Widget _chip(IconData icon, String label, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── LISTA DE PRODUCTOS ───────────────────────────────────────

  Widget _buildProductList(BuildContext context) {
    return StreamBuilder<List<ProductModel>>(
      stream: _viewModel.watchAllProducts(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var products = snapshot.data!.where((p) {
          if (_busqueda.isNotEmpty &&
              !p.titulo.toLowerCase().contains(_busqueda)) {
            return false;
          }
          if (_filtroCategoria != null &&
              p.categoria.toLowerCase() != _filtroCategoria!.toLowerCase()) {
            return false;
          }
          return true;
        }).toList();

        if (_sortField == 'puntuacion') {
          products.sort(
            (a, b) => _sortAsc
                ? a.puntuacion.compareTo(b.puntuacion)
                : b.puntuacion.compareTo(a.puntuacion),
          );
        }

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  _busqueda.isNotEmpty || _filtroCategoria != null
                      ? 'No hay productos que coincidan con los filtros'
                      : 'No hay productos registrados',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                ),
                if (_busqueda.isNotEmpty || _filtroCategoria != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      _busquedaCtrl.clear();
                      setState(() {
                        _busqueda = '';
                        _filtroCategoria = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Limpiar filtros'),
                  ),
                ],
              ],
            ),
          );
        }

        if (kIsWeb) {
          return _buildDataTable(context, products);
        }
        return _buildMobileList(context, products);
      },
    );
  }

  Widget _buildDataTable(BuildContext context, List<ProductModel> products) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: MediaQuery.of(context).size.width > 900 ? null : 900,
        child: SingleChildScrollView(
          child: DataTable(
            sortColumnIndex: _sortField == 'puntuacion' ? 4 : null,
            sortAscending: _sortAsc,
            headingRowHeight: 48,
            dataRowMinHeight: 56,
            dataRowMaxHeight: 72,
            columnSpacing: 16,
            horizontalMargin: 16,
            headingRowColor: WidgetStatePropertyAll(
              theme.colorScheme.surfaceContainerHighest,
            ),
            columns: [
              DataColumn(
                label: Text(
                  'Producto',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Categoría',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataColumn(
                label: Text(
                  'Precio',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'Stock',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                numeric: true,
              ),
              DataColumn(
                label: Text(
                  'Rating',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                numeric: true,
                onSort: (_, asc) => setState(() {
                  _sortField = 'puntuacion';
                  _sortAsc = asc;
                }),
              ),
              DataColumn(
                label: Text('', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
            rows: products.map((product) {
              return DataRow(
                onLongPress: () => _cargarEdicion(product),
                cells: [
                  DataCell(
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: imagenProducto(
                              product.imagen,
                              height: 44,
                              width: 44,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                product.titulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (product.fabricante.isNotEmpty)
                                Text(
                                  product.fabricante,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(_buildCategoryChip(product.categoria)),
                  DataCell(
                    Text(
                      'S/. ${product.costo.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  DataCell(
                    Text(
                      product.inventario.toString(),
                      style: TextStyle(
                        color: product.inventario <= 5
                            ? Colors.orange.shade700
                            : product.inventario == 0
                            ? Colors.red
                            : null,
                        fontWeight: product.inventario <= 5
                            ? FontWeight.w600
                            : null,
                      ),
                    ),
                  ),
                  DataCell(_buildRating(product.puntuacion)),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          iconSize: 20,
                          tooltip: 'Editar',
                          onPressed: () {
                            _cargarEdicion(product);
                            _irAFormulario();
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          iconSize: 20,
                          tooltip: 'Eliminar',
                          onPressed: () async {
                            if (await _confirmarEliminacion(product)) {
                              try {
                                await _viewModel.eliminarProducto(product.id);
                                _mostrarSnack('Producto eliminado');
                              } catch (e) {
                                _mostrarSnack('Error al eliminar: $e');
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<ProductModel> products) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              _cargarEdicion(product);
              _irAFormulario();
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imagenProducto(
                      product.imagen,
                      height: 56,
                      width: 56,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildCategoryChip(
                              product.categoria,
                              compact: true,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'S/. ${product.costo.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildRating(product.puntuacion, compact: true),
                            const Spacer(),
                            _stockBadge(product),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Editar',
                        onPressed: () {
                          _cargarEdicion(product);
                          _irAFormulario();
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red,
                        ),
                        tooltip: 'Eliminar',
                        onPressed: () async {
                          if (await _confirmarEliminacion(product)) {
                            try {
                              await _viewModel.eliminarProducto(product.id);
                              _mostrarSnack('Producto eliminado');
                            } catch (e) {
                              _mostrarSnack('Error al eliminar: $e');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── GESTIÓN DE PEDIDOS ──────────────────────────────────────

  String? _filtroEstadoPedido;

  Color _orderStatusColor(String estado) {
    switch (normalizeOrderStatus(estado)) {
      case 'pendiente':
        return Colors.orange;
      case 'confirmado':
        return Colors.blue;
      case 'enviado':
        return Theme.of(context).colorScheme.primary;
      case 'entregado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _orderStatusIcon(String estado) {
    switch (normalizeOrderStatus(estado)) {
      case 'pendiente':
        return Icons.hourglass_empty;
      case 'confirmado':
        return Icons.check_circle_outline;
      case 'enviado':
        return Icons.local_shipping_outlined;
      case 'entregado':
        return Icons.celebration_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildOrdersSection(BuildContext context) {
    return StreamBuilder<List<AdminOrderItem>>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('DEBUG ADMIN ORDERS: stream error=${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No se pudo cargar pedidos. Revisa el índice de Firestore si deseas optimizar.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var orders = snapshot.data!;
        if (_filtroEstadoPedido != null) {
          orders = orders
              .where((o) => o.order.estado == _filtroEstadoPedido)
              .toList();
        }

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 12),
                Text(
                  _filtroEstadoPedido != null
                      ? 'No hay pedidos en "$_filtroEstadoPedido"'
                      : 'No hay pedidos registrados',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        final stats = <String, int>{};
        for (final o in snapshot.data!) {
          stats[o.order.estado] = (stats[o.order.estado] ?? 0) + 1;
        }

        if (kIsWeb) {
          return Column(
            children: [
              _buildOrdersFilters(context, stats),
              Expanded(child: _buildOrdersDataTable(orders)),
            ],
          );
        }
        return Column(
          children: [
            _buildOrdersFilters(context, stats),
            Expanded(child: _buildOrdersMobileList(orders)),
          ],
        );
      },
    );
  }

  Widget _buildOrdersFilters(BuildContext context, Map<String, int> stats) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          _orderStatusChip(
            null,
            'Todos (${stats.values.fold(0, (a, b) => a + b)})',
            null,
            () {
              setState(() => _filtroEstadoPedido = null);
            },
          ),
          const SizedBox(width: 6),
          for (final estado in adminOrderStatuses) ...[
            _orderStatusChip(
              estado,
              '${orderStatusLabel(estado)} (${stats[estado] ?? 0})',
              _orderStatusColor(estado),
              () => setState(() => _filtroEstadoPedido = estado),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _orderStatusChip(
    String? estado,
    String label,
    Color? color,
    VoidCallback onTap,
  ) {
    final selected = _filtroEstadoPedido == estado;
    final chipColor = color ?? Colors.grey;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? chipColor : chipColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: chipColor,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersDataTable(List<AdminOrderItem> orders) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: DataTable(
        sortColumnIndex: null,
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('# Orden')),
          DataColumn(label: Text('Fecha')),
          DataColumn(label: Text('Cliente')),
          DataColumn(label: Text('Total')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: orders.map((item) {
          final o = item.order;
          final cliente = o.direccion['nombre'] ?? '—';
          final fecha =
              '${o.fechaCreacion.day}/${o.fechaCreacion.month}/${o.fechaCreacion.year}';
          return DataRow(
            cells: [
              DataCell(
                Text(
                  o.numeroOrden,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(Text(fecha, style: const TextStyle(fontSize: 13))),
              DataCell(Text(cliente, style: const TextStyle(fontSize: 13))),
              DataCell(Text('S/. ${o.total.toStringAsFixed(2)}')),
              DataCell(_orderStatusBadge(o.estado)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildOrderStatusDropdown(item),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 20),
                      tooltip: 'Ver detalle',
                      onPressed: () => _showOrderDetail(context, item),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrdersMobileList(List<AdminOrderItem> orders) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final item = orders[index];
        final o = item.order;
        final cliente = o.direccion['nombre'] ?? '—';
        final fecha =
            '${o.fechaCreacion.day}/${o.fechaCreacion.month}/${o.fechaCreacion.year}';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        o.numeroOrden,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _orderStatusBadge(o.estado),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$fecha — $cliente',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'S/. ${o.total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    _buildOrderStatusDropdown(item),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined, size: 20),
                      tooltip: 'Ver detalle',
                      onPressed: () => _showOrderDetail(context, item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _orderStatusBadge(String estado) {
    final normalizedStatus = normalizeOrderStatus(estado);
    final color = _orderStatusColor(normalizedStatus);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_orderStatusIcon(normalizedStatus), size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            orderStatusLabel(normalizedStatus),
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusDropdown(AdminOrderItem item) {
    final o = item.order;
    final normalizedStatus = normalizeOrderStatus(o.estado);
    final safeValue = adminOrderStatuses.contains(normalizedStatus)
        ? normalizedStatus
        : 'pendiente';
    debugPrint('DEBUG ADMIN ORDERS: dropdown statuses=$adminOrderStatuses');
    return SizedBox(
      width: 130,
      height: 32,
      child: DropdownButtonFormField<String>(
        initialValue: safeValue,
        isDense: true,
        items: adminOrderStatuses
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  orderStatusLabel(e),
                  style: TextStyle(fontSize: 12, color: _orderStatusColor(e)),
                ),
              ),
            )
            .toList(),
        onChanged: (nuevo) async {
          final normalizedNewStatus = normalizeOrderStatus(nuevo);
          if (nuevo != null && normalizedNewStatus != safeValue) {
            await _viewModel.actualizarEstadoPedido(
              item.uid,
              item.orderId,
              normalizedNewStatus,
            );
          }
        },
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          isDense: true,
        ),
      ),
    );
  }

  void _showOrderDetail(BuildContext context, AdminOrderItem item) {
    final o = item.order;
    final direccion = o.direccion;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Expanded(
              child: Text(o.numeroOrden, style: const TextStyle(fontSize: 18)),
            ),
            _orderStatusBadge(o.estado),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow(
                  'Fecha',
                  '${o.fechaCreacion.day}/${o.fechaCreacion.month}/${o.fechaCreacion.year}',
                ),
                _detailRow('Método de pago', o.metodoPago),
                _detailRow('Total', 'S/. ${o.total.toStringAsFixed(2)}'),
                _detailRow('Artículos', '${o.totalItems} producto(s)'),
                const Divider(height: 24),
                const Text(
                  'Dirección de envío',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                if (direccion['nombre'] != null)
                  _detailRow('Nombre', direccion['nombre']!),
                if (direccion['direccion'] != null)
                  _detailRow('Dirección', direccion['direccion']!),
                if (direccion['ciudad'] != null)
                  _detailRow('Ciudad', direccion['ciudad']!),
                if (direccion['telefono'] != null)
                  _detailRow('Teléfono', direccion['telefono']!),
                if (direccion['notas'] != null &&
                    direccion['notas']!.isNotEmpty)
                  _detailRow('Notas', direccion['notas']!),
                const Divider(height: 24),
                const Text(
                  'Productos',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...o.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['titulo']?.toString() ?? '',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          'x${item['cantidad']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'S/. ${(double.tryParse(item['costo']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    await SessionManager.logoutAndResetNavigation(reason: 'manual');
  }

  Widget _buildDashboard(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<List<ProductModel>>(
            stream: _viewModel.watchAllProducts(),
            builder: (context, snap) {
              final products = snap.data ?? [];
              final total = products.length;
              final lowStock = products
                  .where(
                    (p) =>
                        p.disponible && p.inventario > 0 && p.inventario <= 5,
                  )
                  .length;
              final agotados = products
                  .where((p) => !p.disponible || p.inventario == 0)
                  .length;
              return Row(
                children: [
                  Expanded(
                    child: _statCard(
                      theme,
                      Icons.inventory_2,
                      'Total Productos',
                      total.toString(),
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _statCard(
                      theme,
                      Icons.warning_amber,
                      'Stock Bajo',
                      lowStock.toString(),
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _statCard(
                      theme,
                      Icons.block_flipped,
                      'Agotados',
                      agotados.toString(),
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StreamBuilder<List<AdminOrderItem>>(
                      stream: _ordersStream,
                      builder: (context, snap2) {
                        final orders = snap2.data ?? [];
                        return _statCard(
                          theme,
                          Icons.receipt_long,
                          'Total Pedidos',
                          orders.length.toString(),
                          Colors.teal,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          StreamBuilder<List<AdminOrderItem>>(
            stream: _ordersStream,
            builder: (context, snap) {
              final orders = snap.data ?? [];
              if (orders.isEmpty) return const SizedBox();
              final conteo = <String, int>{};
              for (final o in orders) {
                conteo[o.order.estado] = (conteo[o.order.estado] ?? 0) + 1;
              }
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedidos por Estado',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: adminOrderStatuses.map((e) {
                          final color = _orderStatusColor(e);
                          final cantidad = conteo[e] ?? 0;
                          return SizedBox(
                            width: 180,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _orderStatusIcon(e),
                                    color: color,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cantidad.toString(),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                      Text(
                                        orderStatusLabel(e),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    ThemeData theme,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String categoria, {bool compact = false}) {
    // Normaliza la categoría: elimina espacios y convierte a minúsculas
    final String normalized = categoria.trim().toLowerCase();
    // Determina si este chip está seleccionado
    final bool isSelected = _filtroCategoria?.toLowerCase() == normalized;
    Color color;
    switch (normalized) {
      case 'laptop':
        color = Colors.blue;
        break;
      case 'smartphone':
        color = Colors.green;
        break;
      case 'tablet':
        color = Colors.teal;
        break;
      case 'monitor':
        color = Colors.purple;
        break;
      case 'periférico':
      case 'periferico':
        color = Colors.orange;
        break;
      case 'hardware':
      case 'componentes':
        color = Colors.indigo;
        break;
      case 'equipo':
        color = Colors.brown;
        break;
      case 'software':
        color = Colors.cyan;
        break;
      default:
        color = Colors.grey;
        break;
    }
    // Texto a mostrar (capitalizado)
    final String display = normalized.isNotEmpty
        ? normalized[0].toUpperCase() + normalized.substring(1)
        : '';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            if (isSelected) {
              _filtroCategoria = null; // desactivar filtro
            } else {
              _filtroCategoria = normalized; // activar filtro
            }
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 6 : 10,
            vertical: compact ? 2 : 4,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.25)
                : color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            display,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRating(double rating, {bool compact = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: compact ? 14 : 16, color: Colors.amber.shade600),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: Colors.amber.shade800,
          ),
        ),
      ],
    );
  }

  Widget _stockBadge(ProductModel product) {
    if (!product.disponible || product.inventario == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Agotado',
          style: TextStyle(
            fontSize: 11,
            color: Colors.red,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (product.inventario <= 5) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'Stock: ${product.inventario}',
          style: TextStyle(
            fontSize: 11,
            color: Colors.orange.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Stock: ${product.inventario}',
        style: TextStyle(
          fontSize: 11,
          color: Colors.green.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
