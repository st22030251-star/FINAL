import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addProduct(Product product) {
    return _db.collection('products').add(product.toMap());
  }

  Future<void> updateStock(String id, int newStock) {
    return _db.collection('products').doc(id).update({'stock': newStock});
  }

  Future<void> saveSale(Map<String, dynamic> saleData) {
    return _db.collection('sales').add({
      ...saleData,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
