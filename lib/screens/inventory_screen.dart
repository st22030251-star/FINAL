import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/product_model.dart';
import '../services/biometric_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _firestore = FirestoreService();
  final _bio = BiometricService();
  bool _isAdminMode = false;

  void _enableAdmin() async {
    final authenticated = await _bio.authenticate();
    if (authenticated) {
      setState(() => _isAdminMode = true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Modo Administrador Activado")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fallo en la autenticación")));
    }
  }

  void _disableAdmin() {
    setState(() => _isAdminMode = false);
  }

  void _showAddDialog() async {
    final name = TextEditingController();
    final price = TextEditingController();
    final sku = TextEditingController();
    final category = TextEditingController();
    final stock = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nuevo Producto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "Nombre")),
            TextField(controller: price, decoration: const InputDecoration(labelText: "Precio"), keyboardType: TextInputType.number),
            TextField(controller: sku, decoration: const InputDecoration(labelText: "SKU")),
            TextField(controller: category, decoration: const InputDecoration(labelText: "Categoría")),
            TextField(controller: stock, decoration: const InputDecoration(labelText: "Stock"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              final p = Product(
                id: '',
                name: name.text,
                price: double.parse(price.text),
                sku: sku.text,
                category: category.text,
                stock: int.parse(stock.text),
              );
              _firestore.addProduct(p);
              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventario de Stock"),
        actions: [
          IconButton(
            icon: Icon(_isAdminMode ? Icons.admin_panel_settings : Icons.lock),
            onPressed: _isAdminMode ? _disableAdmin : _enableAdmin,
            color: _isAdminMode ? Colors.green : Colors.grey,
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
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
                subtitle: Text("SKU: \${p.sku} | \${p.category}"),
                trailing: Text("\${p.stock}", style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: p.stock < 10 ? Colors.red : Colors.green,
                )),
                onTap: _isAdminMode ? () {
                  // Lógica para editar stock
                  _firestore.updateStock(p.id, p.stock + 1);
                } : null,
              );
            },
          );
        },
      ),
      floatingActionButton: _isAdminMode ? FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
