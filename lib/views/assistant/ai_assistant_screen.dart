import 'package:flutter/material.dart';

import '../../core/widgets/technovate_widgets.dart';
import '../../models/assistant_chat_message.dart';
import '../../models/product_model.dart';
import '../../viewmodels/assistant_view_model.dart';
import '../../viewmodels/cart_view_model.dart';

class AiAssistantScreen extends StatefulWidget {
  final CartViewModel cartViewModel;
  final VoidCallback onProductAdded;

  const AiAssistantScreen({
    super.key,
    required this.cartViewModel,
    required this.onProductAdded,
  });

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  late final AssistantViewModel _viewModel;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _viewModel = AssistantViewModel(cartViewModel: widget.cartViewModel);
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (!mounted) return;
    setState(() {});
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _viewModel.isLoading) return;
    _messageController.clear();
    await _viewModel.sendMessage(message);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutQuad,
      );
    });
  }

  void _useSuggestion(String text) {
    _viewModel.sendMessage(text);
  }

  void _addProduct(ProductModel product) {
    final error = _viewModel.addRecommendationToCart(product);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    widget.onProductAdded();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.titulo} agregado al carrito 🛒'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  // Abre el formulario del recomendador por presupuesto
  void _mostrarFormularioRecomendador() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BudgetRecommenderForm(
        onSubmit: (presupuesto, uso, marca, formato, prioridad) {
          Navigator.pop(context);
          _viewModel.sendBudgetForm(
            presupuesto: presupuesto,
            uso: uso,
            marca: marca,
            formato: formato,
            prioridad: prioridad,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: tituloTechnovate(subtitulo: 'Asistente Experto'),
        backgroundColor: Colors.deepPurple.shade900,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.cyanAccent),
            tooltip: 'Configurar Presupuesto',
            onPressed: _mostrarFormularioRecomendador,
          ),
        ],
      ),
      body: Column(
        children: [
          _QuickActionChips(onSelected: _useSuggestion),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _viewModel.messages.length + (_viewModel.isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_viewModel.isLoading && index == _viewModel.messages.length) {
                  return const _TypingBubble();
                }
                final message = _viewModel.messages[index];
                return Column(
                  crossAxisAlignment: message.isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    _MessageBubble(message: message),
                    if (message.recommendedProducts.isNotEmpty)
                      _RecommendationList(
                        products: message.recommendedProducts,
                        onAddProduct: _addProduct,
                        onViewDetails: (p) => _mostrarDetallesProducto(p),
                      ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.psychology_alt, color: Colors.deepPurple, size: 28),
                    tooltip: 'Formulario Recomendador',
                    onPressed: _mostrarFormularioRecomendador,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ej: recomiéndame placa socket AM4 y RAM...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _viewModel.isLoading ? null : _sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade700,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.send),
                    tooltip: 'Enviar mensaje',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetallesProducto(ProductModel product) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product.titulo),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imagenProducto(product.imagen, height: 160, width: double.infinity),
                ),
                const SizedBox(height: 12),
                Text(
                  'S/. ${product.costo.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Marca: ${product.fabricante}'),
                Text('Garantía: ${product.garantia}'),
                Text('Inventario: ${product.inventario} unidades'),
                const Divider(height: 20),
                const Text(
                  'Especificaciones Técnicas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                if (product.ram.isNotEmpty) Text('• RAM: ${product.ram}'),
                if (product.procesador.isNotEmpty) Text('• Procesador: ${product.procesador}'),
                if (product.gpu.isNotEmpty) Text('• GPU: ${product.gpu}'),
                if (product.almacenamiento.isNotEmpty) Text('• Almacenamiento: ${product.almacenamiento}'),
                if (product.socket.isNotEmpty) Text('• Socket: ${product.socket}'),
                if (product.tipoRam.isNotEmpty) Text('• Tipo RAM: ${product.tipoRam}'),
                if (product.potenciaFuente > 0) Text('• Fuente requerida: ${product.potenciaFuente} W'),
                if (product.especificaciones.isEmpty &&
                    product.ram.isEmpty &&
                    product.socket.isEmpty)
                  const Text('No se detallaron especificaciones técnicas.'),
                const SizedBox(height: 10),
                const Text(
                  'Descripción:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(product.detalle),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            ElevatedButton(
              onPressed: product.tieneStock
                  ? () {
                      Navigator.pop(context);
                      _addProduct(product);
                    }
                  : null,
              child: const Text('Agregar al Carrito'),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActionChips extends StatelessWidget {
  const _QuickActionChips({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final chips = [
      {'label': 'Gaming 🎮', 'prompt': 'Armame una PC para gaming con buena GPU'},
      {'label': 'Oficina 📁', 'prompt': 'Busco una laptop economica para oficina y estudio'},
      {'label': 'Diseño 🎨', 'prompt': 'Recomiendame componentes para diseno grafico y renderizado'},
      {'label': 'Laptop 💻', 'prompt': 'Muestrame las laptops con mejor bateria y rendimiento'},
    ];

    return Container(
      height: 48,
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final item = chips[index];
          return ActionChip(
            backgroundColor: Colors.deepPurple.shade50,
            side: BorderSide(color: Colors.deepPurple.shade200, width: 0.5),
            labelStyle: TextStyle(color: Colors.deepPurple.shade900, fontWeight: FontWeight.w600),
            label: Text(item['label']!),
            onPressed: () => onSelected(item['prompt']!),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemCount: chips.length,
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AssistantChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    
    // Gradiente Cyberpunk para burbujas
    final decoration = isUser
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade600, Colors.deepPurple.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo.withOpacity(0.15),
                blurRadius: 6,
                offset: const Offset(1, 3),
              )
            ],
          )
        : BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          );

    final textStyle = TextStyle(
      color: isUser ? Colors.white : Colors.black87,
      fontSize: 15,
      height: 1.4,
    );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: decoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: textStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationList extends StatelessWidget {
  const _RecommendationList({
    required this.products,
    required this.onAddProduct,
    required this.onViewDetails,
  });

  final List<ProductModel> products;
  final ValueChanged<ProductModel> onAddProduct;
  final ValueChanged<ProductModel> onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 234,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          final noStock = !product.tieneStock;
          
          // Estilo de tarjeta con colores Cyberpunk en los bordes y sombras
          return Container(
            width: 240,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple.shade100, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.shade900.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imagenProducto(
                          product.imagen,
                          width: 58,
                          height: 58,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.titulo,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: Colors.cyan.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                product.categoria,
                                style: TextStyle(
                                  color: Colors.cyan.shade900,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      product.detalle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'S/. ${product.costo.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            product.puntuacion.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => onViewDetails(product),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            side: BorderSide(color: Colors.deepPurple.shade300),
                          ),
                          child: const Text('Ver', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: noStock ? null : () => onAddProduct(product),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            backgroundColor: Colors.deepPurple.shade700,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.add_shopping_cart, size: 14),
                          label: const Text('Agregar', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepPurple.shade100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.deepPurple.shade800,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Asistente analizando compatibilidad...',
              style: TextStyle(color: Colors.deepPurple.shade800, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// Formulario de presupuesto Cyberpunk
class _BudgetRecommenderForm extends StatefulWidget {
  const _BudgetRecommenderForm({required this.onSubmit});

  final Function(
    double presupuesto,
    String uso,
    String marca,
    String formato,
    String prioridad,
  ) onSubmit;

  @override
  State<_BudgetRecommenderForm> createState() => _BudgetRecommenderFormState();
}

class _BudgetRecommenderFormState extends State<_BudgetRecommenderForm> {
  final TextEditingController _budgetController = TextEditingController(text: '3000');
  String _selectedUse = 'Gaming';
  String _selectedBrand = 'Cualquiera';
  String _selectedForm = 'Computadora de Escritorio (Desktop)';
  String _selectedPriority = 'Rendimiento';

  final List<String> _uses = ['Gaming', 'Oficina/Estudio', 'Diseño Gráfico', 'Programación'];
  final List<String> _brands = ['Cualquiera', 'ASUS', 'Intel', 'AMD', 'NVIDIA', 'MSI', 'Gigabyte'];
  final List<String> _formats = [
    'Computadora de Escritorio (Desktop)',
    'Computadora Portátil (Laptop)'
  ];
  final List<String> _priorities = ['Rendimiento', 'Precio / Calidad', 'Garantía / Marca'];

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Configurar Presupuesto y Preferencias ⚙️',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Presupuesto máximo (S/.)',
                icon: Icon(Icons.attach_money, color: Colors.deepPurple),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedUse,
              items: _uses.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (val) => setState(() => _selectedUse = val!),
              decoration: const InputDecoration(
                labelText: 'Uso principal',
                icon: Icon(Icons.sports_esports, color: Colors.deepPurple),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedBrand,
              items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
              onChanged: (val) => setState(() => _selectedBrand = val!),
              decoration: const InputDecoration(
                labelText: 'Marca favorita',
                icon: Icon(Icons.bolt, color: Colors.deepPurple),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedForm,
              items: _formats.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
              onChanged: (val) => setState(() => _selectedForm = val!),
              decoration: const InputDecoration(
                labelText: 'Formato',
                icon: Icon(Icons.computer, color: Colors.deepPurple),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (val) => setState(() => _selectedPriority = val!),
              decoration: const InputDecoration(
                labelText: 'Prioridad',
                icon: Icon(Icons.star, color: Colors.deepPurple),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final budget = double.tryParse(_budgetController.text) ?? 3000;
                widget.onSubmit(
                  budget,
                  _selectedUse,
                  _selectedBrand,
                  _selectedForm,
                  _selectedPriority,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade900,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Generar Recomendación Compatible', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
