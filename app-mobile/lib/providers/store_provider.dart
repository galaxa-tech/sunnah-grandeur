import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/store_category_model.dart';

enum StoreSort { featured, priceLow, priceHigh, newest }

class StoreProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _productsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _categoriesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _bannersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _favoritesSub;
  StreamSubscription<User?>? _authSub;

  List<ProductModel> _allProducts = [];
  List<StoreCategoryModel> _categories = _fallbackCategories;
  List<StoreBannerModel> _banners = [];
  Set<String> _favoriteIds = {};
  String? _selectedCategoryId;
  String _searchQuery = '';
  StoreSort _sort = StoreSort.featured;
  bool _isLoading = true;
  String? _error;

  StoreProvider() {
    _listenProducts();
    _listenCategories();
    _listenBanners();
    _authSub = _auth.authStateChanges().listen(_listenFavorites);
  }

  List<ProductModel> get allProducts => _allProducts;
  List<StoreCategoryModel> get categories => _categories;
  List<StoreBannerModel> get banners => _banners;
  Set<String> get favoriteIds => _favoriteIds;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  StoreSort get sort => _sort;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get selectedCategoryName {
    if (_selectedCategoryId == null) return 'All Products';
    return _categories
        .firstWhere(
          (c) => c.id == _selectedCategoryId,
          orElse: () => StoreCategoryModel(
            id: _selectedCategoryId!,
            name: _selectedCategoryId!,
            iconKey: 'storefront',
            accentColor: const Color(0xFFC9A84C),
            sortOrder: 999,
          ),
        )
        .name;
  }

  List<ProductModel> get featuredProducts {
    final featured = _allProducts.where((p) => p.isFeatured).toList();
    return featured.isNotEmpty ? featured.take(8).toList() : _allProducts.take(8).toList();
  }

  List<ProductModel> get products {
    Iterable<ProductModel> list = _allProducts;

    if (_selectedCategoryId != null) {
      list = list.where((p) => p.categoryId == _selectedCategoryId);
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query) ||
            p.description.toLowerCase().contains(query) ||
            p.sku.toLowerCase().contains(query);
      });
    }

    final sorted = list.toList();
    switch (_sort) {
      case StoreSort.priceLow:
        sorted.sort((a, b) => a.priceInCents.compareTo(b.priceInCents));
        break;
      case StoreSort.priceHigh:
        sorted.sort((a, b) => b.priceInCents.compareTo(a.priceInCents));
        break;
      case StoreSort.newest:
        sorted.sort((a, b) => b.id.compareTo(a.id));
        break;
      case StoreSort.featured:
        sorted.sort((a, b) {
          if (a.isFeatured == b.isFeatured) return a.name.compareTo(b.name);
          return a.isFeatured ? -1 : 1;
        });
        break;
    }
    return sorted;
  }

  int countForCategory(String? categoryId) {
    if (categoryId == null) return _allProducts.length;
    return _allProducts.where((p) => p.categoryId == categoryId).length;
  }

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  void setCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearch(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setSort(StoreSort sort) {
    _sort = sort;
    notifyListeners();
  }

  Future<void> toggleFavorite(ProductModel product) async {
    final user = _auth.currentUser;
    if (user == null) {
      _favoriteIds.contains(product.id)
          ? _favoriteIds.remove(product.id)
          : _favoriteIds.add(product.id);
      notifyListeners();
      return;
    }

    final ref = _db
        .collection('favorites')
        .doc(user.uid)
        .collection('items')
        .doc(product.id);

    if (_favoriteIds.contains(product.id)) {
      await ref.delete();
    } else {
      await ref.set({
        'productId': product.id,
        'name': product.name,
        'priceInCents': product.priceInCents,
        'image': product.primaryImage,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _listenProducts() {
    _productsSub = _db
        .collection('products')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      _allProducts = snap.docs.map((d) => ProductModel.fromMap(d.data(), d.id)).toList();
      _isLoading = false;
      _error = null;
      notifyListeners();
    }, onError: (Object e) {
      debugPrint('[StoreProvider] products: $e');
      _isLoading = false;
      _error = 'Could not load products.';
      notifyListeners();
    });
  }

  void _listenCategories() {
    _categoriesSub = _db
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      final remote = snap.docs
          .map((d) => StoreCategoryModel.fromMap(d.data(), d.id))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (remote.isNotEmpty) _categories = remote;
      notifyListeners();
    }, onError: (Object e) => debugPrint('[StoreProvider] categories: $e'));
  }

  void _listenBanners() {
    _bannersSub = _db
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snap) {
      _banners = snap.docs.map((d) => StoreBannerModel.fromMap(d.data(), d.id)).toList();
      notifyListeners();
    }, onError: (Object e) => debugPrint('[StoreProvider] banners: $e'));
  }

  void _listenFavorites(User? user) {
    _favoritesSub?.cancel();
    _favoriteIds = {};
    if (user == null) {
      notifyListeners();
      return;
    }
    _favoritesSub = _db
        .collection('favorites')
        .doc(user.uid)
        .collection('items')
        .snapshots()
        .listen((snap) {
      _favoriteIds = snap.docs.map((d) => d.id).toSet();
      notifyListeners();
    }, onError: (Object e) => debugPrint('[StoreProvider] favorites: $e'));
  }

  @override
  void dispose() {
    _productsSub?.cancel();
    _categoriesSub?.cancel();
    _bannersSub?.cancel();
    _favoritesSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}

const _fallbackCategories = <StoreCategoryModel>[
  StoreCategoryModel(id: 'men', name: 'Men', iconKey: 'person', accentColor: Color(0xFFC9A84C), sortOrder: 1),
  StoreCategoryModel(id: 'women', name: 'Women', iconKey: 'woman', accentColor: Color(0xFF8BC38B), sortOrder: 2),
  StoreCategoryModel(id: 'kids', name: 'Kids', iconKey: 'child_care', accentColor: Color(0xFF6BB5D4), sortOrder: 3),
  StoreCategoryModel(id: 'salah', name: 'Salah & Worship', iconKey: 'mosque', accentColor: Color(0xFFC9A84C), sortOrder: 4),
  StoreCategoryModel(id: 'quran', name: 'Quran & Books', iconKey: 'menu_book', accentColor: Color(0xFF8BC38B), sortOrder: 5),
  StoreCategoryModel(id: 'fragrance', name: 'Fragrance', iconKey: 'water_drop', accentColor: Color(0xFFC9A84C), sortOrder: 6),
  StoreCategoryModel(id: 'home', name: 'Home & Decor', iconKey: 'home', accentColor: Color(0xFF6BB5D4), sortOrder: 7),
  StoreCategoryModel(id: 'ramadan', name: 'Ramadan & Eid', iconKey: 'star', accentColor: Color(0xFFE87D7D), sortOrder: 8),
  StoreCategoryModel(id: 'hajj', name: 'Hajj & Umrah', iconKey: 'flight', accentColor: Color(0xFF7DD4A8), sortOrder: 9),
  StoreCategoryModel(id: 'gifts', name: 'Gifts', iconKey: 'card_giftcard', accentColor: Color(0xFFD4A0C4), sortOrder: 10),
];
