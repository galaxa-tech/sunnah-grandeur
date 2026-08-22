import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class StoreProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;

  List<ProductModel> get products => _filteredProducts;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;

  StoreProvider() {
    fetchAllProducts();
  }

  Future<void> fetchAllProducts() async {
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _db.collection('products').get();
      _allProducts = snap.docs.map((d) => ProductModel.fromMap(d.data(), d.id)).toList();
      _applyFilter();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching products: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_selectedCategory == 'All') {
      _filteredProducts = _allProducts;
    } else {
      _filteredProducts = _allProducts.where((p) {
        // Assuming products have a 'category' field in Firestore
        // If not, we fall back to title match for demo purposes if needed, 
        // but let's assume valid category field exists.
        return p.category.toLowerCase() == _selectedCategory.toLowerCase();
      }).toList();
    }
  }

  Future<void> refresh() async {
    await fetchAllProducts();
  }
}
