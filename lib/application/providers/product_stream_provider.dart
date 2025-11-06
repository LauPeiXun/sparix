import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sparix/data/models/spare_part.dart';
import 'package:sparix/data/repositories/product_repository.dart';
import 'package:sparix/data/models/filter_model.dart';

class ProductStreamProvider extends ChangeNotifier {
  final ProductRepository _productRepository = ProductRepository();

  String _searchQuery = '';
  ProductFilter _currentFilter = ProductFilter();

  // Getters
  String get searchQuery => _searchQuery;
  ProductFilter get currentFilter => _currentFilter;

  /// Get filtered products stream
  Stream<List<Product>> get filteredProductsStream {
    return _productRepository.getAllProductsStream().map((products) {
      List<Product> filtered = products;

      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        filtered = filtered.where((product) {
          return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              product.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              product.model.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              product.category.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }

      // Apply advanced filters
      if (!_currentFilter.isEmpty) {
        filtered = _applyAdvancedFilters(filtered);
      }

      return filtered;
    });
  }

  List<Product> _applyAdvancedFilters(List<Product> products) {
    return products.where((product) {
      // Brand filter
      if (_currentFilter.selectedBrands.isNotEmpty &&
          !_currentFilter.selectedBrands.contains(product.brand)) {
        return false;
      }

      // Model filter
      if (_currentFilter.selectedModels.isNotEmpty &&
          !_currentFilter.selectedModels.contains(product.model)) {
        return false;
      }

      // Category filter
      if (_currentFilter.selectedCategories.isNotEmpty &&
          !_currentFilter.selectedCategories.contains(product.category)) {
        return false;
      }

      // Position filter
      if (_currentFilter.selectedPositions.isNotEmpty &&
          !_currentFilter.selectedPositions.contains(product.position)) {
        return false;
      }

      // Location filters
      if (_currentFilter.selectedWarehouses.isNotEmpty &&
          !_currentFilter.selectedWarehouses.contains(product.warehouse)) {
        return false;
      }

      if (_currentFilter.selectedRacks.isNotEmpty &&
          !_currentFilter.selectedRacks.contains(product.rack)) {
        return false;
      }

      if (_currentFilter.selectedSections.isNotEmpty &&
          !_currentFilter.selectedSections.contains(product.section)) {
        return false;
      }

      // Stock level filter
      if (_currentFilter.stockRange != null) {
        final stock = product.stock.toDouble();
        if (stock < _currentFilter.stockRange!.start ||
            stock > _currentFilter.stockRange!.end) {
          return false;
        }
      }

      // Stock availability filter
      if (!_currentFilter.showInStock && product.stock > 0) {
        return false;
      }
      if (!_currentFilter.showOutOfStock && product.stock == 0) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Search products
  void searchProducts(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Apply filters
  void applyFilter(ProductFilter filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  /// Clear filters
  void clearFilters() {
    _currentFilter = ProductFilter();
    notifyListeners();
  }

  /// Get unique values for filter options (using current stream data)
  Stream<Set<String>> get uniqueBrandsStream {
    return _productRepository.getAllProductsStream().map(
          (products) => products.map((p) => p.brand).toSet(),
    );
  }

  Stream<Set<String>> get uniqueModelsStream {
    return _productRepository.getAllProductsStream().map(
          (products) => products.map((p) => p.model).toSet(),
    );
  }

  Stream<Set<String>> get uniqueCategoriesStream {
    return _productRepository.getAllProductsStream().map(
          (products) => products.map((p) => p.category).toSet(),
    );
  }

  Stream<Set<String>> get uniquePositionsStream {
    return _productRepository.getAllProductsStream().map(
          (products) => products.map((p) => p.position).toSet(),
    );
  }

  Stream<Set<String>> get uniqueWarehousesStream {
    return _productRepository.getAllProductsStream().map(
          (products) => products.map((p) => p.warehouse).toSet(),
    );
  }

  Stream<Set<String>> get uniqueRacksStream {
    return _productRepository.getAllProductsStream().map(
          (products) => products.map((p) => p.rack).toSet(),
    );
  }

  Stream<Set<String>> get uniqueSectionsStream {
    return _productRepository.getAllProductsStream().map(
          (products) => products.map((p) => p.section).toSet(),
    );
  }

  /// Get stock range stream
  Stream<RangeValues> get stockRangeStream {
    return _productRepository.getAllProductsStream().map((products) {
      if (products.isEmpty) return const RangeValues(0, 100);

      final stocks = products.map((p) => p.stock.toDouble()).toList();
      final min = stocks.reduce((a, b) => a < b ? a : b);
      final max = stocks.reduce((a, b) => a > b ? a : b);

      return RangeValues(min, max.clamp(min + 1, double.infinity));
    });
  }

  /// Get a single product stream by ID
  Stream<Product?> getProductStreamById(String productId) {
    return _productRepository.getProductByIdStream(productId);
  }
}