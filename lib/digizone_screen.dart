import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'carrito_screen.dart';
import 'carrito_state.dart';
import 'digizone_admin_screen.dart';
import 'digizone_tienda_screen.dart';
import 'digizone_utils.dart';
import 'historial_pedidos_screen.dart';
import 'ubicacion_screen.dart';

class DigizoneScreen extends StatefulWidget {
  const DigizoneScreen({super.key});

  @override
  State<DigizoneScreen> createState() => _DigizoneScreenState();
}

class _DigizoneScreenState extends State<DigizoneScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  final CarritoState carritoState = CarritoState();
  late final AnimationController _iconAnimationController;
  late final Animation<double> _iconScale;

  bool get _esAdmin {
    final user = FirebaseAuth.instance.currentUser;
    return user?.email?.toLowerCase() == 'admin@gmail.com';
  }

  int get _indiceCarrito => _esAdmin ? 2 : 1;

  int get _indiceHistorial => _esAdmin ? 4 : 3;

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

  Future<void> _cerrarSesion() async {
    _scaffoldKey.currentState?.closeDrawer();
    await FirebaseAuth.instance.signOut();
  }

  void _irAHistorial() {
    _scaffoldKey.currentState?.closeDrawer();
    setState(() => _selectedIndex = _indiceHistorial);
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

  Widget _barraSuperior() {
    return Material(
      color: Colors.indigo,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                tooltip: 'Menú',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const Expanded(
                child: Text(
                  technovateNombre,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Cerrar sesión',
                onPressed: _cerrarSesion,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Usuario';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.indigo),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.indigo, size: 36),
            ),
            accountName: Text(
              technovateNombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(email),
          ),
          if (_esAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings, color: Colors.indigo),
              title: const Text('Administración'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 0);
              },
            ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.indigo),
            title: const Text('Historial de pedidos'),
            onTap: _irAHistorial,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Cerrar sesión',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: _cerrarSesion,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStackChildren() {
    final tienda = DigizoneTiendaScreen(
      carritoState: carritoState,
      onProductoAgregado: _onProductoAgregado,
      onVerCarrito: () => setState(() => _selectedIndex = _indiceCarrito),
    );

    if (_esAdmin) {
      return [
        const DigizoneAdminScreen(),
        tienda,
        CarritoScreen(carritoState: carritoState),
        const UbicacionScreen(),
        const HistorialPedidosScreen(),
      ];
    }

    return [
      tienda,
      CarritoScreen(carritoState: carritoState),
      const UbicacionScreen(),
      const HistorialPedidosScreen(),
    ];
  }

  List<BottomNavigationBarItem> _buildNavItems() {
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
        BottomNavigationBarItem(
          icon: _iconoCarrito(),
          label: 'Carrito',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.location_on),
          label: 'Ubicación',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Historial',
        ),
      ];
    }

    return [
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
      const BottomNavigationBarItem(
        icon: Icon(Icons.history),
        label: 'Historial',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final children = _buildStackChildren();
    final maxIndex = children.length - 1;
    final selectedIndex = _selectedIndex.clamp(0, maxIndex);
    if (selectedIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedIndex = selectedIndex);
      });
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _barraSuperior(),
          Expanded(
            child: IndexedStack(
              index: selectedIndex,
              children: children,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: _buildNavItems(),
      ),
    );
  }
}
