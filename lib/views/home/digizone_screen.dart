import 'package:flutter/material.dart';

import '../../viewmodels/cart_view_model.dart';
import '../assistant/ai_assistant_screen.dart';
import '../cart/cart_screen.dart';
import '../location/ubicacion_screen.dart';
import '../store/digizone_tienda_screen.dart';
import '../location/ubicacion_screen.dart';
import 'home_landing_screen.dart';

class DigizoneScreen extends StatefulWidget {
  final String? userEmail;

  const DigizoneScreen({super.key, this.userEmail});

  @override
  State<DigizoneScreen> createState() => _DigizoneScreenState();
}

class _DigizoneScreenState extends State<DigizoneScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String? _categoriaStore;
  final CartViewModel cartViewModel = CartViewModel();
  late final AnimationController _iconAnimationController;
  late final Animation<double> _iconScale;



  List<Widget> get _screens {
    if (_esAdmin) {
      return [
        const DigizoneAdminScreen(),
        DigizoneTiendaScreen(
          cartViewModel: cartViewModel,
          onProductAdded: _onProductAdded,
          onViewCart: () => setState(() => _selectedIndex = _indiceCarrito),
        ),
        CartScreen(cartViewModel: cartViewModel),
        AiAssistantScreen(
          cartViewModel: cartViewModel,
          onProductAdded: _onProductAdded,
        ),
        const UbicacionScreen(),
      ];
    }
        // Admin UI block removed; admin now has separate login and guard.

    return [
      HomeLandingScreen(
        onNavigateTienda: (categoria) {
          _categoriaStore = categoria;
          setState(() => _selectedIndex = 1);
        },
        onNavigateAsistente: () => setState(() => _selectedIndex = 3),
        onNavigateCarrito: () => setState(() => _selectedIndex = 2),
        onNavigateUbicacion: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UbicacionScreen()),
          );
        },
        cartViewModel: cartViewModel,
      ),
      DigizoneTiendaScreen(
        cartViewModel: cartViewModel,
        onProductAdded: _onProductAdded,
        onViewCart: () => setState(() => _selectedIndex = _indiceCarrito),
        categoriaInicial: _categoriaStore,
      ),
      CartScreen(cartViewModel: cartViewModel),
      AiAssistantScreen(
        cartViewModel: cartViewModel,
        onProductAdded: _onProductAdded,
      ),
      const UbicacionScreen(),
    ];
  }

  List<BottomNavigationBarItem> get _navItems {
    if (_esAdmin) {
      return [
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
          icon: Icon(Icons.auto_awesome),
          label: 'Asistente',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.location_on),
          label: 'Ubicación',
        ),
      ];
    }
    // Admin navigation items removed; admin uses separate routes.

    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Inicio',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.store),
        label: 'Tienda',
      ),
      BottomNavigationBarItem(icon: _cartIcon(), label: 'Carrito'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.auto_awesome),
        label: 'Asistente',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.location_on),
        label: 'Ubicación',
      ),
    ];
  }

  int get _indiceCarrito => 2;

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
  void didUpdateWidget(DigizoneScreen old) {
    super.didUpdateWidget(old);
    if (old.userEmail != widget.userEmail) setState(() {});
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
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex.clamp(0, _screens.length - 1),
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex.clamp(0, _navItems.length - 1),
        onTap: _onTabTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        items: _navItems,
      ),
    );
  }
}
