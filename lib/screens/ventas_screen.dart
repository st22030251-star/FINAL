import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Historial de Ventas")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sales').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final sales = snapshot.data!.docs;
          return ListView.builder(
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final s = sales[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text("Venta #\${sales[index].id.substring(0, 8)}"),
                  subtitle: Text("\${s['timestamp']?.toDate()?.toString() ?? 'Fecha pendiente'}"),
                  trailing: Text("\$\${(s['total'] ?? 0.0).toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
