import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'carrito_screen.dart';
import 'carrito_state.dart';
import 'digizone_admin_screen.dart';
import 'digizone_tienda_screen.dart';
import 'digizone_utils.dart';
import 'historial_pedidos_screen.dart';
import 'ubicacion_screen.dart';
import 'voice_assistant_service.dart';
import 'core/widgets/confirm_dialog.dart';

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
  final AsistenteVoz _asistenteVoz = AsistenteVoz();
  final ValueNotifier<SearchFilters> _filtrosBusqueda =
      ValueNotifier(const SearchFilters());

  bool get _esAdmin => FirebaseAuth.instance.currentUser?.email?.toLowerCase() == 'admin@gmail.com';

  int get _indiceTienda => _esAdmin ? 1 : 0;
  int get _indiceCarrito => _esAdmin ? 2 : 1;
  int get _indiceUbicacion => _esAdmin ? 3 : 2;
  int get _indiceHistorial => _esAdmin ? 4 : 3;

  final List<String> _titulos = const ['Tienda', 'Carrito', 'Ubicación', 'Historial'];

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _iconScale = Tween<double>(begin: 1.0, end: 1.35).animate(
      CurvedAnimation(parent: _iconAnimationController, curve: Curves.elasticOut),
    );
    carritoState.addListener(_onCarritoActualizado);
  }

  @override
  void dispose() {
    carritoState.removeListener(_onCarritoActualizado);
    _iconAnimationController.dispose();
    _filtrosBusqueda.dispose();
    _asistenteVoz.dispose();
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
    final confirmado = await mostrarConfirmacion(
      context,
      titulo: 'Cerrar sesión',
      mensaje: '¿Estás seguro de que deseas cerrar sesión?',
      confirmar: 'Cerrar sesión',
      icono: Icons.logout,
      colorConfirmar: Colors.red,
    );
    if (!confirmado || !mounted) return;
    _scaffoldKey.currentState?.closeDrawer();
    await FirebaseAuth.instance.signOut();
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
            accountName: Text(technovateNombre, style: const TextStyle(fontWeight: FontWeight.bold)),
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
            leading: const Icon(Icons.favorite, color: Colors.red),
            title: const Text('Favoritos'),
            onTap: () {
              Navigator.pop(context);
              context.push('/favorites');
            },
          ),
          ListTile(
            leading: const Icon(Icons.history, color: Colors.indigo),
            title: const Text('Historial de pedidos'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = _indiceHistorial);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
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
      filtrosBusqueda: _filtrosBusqueda,
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
        const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Tienda'),
        BottomNavigationBarItem(icon: _iconoCarrito(), label: 'Carrito'),
        const BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Ubicación'),
        const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
      ];
    }
    return [
      const BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Tienda'),
      BottomNavigationBarItem(icon: _iconoCarrito(), label: 'Carrito'),
      const BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Ubicación'),
      const BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
    ];
  }

  String _tituloActual() {
    if (_esAdmin && _selectedIndex == 0) return 'Admin';
    final idx = _esAdmin ? _selectedIndex - 1 : _selectedIndex;
    return idx >= 0 && idx < _titulos.length ? _titulos[idx] : '';
  }

  Future<void> _mostrarEscucha() async {
    final disponible = await _asistenteVoz.inicializar();
    if (!disponible || !mounted) {
      if (mounted) _mostrarErrorVoz(_asistenteVoz.ultimoError);
      return;
    }
    final texto = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DialogoEscucha(asistente: _asistenteVoz),
    );
    if (texto == null || texto.trim().isEmpty || !mounted) return;
    _ejecutarComando(AsistenteVoz.parsear(texto));
  }

  Future<void> _ejecutarComando(ComandoParseado comando) async {
    switch (comando.tipo) {
      case ComandoVoz.buscar:
        _filtrosBusqueda.value = SearchFilters(
          query: comando.termino ?? '',
          precioMin: comando.precioMin,
          precioMax: comando.precioMax,
        );
        setState(() => _selectedIndex = _indiceTienda);
      case ComandoVoz.agregarCarrito:
        if (comando.termino != null) await _agregarProductoPorVoz(comando.termino!);
      case ComandoVoz.irCarrito:
        setState(() => _selectedIndex = _indiceCarrito);
      case ComandoVoz.limpiarCarrito:
        carritoState.limpiar();
      case ComandoVoz.eliminarCarrito:
        if (comando.termino != null) _eliminarProductoPorVoz(comando.termino!);
      case ComandoVoz.irUbicacion:
        setState(() => _selectedIndex = _indiceUbicacion);
      case ComandoVoz.irHistorial:
        setState(() => _selectedIndex = _indiceHistorial);
      case ComandoVoz.ayuda:
        _mostrarAyuda();
      case ComandoVoz.desconocido:
        if (mounted) _mostrarSnack('No entendí el comando. Di "ayuda" para ver los comandos');
    }
  }

  void _mostrarSnack(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _agregarProductoPorVoz(String termino) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection(digizoneColeccion).get();
      final lower = termino.toLowerCase();
      final matches = snapshot.docs.where((doc) {
        final d = doc.data();
        return (d['titulo'] ?? '').toString().toLowerCase().contains(lower) && d['disponible'] != false;
      }).toList();
      if (matches.isEmpty) {
        _mostrarSnack('No encontré "$termino" en los productos');
        return;
      }
      final data = matches.first.data();
      final error = carritoState.agregar(
        idProducto: matches.first.id,
        titulo: (data['titulo'] ?? '').toString(),
        detalle: (data['detalle'] ?? '').toString(),
        costo: ((data['costo'] ?? 0) as num).toDouble(),
        imagen: (data['imagen'] ?? '').toString(),
        inventario: ((data['inventario'] ?? 0) as num).toInt(),
        disponible: data['disponible'] != false,
      );
      _mostrarSnack(error ?? '✅ ${data['titulo']} agregado al carrito');
      if (error == null) _onProductoAgregado();
    } catch (e) {
      _mostrarSnack('Error: $e');
    }
  }

  void _eliminarProductoPorVoz(String termino) {
    final lower = termino.toLowerCase();
    final idx = carritoState.items.indexWhere((i) => i.titulo.toLowerCase().contains(lower));
    if (idx == -1) {
      _mostrarSnack('No encontré "$termino" en tu carrito');
      return;
    }
    carritoState.eliminarEn(idx);
    _mostrarSnack('Producto eliminado del carrito');
  }

  void _mostrarErrorVoz(String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.mic_off, color: Colors.red), SizedBox(width: 8), Text('Voz no disponible')]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mensaje),
            const SizedBox(height: 16),
            const Text('En dispositivos Xiaomi/Redmi, instala "Google Speech Recognition" desde Play Store.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
      ),
    );
  }

  void _mostrarAyuda() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.mic, color: Colors.indigo), SizedBox(width: 8), Text('Comandos de voz')]),
        content: const SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            _AyudaItem('"Busca laptops"', 'Filtrar productos'),
            _AyudaItem('"Laptops entre 1000 y 2000"', 'Filtrar por nombre y precio'),
            _AyudaItem('"Menos de 500 soles"', 'Productos bajo cierto precio'),
            _AyudaItem('"Agrega laptop al carrito"', 'Agregar producto'),
            _AyudaItem('"Quita laptop del carrito"', 'Eliminar producto'),
            _AyudaItem('"Limpia el carrito"', 'Vaciar carrito'),
            _AyudaItem('"Ir al carrito"', 'Navegar al carrito'),
            _AyudaItem('"Ir a ubicación"', 'Ver mapa'),
            _AyudaItem('"Ver historial"', 'Ver pedidos'),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = _buildStackChildren();
    final maxIndex = children.length - 1;
    final selectedIndex = _selectedIndex.clamp(0, maxIndex);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: tituloTechnovate(subtitulo: _tituloActual()),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            tooltip: 'Asistente de voz',
            onPressed: _mostrarEscucha,
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(index: selectedIndex, children: children),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: _buildNavItems(),
      ),
    );
  }
}

class _AyudaItem extends StatelessWidget {
  final String comando;
  final String descripcion;
  const _AyudaItem(this.comando, this.descripcion);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.mic, size: 18, color: Colors.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comando, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(descripcion, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogoEscucha extends StatefulWidget {
  final AsistenteVoz asistente;
  const _DialogoEscucha({required this.asistente});

  @override
  State<_DialogoEscucha> createState() => _DialogoEscuchaState();
}

class _DialogoEscuchaState extends State<_DialogoEscucha> with SingleTickerProviderStateMixin {
  String _texto = '';
  bool _escuchando = false;
  late final AnimationController _pulsoController;
  late final Animation<double> _pulsoAnim;

  @override
  void initState() {
    super.initState();
    _pulsoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulsoAnim = Tween<double>(begin: 0.85, end: 1.15).animate(CurvedAnimation(parent: _pulsoController, curve: Curves.easeInOut));
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciarEscucha());
  }

  void _iniciarEscucha() {
    widget.asistente.escuchar(
      alResultado: (texto, esFinal) {
        if (mounted) {
          setState(() => _texto = texto);
          if (esFinal && texto.trim().isNotEmpty) Navigator.pop(context, texto);
        }
      },
      alIniciar: () { if (mounted) setState(() => _escuchando = true); },
      alError: (_) { if (mounted) Navigator.pop(context); },
    );
  }

  @override
  void dispose() {
    _pulsoController.dispose();
    widget.asistente.detener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _pulsoAnim,
            child: Icon(Icons.mic, size: 64, color: _escuchando ? Colors.indigo : Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(_escuchando ? 'Escuchando...' : 'Inicializando...', style: const TextStyle(fontSize: 16)),
          if (_texto.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(_texto, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.indigo), textAlign: TextAlign.center),
          ],
          const SizedBox(height: 16),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ],
      ),
    );
  }
}
