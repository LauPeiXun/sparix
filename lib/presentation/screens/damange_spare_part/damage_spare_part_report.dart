import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sparix/presentation/components/nav_bar.dart';
import 'package:sparix/data/repositories/product_repository.dart';
import 'package:sparix/data/models/spare_part.dart';
import 'package:sparix/application/providers/damage_report_provider.dart';
import 'package:sparix/application/providers/employee_provider.dart';

class DamageSparePartReport extends StatefulWidget {
  const DamageSparePartReport({super.key});

  @override
  State<DamageSparePartReport> createState() => _DamageSparePartReportState();
}

class _DamageSparePartReportState extends State<DamageSparePartReport> {
  final TextEditingController _partNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _reportedByController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ProductRepository _productRepository = ProductRepository();
  
  String? _selectedReportType;
  DateTime _selectedDate = DateTime.now();
  // ignore: prefer_final_fields
  List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;
  
  final List<String> _reportTypes = ['Damage', 'Lost'];
  
  // For part name search
  List<Product> _searchResults = [];
  Product? _selectedProduct;
  bool _isSearching = false;
  final FocusNode _partNameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Load user after the widget is built to ensure provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadCurrentUser();
    });
  }

  Future<void> _loadCurrentUser() async {
    // First, try to load current employee data from provider
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      try {
        // Try to get employee by email
        await employeeProvider.getEmployeeByEmail(user.email!);
      } catch (e) {
        // If employee not found, that's fine - we'll fall back to Firebase Auth data
        debugPrint('Employee not found for ${user.email}: $e');
      }
    }
    
    setState(() {
      _reportedByController.text = _getCurrentUserName();
    });
  }

  String _getCurrentUserName() {
    // Try to get current employee from provider first
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    if (employeeProvider.currentEmployee != null && 
        employeeProvider.currentEmployee!.name.isNotEmpty) {
      return employeeProvider.currentEmployee!.name;
    }

    // Fallback to Firebase Auth user
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Use display name if available, otherwise use email, otherwise use UID
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName!;
      } else if (user.email != null && user.email!.isNotEmpty) {
        return user.email!.split('@')[0]; // Use email username part
      } else {
        return 'User ${user.uid.substring(0, 8)}';
      }
    }
    
    return 'Anonymous User';
  }

  @override
  void dispose() {
    _partNameController.dispose();
    _quantityController.dispose();
    _reportedByController.dispose();
    _descriptionController.dispose();
    _partNameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
        title: const Text(
          'Damage Spare Part Report',
          style: TextStyle(
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
                // Part Name Search
                _buildLabel('Part Name *'),
                _buildPartNameSearchField(),
                const SizedBox(height: 16),

                // Report Type
                _buildLabel('Report Type *'),
                _buildDropdown(
                  value: _selectedReportType,
                  hint: 'Select Report Type',
                  items: _reportTypes,
                  onChanged: (value) {
                    setState(() {
                      _selectedReportType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Quantity
                _buildLabel('Quantity *'),
                _buildTextFormField(
                  controller: _quantityController,
                  hint: _selectedProduct != null 
                      ? 'Enter quantity (Max: ${_selectedProduct!.stock})' 
                      : 'Enter number of affected parts',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Quantity is required';
                    }
                    final quantity = int.tryParse(value);
                    if (quantity == null || quantity <= 0) {
                      return 'Please enter a valid quantity';
                    }
                    
                    // Check if quantity exceeds available stock
                    if (_selectedProduct != null) {
                      if (quantity > _selectedProduct!.stock) {
                        return 'Quantity cannot exceed available stock (${_selectedProduct!.stock})';
                      }
                    }
                    
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date Reported
                _buildLabel('Date Reported *'),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                _buildLabel('Description / Remarks'),
                _buildTextFormField(
                  controller: _descriptionController,
                  hint: 'Enter short note about the issue (optional)',
                  keyboardType: TextInputType.multiline,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                // Image Upload Section
                _buildLabel('Damage Spare Part Image Upload'),
                _buildImageUploadSection(),
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
                            : const Text(
                                'Submit Report',
                                style: TextStyle(
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
      bottomNavigationBar: const CustomNavBar(currentIndex: 1),
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        filled: true,
        fillColor: enabled ? Colors.grey[100] : Colors.grey[200],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey[600]),
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload button
        GestureDetector(
          onTap: _showImagePickerDialog,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 40,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to add images of damaged part',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Multiple images allowed',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Selected images grid
        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
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
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Images'),
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
                  _pickMultipleImages();
                },
              ),
            ],
          ),
        );
      },
    );
  }

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
          _selectedImages.add(File(pickedFile.path));
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

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (final file in pickedFiles) {
            _selectedImages.add(File(file.path));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _validateAndSubmit() {
    // Validate selected product
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a part from the search results'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate report type
    if (_selectedReportType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a report type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate form fields
    if (_formKey.currentState!.validate()) {
      _submitForm();
    }
  }

  Widget _buildPartNameSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _partNameController,
          focusNode: _partNameFocusNode,
          decoration: InputDecoration(
            hintText: 'Search for spare part...',
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
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: _onSearchTextChanged,
          validator: (value) {
            if (_selectedProduct == null) {
              return 'Please select a part from the search results';
            }
            return null;
          },
        ),
        
        // Search results dropdown
        if (_searchResults.isNotEmpty && _partNameFocusNode.hasFocus)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final product = _searchResults[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      product.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      '${product.brand} - ${product.model} | Stock: ${product.stock}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () => _selectProduct(product),
                  );
                },
              ),
            ),
          ),
          
        // Selected product display
        if (_selectedProduct != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedProduct!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${_selectedProduct!.brand} - ${_selectedProduct!.model}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: _clearSelectedProduct,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _onSearchTextChanged(String value) {
    if (value.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _selectedProduct = null;
        _quantityController.clear(); // Clear quantity when search is cleared
      });
      return;
    }

    // Clear selected product if user continues typing
    if (_selectedProduct != null && value != _selectedProduct!.name) {
      setState(() {
        _selectedProduct = null;
        _quantityController.clear(); // Clear quantity when product selection changes
      });
    }

    _searchProducts(value);
  }

  Future<void> _searchProducts(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final products = await _productRepository.searchProductsByName(query);
      
      if (mounted) {
        setState(() {
          _searchResults = products.take(10).toList(); // Limit to 10 results
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectProduct(Product product) {
    setState(() {
      _selectedProduct = product;
      _partNameController.text = product.name;
      _searchResults.clear();
    });
    _partNameFocusNode.unfocus();
  }

  void _clearSelectedProduct() {
    setState(() {
      _selectedProduct = null;
      _partNameController.clear();
      _quantityController.clear(); // Clear quantity when product is cleared
      _searchResults.clear();
    });
  }

  Future<void> _submitForm() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final damageReportProvider = Provider.of<DamageReportProvider>(context, listen: false);
      
      final success = await damageReportProvider.addDamageReport(
        partName: _selectedProduct!.name,
        productId: _selectedProduct!.productId,
        reportType: _selectedReportType!,
        quantity: int.parse(_quantityController.text.trim()),
        dateReported: _selectedDate,
        reportedBy: _getCurrentUserName(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        imageFiles: _selectedImages,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Damage report submitted successfully!'),
                ],
              ),
              backgroundColor: Color(0xFF5CE65C),
              duration: Duration(seconds: 3),
            ),
          );

          Navigator.of(context).pop(true); // Return true to indicate success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Failed to submit report: ${damageReportProvider.error ?? 'Unknown error'}'),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to submit report: ${e.toString()}'),
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