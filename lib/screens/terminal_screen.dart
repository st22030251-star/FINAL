import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/product_model.dart';
import '../services/biometric_service.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final _firestore = FirestoreService();
  final List<Product> _cart = [];
  final _bio = BiometricService();

  void _addToCart(Product product) {
    setState(() => _cart.add(product));
  }

  double get _total => _cart.fold(0, (sum, item) => sum + item.price);

  void _checkout() async {
    if (_cart.isEmpty) return;
    
    // Simular guardado de venta
    await _firestore.saveSale({
      'items': _cart.map((e) => e.toMap()).toList(),
      'total': _total,
    });
    
    setState(() => _cart.clear());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Venta Realizada con Éxito")));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: _firestore.getProducts(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final products = snapshot.data!;
              return ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text("\$${p.price} - Stock: ${p.stock}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () => _addToCart(p),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.grey[200]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total: \$${_total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ElevatedButton(
                onPressed: _checkout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                child: const Text("PAGAR"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
