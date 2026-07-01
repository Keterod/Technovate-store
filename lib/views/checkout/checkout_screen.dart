import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/technovate_widgets.dart';
import '../../services/analytics_service.dart';
import '../../services/location_service.dart';
import '../../services/profile_service.dart';
import '../../viewmodels/cart_view_model.dart';
import '../../viewmodels/order_view_model.dart';
import '../location/mapa_picker_screen.dart';
import '../profile/profile_screen.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final CartViewModel cartViewModel;
  final OrderViewModel orderViewModel;

  const CheckoutScreen({
    super.key,
    required this.cartViewModel,
    required this.orderViewModel,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutFormData {
  const _CheckoutFormData({
    required this.nombre,
    required this.direccion,
    required this.ciudad,
    required this.telefono,
    required this.notas,
  });

  final String nombre;
  final String direccion;
  final String ciudad;
  final String telefono;
  final String notas;
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _notasController = TextEditingController();

  final LocationService _locationService = LocationService();
  String _metodoPago = 'Efectivo';
  bool _procesando = false;
  bool _obteniendoUbicacion = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    try {
      final profile = await _profileService.getProfile();
      final user = FirebaseAuth.instance.currentUser;
      if (!mounted) return;
      _nombreController.text = profile.nombre.isNotEmpty
          ? profile.nombre
          : user?.displayName ?? user?.email ?? '';
      _direccionController.text = profile.direccion;
      _ciudadController.text = profile.ciudad;
      _telefonoController.text = profile.telefono;
    } catch (_) {
      // Silently fall back to empty fields
    }
  }

  Future<void> _usarUbicacionActual() async {
    setState(() => _obteniendoUbicacion = true);
    try {
      final pos = await _locationService.obtenerUbicacionUsuario();
      final result = await _locationService.reverseGeocode(pos);
      _direccionController.text = result['direccion'] ?? '';
      _ciudadController.text = result['ciudad'] ?? '';
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _obteniendoUbicacion = false);
    }
  }

  Future<void> _seleccionarEnMapa() async {
    final result = await Navigator.push<MapaPickerResult>(
      context,
      MaterialPageRoute(builder: (_) => const MapaPickerScreen()),
    );
    if (result != null) {
      _direccionController.text = result.direccion;
      _ciudadController.text = result.ciudad;
    }
  }

  final List<String> _metodosPago = [
    'Efectivo',
    'Tarjeta débito/crédito',
    'Transferencia bancaria',
    'Yape',
    'Plin',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _telefonoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _confirmarPedido() async {
    if (_procesando) return;

    final stopwatch = Stopwatch()..start();
    debugPrint('DEBUG CHECKOUT: confirm pressed');
    try {
      await _confirmarPedidoInterno(
        stopwatch,
      ).timeout(const Duration(seconds: 15));
    } on TimeoutException catch (e, stackTrace) {
      debugPrint('DEBUG CHECKOUT: timeout error=$e');
      debugPrint('DEBUG CHECKOUT: stack=$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El pedido tardó demasiado. Intenta nuevamente.'),
        ),
      );
    } on FirebaseException catch (e, stackTrace) {
      debugPrint(
        'DEBUG CHECKOUT: firebase error code=${e.code} message=${e.message}',
      );
      debugPrint('DEBUG CHECKOUT: stack=$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo confirmar el pedido. Intenta nuevamente.'),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('DEBUG CHECKOUT: error=$e');
      debugPrint('DEBUG CHECKOUT: stack=$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo confirmar el pedido. Intenta nuevamente.'),
        ),
      );
    } finally {
      debugPrint('DEBUG CHECKOUT: total ms=${stopwatch.elapsedMilliseconds}');
      stopwatch.stop();
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _confirmarPedidoInterno(Stopwatch stopwatch) async {
    debugPrint('DEBUG CHECKOUT: validate form start');
    final validationError = _validarCamposRapido();
    debugPrint(
      'DEBUG CHECKOUT: validate form result=${validationError == null}',
    );
    if (validationError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    if (mounted) setState(() => _procesando = true);

    debugPrint('DEBUG CHECKOUT: read fields start');
    final formData = _leerCamposFormulario();
    debugPrint('DEBUG CHECKOUT: read fields done');

    debugPrint('DEBUG CHECKOUT: validate cart start');
    final cartItems = widget.cartViewModel.items;
    if (cartItems.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('El carrito está vacío.')));
      return;
    }
    debugPrint('DEBUG CHECKOUT: validate cart done items=${cartItems.length}');

    debugPrint('DEBUG CHECKOUT: build order data start');
    final direccion = {
      'nombre': formData.nombre,
      'direccion': formData.direccion,
      'ciudad': formData.ciudad,
      'telefono': formData.telefono,
      'notas': formData.notas,
    };
    final total = widget.cartViewModel.totalPrecio;
    debugPrint('DEBUG CHECKOUT: build order data done');

    AnalyticsService().logBeginCheckout(value: total);

    debugPrint('DEBUG CHECKOUT: before order service');
    debugPrint('DEBUG CHECKOUT: start create order');
    final order = await widget.orderViewModel.crearPedido(
      cartItems: cartItems,
      direccion: direccion,
      metodoPago: _metodoPago,
      total: total,
    );
    debugPrint('DEBUG CHECKOUT: order create done');

    AnalyticsService().logPurchase(value: total);
    widget.cartViewModel.limpiar();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: order)),
    );
  }

  String? _validarCamposRapido() {
    if (_nombreController.text.trim().isEmpty) return 'Ingresa tu nombre';
    if (_direccionController.text.trim().isEmpty) return 'Ingresa tu dirección';
    if (_ciudadController.text.trim().isEmpty) return 'Ingresa tu ciudad';
    if (_telefonoController.text.trim().isEmpty) return 'Ingresa tu teléfono';
    return null;
  }

  _CheckoutFormData _leerCamposFormulario() {
    return _CheckoutFormData(
      nombre: _nombreController.text.trim(),
      direccion: _direccionController.text.trim(),
      ciudad: _ciudadController.text.trim(),
      telefono: _telefonoController.text.trim(),
      notas: _notasController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.cartViewModel.items;
    final total = widget.cartViewModel.totalPrecio;

    return Scaffold(
      appBar: AppBar(title: tituloTechnovate(subtitulo: 'Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen del pedido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: Hero(
                                  tag: 'cart_img_${item.idProducto}',
                                  child: imagenProducto(
                                    item.imagen,
                                    height: 40,
                                    width: 40,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${item.titulo} x${item.cantidad}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                'S/. ${item.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'S/. ${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Dirección de envío',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProfileScreen(),
                        ),
                      );
                      _cargarPerfil();
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text(
                      'Editar perfil',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _obteniendoUbicacion
                        ? null
                        : _usarUbicacionActual,
                    icon: _obteniendoUbicacion
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: const Text('Usar mi ubicación'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _obteniendoUbicacion ? null : _seleccionarEnMapa,
                    icon: const Icon(Icons.map, size: 18),
                    label: const Text('Seleccionar en mapa'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingresa tu nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _direccionController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Ingresa tu dirección'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ciudadController,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Ingresa tu ciudad'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Ingresa tu teléfono'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notasController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Método de pago',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._metodosPago.map(
                (metodo) => RadioListTile<String>(
                  title: Text(metodo),
                  value: metodo,
                  groupValue: _metodoPago,
                  onChanged: (v) => setState(() => _metodoPago = v!),
                  activeColor: Theme.of(context).colorScheme.primary,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _procesando ? null : _confirmarPedido,
                  icon: _procesando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _procesando
                        ? 'Procesando...'
                        : 'Confirmar pedido - S/. ${total.toStringAsFixed(2)}',
                  ),
                  style: ElevatedButton.styleFrom(
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
