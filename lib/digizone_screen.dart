import 'package:flutter/material.dart';
import 'carrito_screen.dart';
import 'carrito_state.dart';
import 'digizone_admin_screen.dart';
import 'digizone_tienda_screen.dart';
import 'ubicacion_screen.dart';

class DigizoneScreen extends StatefulWidget {
  const DigizoneScreen({super.key});

  @override
  State<DigizoneScreen> createState() => _DigizoneScreenState();
}

class _DigizoneScreenState extends State<DigizoneScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final CarritoState carritoState = CarritoState();
  late final AnimationController _iconAnimationController;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _iconScale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(
        parent: _iconAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    carritoState.addListener(_onCarritoActualizado);
  }

  @override
  void dispose() {
    carritoState.removeListener(_onCarritoActualizado);
    _iconAnimationController.dispose();
    super.dispose();
  }

  void _onCarritoActualizado() => setState(() {});

  void _animarIconoCarrito() {
    _iconAnimationController.forward(from: 0).then((_) {
      if (mounted) _iconAnimationController.reverse();
    });
  }

  void _onProductoAgregado() {
    _animarIconoCarrito();
    setState(() {});
  }

  Widget _iconoCarrito() {
    return ScaleTransition(
      scale: _iconScale,
      child: Badge(
        isLabelVisible: carritoState.totalItems > 0,
        label: Text('${carritoState.totalItems}'),
        child: const Icon(Icons.shopping_cart),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const DigizoneAdminScreen(),
          DigizoneTiendaScreen(
            carritoState: carritoState,
            onProductoAgregado: _onProductoAgregado,
            onVerCarrito: () => setState(() => _selectedIndex = 2),
          ),
          CarritoScreen(carritoState: carritoState),
          const UbicacionScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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
          BottomNavigationBarItem(
            icon: _iconoCarrito(),
            label: 'Carrito',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Ubicación',
          ),
        ],
      ),
    );
  }
}
