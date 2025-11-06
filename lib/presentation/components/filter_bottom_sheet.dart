import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sparix/application/providers/product_stream_provider.dart';
import 'package:sparix/data/models/filter_model.dart';
import 'package:sparix/core/constants/spare_part_filter_options.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  FilterType _selectedFilterType = FilterType.brand;
  late ProductFilter _tempFilter;

  @override
  void initState() {
    super.initState();
    final streamProvider = context.read<ProductStreamProvider>();
    _tempFilter = ProductFilter(
      selectedBrands: Set.from(streamProvider.currentFilter.selectedBrands),
      selectedModels: Set.from(streamProvider.currentFilter.selectedModels),
      selectedCategories: Set.from(streamProvider.currentFilter.selectedCategories),
      selectedPositions: Set.from(streamProvider.currentFilter.selectedPositions),
      selectedWarehouses: Set.from(streamProvider.currentFilter.selectedWarehouses),
      selectedRacks: Set.from(streamProvider.currentFilter.selectedRacks),
      selectedSections: Set.from(streamProvider.currentFilter.selectedSections),
      stockRange: streamProvider.currentFilter.stockRange,
      showInStock: streamProvider.currentFilter.showInStock,
      showOutOfStock: streamProvider.currentFilter.showOutOfStock,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Row(
              children: [
                _buildFilterMenu(),
                const VerticalDivider(width: 1, color: Colors.grey),
                Expanded(child: _buildFilterContent()),
              ],
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Filter Spare Parts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Consumer<ProductStreamProvider>(
            builder: (context, provider, child) {
              final activeFilters = _tempFilter.activeFilterCount;
              if (activeFilters > 0) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5CE65C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$activeFilters active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterMenu() {
    return Container(
      width: 120,
      color: Colors.grey[50],
      child: ListView(
        children: FilterType.values.map((type) {
          final isSelected = _selectedFilterType == type;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedFilterType = type;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF5CE65C) : Colors.transparent,
                  border: isSelected
                      ? null
                      : Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      type.icon,
                      color: isSelected ? Colors.white : Colors.grey[700],
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Consumer<ProductStreamProvider>(
        builder: (context, provider, child) {
          switch (_selectedFilterType) {
            case FilterType.brand:
              return _buildBrandFilter(provider);
            case FilterType.model:
              return _buildModelFilter(provider);
            case FilterType.category:
              return _buildCategoryFilter(provider);
            case FilterType.position:
              return _buildPositionFilter(provider);
            case FilterType.location:
              return _buildLocationFilter(provider);
            case FilterType.stockLevel:
              return _buildStockLevelFilter(provider);
          }
        },
      ),
    );
  }

  Widget _buildBrandFilter(ProductStreamProvider provider) {
    final brands = SparePartFilterOptions.getAllBrands();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Brands',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: ListView(
            children: brands.map((brand) {
              final isSelected = _tempFilter.selectedBrands.contains(brand);
              return CheckboxListTile(
                title: Text(brand),
                value: isSelected,
                activeColor: const Color(0xFF5CE65C),
                onChanged: (value) {
                  setState(() {
                    if (value ?? false) {
                      _tempFilter.selectedBrands.add(brand);
                    } else {
                      _tempFilter.selectedBrands.remove(brand);
                      // Also remove models of this brand when brand is deselected
                      final brandModels = SparePartFilterOptions.getModelsForBrand(brand);
                      _tempFilter.selectedModels.removeWhere((model) => brandModels.contains(model));
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModelFilter(ProductStreamProvider provider) {
    // Get models based on selected brands, or all models if no brands selected
    final models = _tempFilter.selectedBrands.isEmpty
        ? SparePartFilterOptions.getAllModels()
        : _tempFilter.selectedBrands
            .expand((brand) => SparePartFilterOptions.getModelsForBrand(brand))
            .toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _tempFilter.selectedBrands.isEmpty
              ? 'Select Models (All Brands)'
              : 'Select Models (${_tempFilter.selectedBrands.join(", ")})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: models.map((model) {
              final isSelected = _tempFilter.selectedModels.contains(model);
              return CheckboxListTile(
                title: Text(model),
                value: isSelected,
                activeColor: const Color(0xFF5CE65C),
                onChanged: (value) {
                  setState(() {
                    if (value ?? false) {
                      _tempFilter.selectedModels.add(model);
                    } else {
                      _tempFilter.selectedModels.remove(model);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(ProductStreamProvider provider) {
    final categories = SparePartFilterOptions.getAllCategories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Categories',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: categories.map((category) {
              final isSelected = _tempFilter.selectedCategories.contains(category);
              return CheckboxListTile(
                title: Text(category),
                value: isSelected,
                activeColor: const Color(0xFF5CE65C),
                onChanged: (value) {
                  setState(() {
                    if (value ?? false) {
                      _tempFilter.selectedCategories.add(category);
                    } else {
                      _tempFilter.selectedCategories.remove(category);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionFilter(ProductStreamProvider provider) {
    final positions = SparePartFilterOptions.getAllPositions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Positions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: positions.map((position) {
              final isSelected = _tempFilter.selectedPositions.contains(position);
              return CheckboxListTile(
                title: Text(position),
                value: isSelected,
                activeColor: const Color(0xFF5CE65C),
                onChanged: (value) {
                  setState(() {
                    if (value ?? false) {
                      _tempFilter.selectedPositions.add(position);
                    } else {
                      _tempFilter.selectedPositions.remove(position);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationFilter(ProductStreamProvider provider) {
    final warehouses = SparePartFilterOptions.getAllWarehouses();
    final racks = SparePartFilterOptions.getAllRacks();
    final sections = SparePartFilterOptions.getAllSections();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Locations',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Warehouses',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                ),
              ),
              ...warehouses.map((warehouse) {
                final isSelected = _tempFilter.selectedWarehouses.contains(warehouse);
                return CheckboxListTile(
                  title: Text(warehouse),
                  value: isSelected,
                  activeColor: const Color(0xFF5CE65C),
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        _tempFilter.selectedWarehouses.add(warehouse);
                      } else {
                        _tempFilter.selectedWarehouses.remove(warehouse);
                      }
                    });
                  },
                );
              }),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Racks',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                ),
              ),
              ...racks.map((rack) {
                final isSelected = _tempFilter.selectedRacks.contains(rack);
                return CheckboxListTile(
                  title: Text('Rack $rack'),
                  value: isSelected,
                  activeColor: const Color(0xFF5CE65C),
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        _tempFilter.selectedRacks.add(rack);
                      } else {
                        _tempFilter.selectedRacks.remove(rack);
                      }
                    });
                  },
                );
              }),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Sections',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                ),
              ),
              ...sections.map((section) {
                final isSelected = _tempFilter.selectedSections.contains(section);
                return CheckboxListTile(
                  title: Text('Section $section'),
                  value: isSelected,
                  activeColor: const Color(0xFF5CE65C),
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        _tempFilter.selectedSections.add(section);
                      } else {
                        _tempFilter.selectedSections.remove(section);
                      }
                    });
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockLevelFilter(ProductStreamProvider provider) {
    return StreamBuilder<RangeValues>(
      stream: provider.stockRangeStream,
      builder: (context, snapshot) {
        final stockRange = snapshot.data ?? const RangeValues(0, 100);
        final currentRange = _tempFilter.stockRange ?? stockRange;

        return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stock Level Filter',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Stock availability checkboxes
        CheckboxListTile(
          title: const Text('Show In Stock'),
          value: _tempFilter.showInStock,
          activeColor: const Color(0xFF5CE65C),
          onChanged: (value) {
            setState(() {
              _tempFilter = _tempFilter.copyWith(showInStock: value ?? true);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('Show Out of Stock'),
          value: _tempFilter.showOutOfStock,
          activeColor: const Color(0xFF5CE65C),
          onChanged: (value) {
            setState(() {
              _tempFilter = _tempFilter.copyWith(showOutOfStock: value ?? true);
            });
          },
        ),

        const SizedBox(height: 20),
        const Text(
          'Stock Range',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),

        RangeSlider(
          values: currentRange,
          min: stockRange.start,
          max: stockRange.end,
          divisions: (stockRange.end - stockRange.start).round(),
          activeColor: const Color(0xFF5CE65C),
          inactiveColor: Colors.grey[300],
          labels: RangeLabels(
            '${currentRange.start.round()}',
            '${currentRange.end.round()}',
          ),
          onChanged: (RangeValues values) {
            setState(() {
              _tempFilter = _tempFilter.copyWith(stockRange: values);
            });
          },
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${currentRange.start.round()}'),
            Text('${currentRange.end.round()}'),
          ],
        ),
        ],
        );
      },
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                final streamProvider = context.read<ProductStreamProvider>();
                streamProvider.applyFilter(_tempFilter);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5CE65C),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}