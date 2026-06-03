import 'package:flutter/material.dart';

import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/cart_view_model.dart';
import '../admin/digizone_admin_screen.dart';
import '../assistant/ai_assistant_screen.dart';
import '../cart/cart_screen.dart';
import '../location/ubicacion_screen.dart';
import '../store/digizone_tienda_screen.dart';

class DigizoneScreen extends StatefulWidget {
  final AuthViewModel authViewModel;

  const DigizoneScreen({super.key, required this.authViewModel});

  @override
  State<DigizoneScreen> createState() => _DigizoneScreenState();
}

class _DigizoneScreenState extends State<DigizoneScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final CartViewModel cartViewModel = CartViewModel();
  late final AnimationController _iconAnimationController;
  late final Animation<double> _iconScale;

  bool get _isAdmin => widget.authViewModel.isAdmin;

  /// Las pestañas se generan dinámicamente.
  /// Admin ve: Admin, Tienda, Carrito, Ubicación, Asistente
  /// Cliente ve: Tienda, Carrito, Ubicación, Asistente
  List<Widget> get _screens {
    return [
      if (_isAdmin) const DigizoneAdminScreen(),
      DigizoneTiendaScreen(
        cartViewModel: cartViewModel,
        onProductAdded: _onProductAdded,
        onViewCart: () {
          final cartIdx = _isAdmin ? 2 : 1;
          setState(() => _selectedIndex = cartIdx);
        },
      ),
      CartScreen(cartViewModel: cartViewModel),
      const UbicacionScreen(),
      AiAssistantScreen(
        cartViewModel: cartViewModel,
        onProductAdded: _onProductAdded,
      ),
    ];
  }

  List<BottomNavigationBarItem> get _navItems {
    return [
      if (_isAdmin)
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
        label: 'Ubicación',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.auto_awesome),
        label: 'Asistente',
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    // Empezar en Tienda (index 0 para cliente, 1 para admin)
    _selectedIndex = _isAdmin ? 1 : 0;
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
    widget.authViewModel.addListener(_onAuthUpdated);
  }

  @override
  void dispose() {
    widget.authViewModel.removeListener(_onAuthUpdated);
    cartViewModel.removeListener(_onCartUpdated);
    cartViewModel.dispose();
    _iconAnimationController.dispose();
    super.dispose();
  }

  void _onCartUpdated() => setState(() {});
  void _onAuthUpdated() {
    if (!mounted) return;
    // Si el usuario cierra sesión, el main.dart se encarga de redirigir
    setState(() {});
  }

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

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Cerrar Sesión'),
          ],
        ),
        content: Text(
          '¿Deseas cerrar sesión como ${widget.authViewModel.nombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.authViewModel.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _screens;
    final navItems = _navItems;

    // Asegurar que el index no exceda el número de pantallas
    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo.shade900,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.person, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.authViewModel.nombre.isNotEmpty
                    ? widget.authViewModel.nombre
                    : widget.authViewModel.email,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            if (_isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: navItems,
      ),
    );
  }
}
