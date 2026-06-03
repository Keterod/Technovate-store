import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/technovate_widgets.dart';
import '../../services/analytics_service.dart';
import '../../services/profile_service.dart';
import '../../viewmodels/cart_view_model.dart';
import '../../viewmodels/order_view_model.dart';
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

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();
  final _nombreController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciudadController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _notasController = TextEditingController();

  String _metodoPago = 'Efectivo';
  bool _procesando = false;

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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _procesando = true);

    AnalyticsService().logBeginCheckout(
      value: widget.cartViewModel.totalPrecio,
    );

    try {
      final order = await widget.orderViewModel.crearPedido(
        cartItems: widget.cartViewModel.items,
        direccion: {
          'nombre': _nombreController.text.trim(),
          'direccion': _direccionController.text.trim(),
          'ciudad': _ciudadController.text.trim(),
          'telefono': _telefonoController.text.trim(),
          'notas': _notasController.text.trim(),
        },
        metodoPago: _metodoPago,
        total: widget.cartViewModel.totalPrecio,
      );

      AnalyticsService().logPurchase(
        value: widget.cartViewModel.totalPrecio,
      );
      widget.cartViewModel.limpiar();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(order: order),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar pedido: $e')),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.cartViewModel.items;
    final total = widget.cartViewModel.totalPrecio;

    return Scaffold(
      appBar: AppBar(
        title: tituloTechnovate(subtitulo: 'Checkout'),
      ),
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
                      ...items.map((item) => Padding(
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
                          )),
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
                    label: const Text('Editar perfil', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingresa tu dirección' : null,
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
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Ingresa tu teléfono' : null,
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
                    _procesando ? 'Procesando...' : 'Confirmar pedido - S/. ${total.toStringAsFixed(2)}',
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
