import 'package:flutter/material.dart';

class ProductFilter {
  final Set<String> selectedBrands;
  final Set<String> selectedModels;
  final Set<String> selectedCategories;
  final Set<String> selectedPositions;
  final Set<String> selectedWarehouses;
  final Set<String> selectedRacks;
  final Set<String> selectedSections;
  final RangeValues? stockRange;
  final bool showInStock;
  final bool showOutOfStock;

  ProductFilter({
    Set<String>? selectedBrands,
    Set<String>? selectedModels,
    Set<String>? selectedCategories,
    Set<String>? selectedPositions,
    Set<String>? selectedWarehouses,
    Set<String>? selectedRacks,
    Set<String>? selectedSections,
    this.stockRange,
    this.showInStock = true,
    this.showOutOfStock = true,
  }) :
        selectedBrands = selectedBrands ?? {},
        selectedModels = selectedModels ?? {},
        selectedCategories = selectedCategories ?? {},
        selectedPositions = selectedPositions ?? {},
        selectedWarehouses = selectedWarehouses ?? {},
        selectedRacks = selectedRacks ?? {},
        selectedSections = selectedSections ?? {};

  ProductFilter copyWith({
    Set<String>? selectedBrands,
    Set<String>? selectedModels,
    Set<String>? selectedCategories,
    Set<String>? selectedPositions,
    Set<String>? selectedWarehouses,
    Set<String>? selectedRacks,
    Set<String>? selectedSections,
    RangeValues? stockRange,
    bool? showInStock,
    bool? showOutOfStock,
    bool clearStockRange = false,
  }) {
    return ProductFilter(
      selectedBrands: selectedBrands ?? this.selectedBrands,
      selectedModels: selectedModels ?? this.selectedModels,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedPositions: selectedPositions ?? this.selectedPositions,
      selectedWarehouses: selectedWarehouses ?? this.selectedWarehouses,
      selectedRacks: selectedRacks ?? this.selectedRacks,
      selectedSections: selectedSections ?? this.selectedSections,
      stockRange: clearStockRange ? null : (stockRange ?? this.stockRange),
      showInStock: showInStock ?? this.showInStock,
      showOutOfStock: showOutOfStock ?? this.showOutOfStock,
    );
  }

  bool get isEmpty {
    return selectedBrands.isEmpty &&
        selectedModels.isEmpty &&
        selectedCategories.isEmpty &&
        selectedPositions.isEmpty &&
        selectedWarehouses.isEmpty &&
        selectedRacks.isEmpty &&
        selectedSections.isEmpty &&
        stockRange == null &&
        showInStock == true &&
        showOutOfStock == true;
  }

  int get activeFilterCount {
    int count = 0;
    if (selectedBrands.isNotEmpty) count++;
    if (selectedModels.isNotEmpty) count++;
    if (selectedCategories.isNotEmpty) count++;
    if (selectedPositions.isNotEmpty) count++;
    if (selectedWarehouses.isNotEmpty || selectedRacks.isNotEmpty || selectedSections.isNotEmpty) count++;
    if (stockRange != null) count++;
    if (!showInStock || !showOutOfStock) count++;
    return count;
  }

  ProductFilter clear() {
    return ProductFilter();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductFilter &&
        _setEquals(other.selectedBrands, selectedBrands) &&
        _setEquals(other.selectedModels, selectedModels) &&
        _setEquals(other.selectedCategories, selectedCategories) &&
        _setEquals(other.selectedPositions, selectedPositions) &&
        _setEquals(other.selectedWarehouses, selectedWarehouses) &&
        _setEquals(other.selectedRacks, selectedRacks) &&
        _setEquals(other.selectedSections, selectedSections) &&
        other.stockRange == stockRange &&
        other.showInStock == showInStock &&
        other.showOutOfStock == showOutOfStock;
  }

  bool _setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    for (final item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      selectedBrands.hashCode,
      selectedModels.hashCode,
      selectedCategories.hashCode,
      selectedPositions.hashCode,
      selectedWarehouses.hashCode,
      selectedRacks.hashCode,
      selectedSections.hashCode,
      stockRange.hashCode,
      showInStock.hashCode,
      showOutOfStock.hashCode,
    );
  }
}

enum FilterType {
  brand,
  model,
  category,
  position,
  location,
  stockLevel,
}

extension FilterTypeExtension on FilterType {
  String get displayName {
    switch (this) {
      case FilterType.brand:
        return 'Brand';
      case FilterType.model:
        return 'Model';
      case FilterType.category:
        return 'Category';
      case FilterType.position:
        return 'Position';
      case FilterType.location:
        return 'Location';
      case FilterType.stockLevel:
        return 'Stock Level';
    }
  }

  IconData get icon {
    switch (this) {
      case FilterType.brand:
        return Icons.business;
      case FilterType.model:
        return Icons.directions_car;
      case FilterType.category:
        return Icons.category;
      case FilterType.position:
        return Icons.settings;
      case FilterType.location:
        return Icons.location_on;
      case FilterType.stockLevel:
        return Icons.inventory;
    }
  }
}