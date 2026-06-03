import 'package:flutter/material.dart';

import '../../viewmodels/cart_view_model.dart';
import '../admin/digizone_admin_screen.dart';
import '../assistant/ai_assistant_screen.dart';
import '../cart/cart_screen.dart';
import '../location/ubicacion_screen.dart';
import '../store/digizone_tienda_screen.dart';

class DigizoneScreen extends StatefulWidget {
  const DigizoneScreen({super.key});

  @override
  State<DigizoneScreen> createState() => _DigizoneScreenState();
}

class _DigizoneScreenState extends State<DigizoneScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final CartViewModel cartViewModel = CartViewModel();
  late final AnimationController _iconAnimationController;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _iconScale = Tween<double>(begin: 1, end: 1.35).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    cartViewModel.addListener(_onCartUpdated);
  }

  @override
  void dispose() {
    cartViewModel.removeListener(_onCartUpdated);
    cartViewModel.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  void _onCartUpdated() => setState(() {});

  void _animateCartIcon() {
    _iconAnimationController.forward(from: 0).then((_) {
      if (mounted) _iconAnimationController.reverse();
    });
  }

  void _onProductAdded() {
    _animateCartIcon();
    setState(() {});
  }

  Widget _cartIcon() {
    return ScaleTransition(
      scale: _iconScale,
      child: Badge(
        isLabelVisible: cartViewModel.totalItems > 0,
        label: Text('${cartViewModel.totalItems}'),
        child: const Icon(Icons.shopping_cart),
      ),
    );
  }

  void _onTabTapped(int index) {
    if (index == 0) {
      showDialog<String>(
        context: context,
        builder: (context) {
          final pinController = TextEditingController();
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.lock, color: Colors.indigo),
                SizedBox(width: 8),
                Text('Acceso Restringido'),
              ],
            ),
            content: TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Ingrese PIN de Administrador',
                hintText: 'PIN por defecto: 1337',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final pin = pinController.text.trim();
                  Navigator.pop(context, pin);
                },
                child: const Text('Ingresar'),
              ),
            ],
          );
        },
      ).then((result) {
        if (!mounted) return;
        if (result == '1337') {
          setState(() => _selectedIndex = 0);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Acceso concedido como Administrador 🔓'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('PIN incorrecto. Acceso denegado 🔐'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const DigizoneAdminScreen(),
          DigizoneTiendaScreen(
            cartViewModel: cartViewModel,
            onProductAdded: _onProductAdded,
            onViewCart: () => setState(() => _selectedIndex = 2),
          ),
          CartScreen(cartViewModel: cartViewModel),
          const UbicacionScreen(),
          AiAssistantScreen(
            cartViewModel: cartViewModel,
            onProductAdded: _onProductAdded,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Tienda',
          ),
          BottomNavigationBarItem(icon: _cartIcon(), label: 'Carrito'),
          const BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Ubicacion',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Asistente',
          ),
        ],
      ),
    );
  }
}
