import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sparix/data/repositories/product_repository.dart';
import 'package:sparix/data/models/spare_part.dart';
import 'package:sparix/core/constants/spare_part_filter_options.dart';

class AddEditSparePartScreen extends StatefulWidget {
  final Product? existingProduct;
  
  const AddEditSparePartScreen({
    super.key,
    this.existingProduct,
  });

  @override
  State<AddEditSparePartScreen> createState() => _AddEditSparePartScreenState();
}

class _AddEditSparePartScreenState extends State<AddEditSparePartScreen> {
  // Controllers for text fields
  final TextEditingController productNameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController salesAmountController = TextEditingController();
  final TextEditingController warrantyController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController stockThresholdController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Form key for validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Repository for Firestore operations
  final ProductRepository _productRepository = ProductRepository();

  // Loading state
  bool _isSubmitting = false;

  // Dropdown values
  String? selectedLocation;
  String? selectedBrand;
  String? selectedModel;
  String? selectedCategory;
  String? selectedStabilizerLink;
  String? selectedPositionFront;
  String? selectedPositionRear;

  // Location detail dropdowns
  String? selectedSection = 'A';
  String? selectedWarehouse = 'Warehouse';
  String? selectedNumber1 = '01';
  String? selectedRack = 'Rack';
  String? selectedNumber2 = '01';
  String? selectedSectionType = 'Section';

  // Image picker
  File? _selectedImage;
  String? _existingImageUrl;
  final ImagePicker _imagePicker = ImagePicker();
  
  bool get _isEditing => widget.existingProduct != null;
  
  // Get available models based on selected brand
  List<String> get _availableModels {
    if (selectedBrand == null || selectedBrand!.isEmpty) {
      return SparePartFilterOptions.getAllModels();
    }
    return SparePartFilterOptions.getModelsForBrand(selectedBrand!);
  }

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateFieldsForEditing();
    }
  }
  
  void _populateFieldsForEditing() {
    final product = widget.existingProduct!;
    productNameController.text = product.name;
    priceController.text = product.price.toString();
    salesAmountController.text = product.salesAmount.toString();
    warrantyController.text = product.warrantyMonths.toString();
    quantityController.text = product.stock.toString();
    stockThresholdController.text = product.stockThreshold.toString();
    descriptionController.text = product.description.join('\n');
    
    selectedSection = product.warehouse;
    selectedNumber1 = product.rack;
    selectedNumber2 = product.section;
    
    // Validate brand exists in constants
    if (SparePartFilterOptions.getAllBrands().contains(product.brand)) {
      selectedBrand = product.brand;
      // Validate model exists for the brand
      final availableModels = SparePartFilterOptions.getModelsForBrand(product.brand);
      if (availableModels.contains(product.model)) {
        selectedModel = product.model;
      } else {
        // Model doesn't exist for this brand, leave null for user to select
        selectedModel = null;
      }
    } else {
      // Brand doesn't exist, leave both null for user to select
      selectedBrand = null;
      selectedModel = null;
    }
    
    // Validate category exists in constants
    if (SparePartFilterOptions.getAllCategories().contains(product.category)) {
      selectedCategory = product.category;
    } else {
      selectedCategory = null;
    }
    
    // Validate position exists in constants
    if (SparePartFilterOptions.getAllPositions().contains(product.position)) {
      selectedPositionFront = product.position;
    } else {
      selectedPositionFront = null;
    }
    
    _existingImageUrl = product.imageUrl;
  }

  @override
  void dispose() {
    productNameController.dispose();
    priceController.dispose();
    salesAmountController.dispose();
    warrantyController.dispose();
    descriptionController.dispose();
    quantityController.dispose();
    stockThresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditing ? 'Edit Spare Part' : 'Add New Spare part',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Section
                GestureDetector(
                  onTap: _showImagePickerDialog,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        style: BorderStyle.solid,
                        width: 1,
                      ),
                    ),
                    child: _selectedImage != null
                        ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImage!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _removeImage,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                    : _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                        ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _existingImageUrl!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _removeImage,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 30,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add product image',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Product Name
                _buildLabel('Product Name *'),
                _buildTextFormField(
                  controller: productNameController,
                  hint: 'Enter spare part name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Product name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Price
                _buildLabel('Supplier Price (RM) *'),
                _buildTextFormField(
                  controller: priceController,
                  hint: 'Enter supplier price',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Supplier price is required';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Please enter a valid supplier price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Sales Amount
                _buildLabel('Sales Amount (RM) *'),
                _buildTextFormField(
                  controller: salesAmountController,
                  hint: 'Enter sales amount',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Sales amount is required';
                    }
                    final salesAmount = double.tryParse(value);
                    if (salesAmount == null || salesAmount <= 0) {
                      return 'Please enter a valid sales amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Warranty
                _buildLabel('Warranty (in month) *'),
                _buildTextFormField(
                  controller: warrantyController,
                  hint: 'Enter spare part warranty period',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Warranty period is required';
                    }
                    final warranty = int.tryParse(value);
                    if (warranty == null || warranty < 0) {
                      return 'Please enter a valid warranty period';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Spare part stock level
                _buildLabel('Quantity *'),
                _buildTextFormField(
                  controller: quantityController,
                  hint: 'Enter spare part quantity',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Spare part quantity is required';
                    }
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity < 0) {
                      return 'Please enter a valid quantity number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Stock threshold
                _buildLabel('Stock Threshold *'),
                _buildTextFormField(
                  controller: stockThresholdController,
                  hint: 'Enter stock threshold level',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Stock threshold is required';
                    }
                    final threshold = int.tryParse(value);
                    if (threshold == null || threshold < 0) {
                      return 'Please enter a valid threshold number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Location
                _buildLabel('Location *'),

                // Location Details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      // Warehouse Row
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Warehouse',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildCompactDropdown(
                              value: selectedSection,
                              items: SparePartFilterOptions.getAllWarehouses(),
                              onChanged: (value) {
                                setState(() {
                                  selectedSection = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Rack Row
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Rack',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildCompactDropdown(
                              value: selectedNumber1,
                              items: SparePartFilterOptions.getAllRacks(),
                              onChanged: (value) {
                                setState(() {
                                  selectedNumber1 = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Section Row
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              'Section',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                          Expanded(
                            child: _buildCompactDropdown(
                              value: selectedNumber2,
                              items: SparePartFilterOptions.getAllSections(),
                              onChanged: (value) {
                                setState(() {
                                  selectedNumber2 = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Brand
                _buildLabel('Brand *'),
                _buildDropdown(
                  value: selectedBrand,
                  hint: 'Select Brand',
                  items: SparePartFilterOptions.getAllBrands(),
                  onChanged: (value) {
                    setState(() {
                      selectedBrand = value;
                      // Clear model selection when brand changes
                      if (selectedModel != null && !_availableModels.contains(selectedModel)) {
                        selectedModel = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Model
                _buildLabel('Model *'),
                _buildDropdown(
                  value: selectedModel,
                  hint: selectedBrand == null ? 'Select Brand First' : 'Select Model',
                  items: _availableModels,
                  onChanged: selectedBrand == null ? null : (value) {
                    setState(() {
                      selectedModel = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Product Category
                _buildLabel('Product Category *'),
                _buildDropdown(
                  value: selectedCategory,
                  hint: 'Select Category',
                  items: SparePartFilterOptions.getAllCategories(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Position
                _buildLabel('Position *'),
                _buildDropdown(
                  value: selectedPositionFront,
                  hint: 'Select Position',
                  items: SparePartFilterOptions.getAllPositions(),
                  onChanged: (value) {
                    setState(() {
                      selectedPositionFront = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Product Description
                _buildLabelWithGenerateButton('Product Description'),
                _buildProductDescriptionField(
                  controller: descriptionController,
                  hint: 'Enter spare part description (optional)',
                  keyboardType: TextInputType.multiline,
                  validator: null,
                ),
                const SizedBox(height: 30),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Back',
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
                        onPressed: _isSubmitting ? null : _validateAndSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF90EE90),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                            strokeWidth: 2,
                          ),
                        )
                            : Text(
                          _isEditing ? 'Update' : 'Confirm',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildProductDescriptionField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final isMultiline = keyboardType == TextInputType.multiline;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      minLines: isMultiline ? 8 : 1, // default visible lines
      maxLines: isMultiline ? null : 1, // expand if multiline
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildLabelWithGenerateButton(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: keyboardType == TextInputType.multiline ? 3 : 1,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?)? onChanged,
  }) {
    final isEnabled = onChanged != null;
    // Validate that the value exists in items list
    final validValue = (value != null && items.contains(value)) ? value : null;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.grey[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          hint: Text(
            hint,
            style: TextStyle(
              color: isEnabled ? Colors.grey[600] : Colors.grey[400],
            ),
          ),
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isEnabled ? Colors.black87 : Colors.grey[400],
          ),
          items: isEnabled
              ? items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }).toList()
              : null,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCompactDropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    // Validate that the value exists in items list
    final validValue = (value != null && items.contains(value)) ? value : null;
    
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validValue,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Image picker dialog
  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Remove selected image
  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _existingImageUrl = null;
    });
  }

  // Validate and submit form
  void _validateAndSubmit() {
    // Validate image first (only for new products)
    if (!_isEditing && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product image'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate dropdowns
    if (selectedBrand == null || selectedBrand!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a brand'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedModel == null || selectedModel!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a model'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedCategory == null || selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedPositionFront == null || selectedPositionFront!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a position'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate form fields
    if (_formKey.currentState!.validate()) {
      // All validation passed
      _submitForm();
    }
  }

  // Submit form after validation
  Future<void> _submitForm() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isEditing) {
        // Update existing product
        final existingProduct = widget.existingProduct!;
        
        // Handle image upload if new image is selected
        String imageUrl = _existingImageUrl ?? '';
        if (_selectedImage != null) {
          imageUrl = await _productRepository.uploadProductImage(
            productId: existingProduct.productId,
            imageFile: _selectedImage!,
          );
        }

        // Create updated Product object
        final updatedProduct = existingProduct.copyWith(
          name: productNameController.text.trim(),
          price: double.parse(priceController.text.trim()),
          salesAmount: double.parse(salesAmountController.text.trim()),
          stock: int.tryParse(quantityController.text.trim()) ?? 0,
          stockThreshold: int.tryParse(stockThresholdController.text.trim()) ?? 5,
          warehouse: selectedSection ?? 'A',
          rack: selectedNumber1 ?? '01',
          section: selectedNumber2 ?? '01',
          brand: selectedBrand!,
          model: selectedModel!,
          category: selectedCategory!,
          position: selectedPositionFront!,
          warrantyMonths: int.parse(warrantyController.text.trim()),
          imageUrl: imageUrl,
          description: descriptionController.text.trim().isEmpty
              ? []
              : [descriptionController.text.trim()],
          updatedAt: DateTime.now(),
        );

        // Update product in Firestore
        await _productRepository.updateProduct(updatedProduct);
        
        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Spare part updated successfully!'),
                ],
              ),
              backgroundColor: Color(0xFF5CE65C),
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate back
          Navigator.of(context).pop(true);
        }
      } else {
        // Add new product (existing logic)
        final productId = _productRepository.generateProductId();

        // Upload image and get URL
        String imageUrl = '';
        if (_selectedImage != null) {
          imageUrl = await _productRepository.uploadProductImage(
            productId: productId,
            imageFile: _selectedImage!,
          );
        }

        // Create Product object
        final product = Product(
          productId: productId,
          name: productNameController.text.trim(),
          price: double.parse(priceController.text.trim()),
          salesAmount: double.parse(salesAmountController.text.trim()),
          currency: 'RM',
          stock: int.tryParse(quantityController.text.trim()) ?? 0,
          stockThreshold: int.tryParse(stockThresholdController.text.trim()) ?? 5,
          status: 'Available',
          warehouse: selectedSection ?? 'A',
          rack: selectedNumber1 ?? '01',
          section: selectedNumber2 ?? '01',
          brand: selectedBrand!,
          model: selectedModel!,
          category: selectedCategory!,
          position: selectedPositionFront!,
          warrantyMonths: int.parse(warrantyController.text.trim()),
          imageUrl: imageUrl,
          description: descriptionController.text.trim().isEmpty
              ? []
              : [descriptionController.text.trim()],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Add product to Firestore
        await _productRepository.addProduct(product);

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Spare part added successfully!'),
                ],
              ),
              backgroundColor: Color(0xFF5CE65C),
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate back
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_isEditing
                      ? 'Failed to update spare part: ${e.toString()}'
                      : 'Failed to add spare part: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
  
}