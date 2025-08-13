import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'add_product_screen_stub.dart'
  if (dart.library.html) 'add_product_screen_web.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import connectivity_plus
import 'package:rahisisha/services/api_exception.dart'; // Import ApiException

class AddProductScreen extends StatefulWidget {
  final InventoryItem? product; // For editing

  const AddProductScreen({Key? key, this.product}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController(); // Custom category input
  final _buyingPriceController = TextEditingController();
  final _wholesalePriceController = TextEditingController(); // Wholesale price
  final _retailPriceController = TextEditingController(); // Retail price
  final _sellingPriceController = TextEditingController();
  final _currentStockController = TextEditingController();
  final _minimumStockController = TextEditingController();
  final _unitDimensionsController = TextEditingController(); // Unit dimensions
  final _unitQuantityController = TextEditingController(); // Unit quantity
  File? _selectedImage;
  Uint8List? _webImageBytes;
  String? _webImageName;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _populateFields();
      if (widget.product!.productImage != null && widget.product!.productImage!.isNotEmpty) {
        // No local file, but we can show the network image as preview
      }
    }
  }

  void _populateFields() {
    final product = widget.product!;
    _nameController.text = product.name;
    _categoryController.text = product.category ?? '';
    _buyingPriceController.text = product.buyingPrice.toString();
    _wholesalePriceController.text = product.wholesalePrice?.toString() ?? '';
    _retailPriceController.text = product.retailPrice?.toString() ?? '';
    _sellingPriceController.text = product.sellingPrice.toString();
    _currentStockController.text = product.currentStock.toString();
    _minimumStockController.text = product.minimumStock.toString();
    _unitDimensionsController.text = product.unitDimensions ?? '';
    _unitQuantityController.text = product.unitQuantity.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _buyingPriceController.dispose();
    _wholesalePriceController.dispose();
    _retailPriceController.dispose();
    _sellingPriceController.dispose();
    _currentStockController.dispose();
    _minimumStockController.dispose();
    _unitDimensionsController.dispose();
    _unitQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing() ? 'Hariri Bidhaa' : 'Ongeza Bidhaa'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProduct,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Hifadhi',
                    style: TextStyle(color: Colors.white),
                  ),
          ),
        ],
        automaticallyImplyLeading: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildImagePicker(),
            _buildNameField(),
            const SizedBox(height: 16),
            _buildCategoryField(),
            const SizedBox(height: 16),
            _buildUnitSection(),
            const SizedBox(height: 24),
            Text(
              'Bei',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildBuyingPriceField(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildWholesalePriceField()),
                const SizedBox(width: 16),
                Expanded(child: _buildRetailPriceField()),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Hifadhi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildCurrentStockField()),
                const SizedBox(width: 16),
                Expanded(child: _buildMinimumStockField()),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(16),
              ),
              child: Text(
                _isEditing() ? 'Sasisha Bidhaa' : 'Ongeza Bidhaa',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  bool _isEditing() => widget.product != null;

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Picha ya Bidhaa (si lazima)', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 300;
            final imageWidget =
              (kIsWeb && _webImageBytes != null)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _webImageBytes!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  )
                : (_selectedImage != null)
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        _selectedImage!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    )
                  : (widget.product?.productImage != null && widget.product!.productImage!.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: widget.product!.productImage!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                      );
            final buttonWidget = kIsWeb
              ? ElevatedButton.icon(
                  onPressed: () {
                    pickWebImageStub((bytes, name) {
                      setState(() {
                        _webImageBytes = bytes;
                        _webImageName = name;
                      });
                    });
                  },
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Ongeza Picha'),
                )
              : ElevatedButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Ongeza Picha'),
                );
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  imageWidget,
                  const SizedBox(height: 12),
                  buttonWidget,
                ],
              );
            } else {
              return Row(
                children: [
                  imageWidget,
                  const SizedBox(width: 16),
                  buttonWidget,
                ],
              );
            }
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Piga Picha'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chagua kutoka Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _pickWebImage() {
    // No-op on non-web platforms
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Jina la Bidhaa',
        hintText: 'Mfano: Samsung',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.shopping_bag),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Tafadhali ingiza jina la bidhaa';
        }
        return null;
      },
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
    );
  }

  Widget _buildCategoryField() {
    return TextFormField(
      controller: _categoryController,
      decoration: const InputDecoration(
        labelText: 'Aina ya Bidhaa (si lazima)',
        hintText: 'Mfano: Simu',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      validator: (value) {
        // Optional, so no required check
        if (value != null && value.length > 100) {
          return 'Aina ya bidhaa isizidie herufi 100';
        }
        return null;
      },
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
    );
  }

  Widget _buildUnitSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kipimo cha Bidhaa',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildUnitDimensionsField(),
            ),
            // Removed Idadi (unit quantity) field
          ],
        ),
      ],
    );
  }

  Widget _buildUnitDimensionsField() {
    return TextFormField(
      controller: _unitDimensionsController,
      decoration: const InputDecoration(
        labelText: 'Kipimo (si lazima)',
        hintText: 'Mfano: Kg, Lita, Kipande',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.straighten),
      ),
      // Optional, so no required check
    );
  }

  Widget _buildBuyingPriceField() {
    return TextFormField(
      controller: _buyingPriceController,
      decoration: const InputDecoration(
        labelText: 'Bei ya Ununuzi *',
        hintText: '0',
        border: OutlineInputBorder(),
        prefixText: 'TSh ',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingiza bei ya ununuzi';
        }
        final price = double.tryParse(value);
        if (price == null || price < 0) {
          return 'Ingiza bei sahihi';
        }
        return null;
      },
    );
  }

  Widget _buildWholesalePriceField() {
    return TextFormField(
      controller: _wholesalePriceController,
      decoration: const InputDecoration(
        labelText: 'Bei ya Jumla',
        hintText: '0',
        border: OutlineInputBorder(),
        prefixText: 'TSh ',
        helperText: 'Bei ya mauzo ya jumla',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final price = double.tryParse(value);
          if (price == null || price < 0) {
            return 'Ingiza bei sahihi';
          }
          final buyingPrice = double.tryParse(_buyingPriceController.text) ?? 0;
          if (price <= buyingPrice) {
            return 'Bei ya jumla iwe zaidi ya bei ya ununuzi';
          }
        }
        return null;
      },
    );
  }

  Widget _buildRetailPriceField() {
    return TextFormField(
      controller: _retailPriceController,
      decoration: const InputDecoration(
        labelText: 'Bei ya Rejareja',
        hintText: '0',
        border: OutlineInputBorder(),
        prefixText: 'TSh ',
        helperText: 'Bei ya mauzo ya rejareja',
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value != null && value.isNotEmpty) {
          final price = double.tryParse(value);
          if (price == null || price < 0) {
            return 'Ingiza bei sahihi';
          }
          final buyingPrice = double.tryParse(_buyingPriceController.text) ?? 0;
          if (price <= buyingPrice) {
            return 'Bei ya rejareja iwe zaidi ya bei ya ununuzi';
          }
        }
        return null;
      },
    );
  }

  Widget _buildCurrentStockField() {
    return TextFormField(
      controller: _currentStockController,
      decoration: const InputDecoration(
        labelText: 'Idadi ya sasa *',
        hintText: '0',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingiza kiasi cha hifadhi';
        }
        final stock = int.tryParse(value);
        if (stock == null || stock < 0) {
          return 'Ingiza kiasi sahihi';
        }
        return null;
      },
    );
  }

  Widget _buildMinimumStockField() {
    return TextFormField(
      controller: _minimumStockController,
      decoration: const InputDecoration(
        labelText: 'Idadi ya chini *',
        hintText: '0',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Ingiza kiasi cha chini';
        }
        final stock = int.tryParse(value);
        if (stock == null || stock < 0) {
          return 'Ingiza kiasi sahihi';
        }
        return null;
      },
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Require at least one price
    if (_wholesalePriceController.text.isEmpty && _retailPriceController.text.isEmpty) {
      _showErrorMessage('Weka angalau Bei ya Jumla au Bei ya Rejareja.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        _showErrorMessage(_isEditing()
            ? 'Ingia online ili kuhariri bidhaa'
            : 'Ingia online ili kuongeza bidhaa');
        return;
      }

      // Get prices
      final buyingPrice = double.parse(_buyingPriceController.text);
      final wholesalePrice = _wholesalePriceController.text.isNotEmpty
          ? double.parse(_wholesalePriceController.text)
          : null;
      final retailPrice = _retailPriceController.text.isNotEmpty
          ? double.parse(_retailPriceController.text)
          : null;

      // Use retail price as default selling price if available, otherwise wholesale
      final sellingPrice = retailPrice ?? wholesalePrice ?? buyingPrice * 1.2;

      // Prepare multipart request for image upload
      final isEditing = _isEditing();
      final url = isEditing
          ? Uri.parse('https://fortex.co.tz/api/inventory/${widget.product!.id}')
          : Uri.parse('https://fortex.co.tz/api/inventory');
      final request = http.MultipartRequest('POST', url);
      // Add fields
      request.fields['name'] = _nameController.text.trim();
      request.fields['category'] = _categoryController.text.trim();
      request.fields['unit'] = 'bidhaa';
      request.fields['buying_price'] = buyingPrice.toString();
      if (wholesalePrice != null) request.fields['wholesale_price'] = wholesalePrice.toString();
      if (retailPrice != null) request.fields['retail_price'] = retailPrice.toString();
      request.fields['selling_price'] = sellingPrice.toString();
      request.fields['unit_dimensions'] = _unitDimensionsController.text.trim();
      request.fields['unit_quantity'] = (_unitQuantityController.text.isNotEmpty ? _unitQuantityController.text : '1.0');
      request.fields['current_stock'] = _currentStockController.text;
      request.fields['minimum_stock'] = _minimumStockController.text;
      request.fields['description'] = _nameController.text.trim();
      // Add image if selected
      if (_selectedImage != null) {
        // ignore: avoid_print
        print('Attaching mobile/desktop image:  [32m${_selectedImage!.path} [0m');
        request.files.add(await http.MultipartFile.fromPath('product_image', _selectedImage!.path));
      }
      // Web: add image from bytes
      if (kIsWeb && _webImageBytes != null && _webImageName != null) {
        // ignore: avoid_print
        print('Attaching web image:  [32m${_webImageName!} (${_webImageBytes!.length} bytes) [0m');
        request.files.add(
          http.MultipartFile.fromBytes(
            'product_image',
            _webImageBytes!,
            filename: _webImageName!,
          ),
        );
      }
      // ignore: avoid_print
      print('Request fields:  [36m');
      request.fields.forEach((k, v) => print('  $k: $v'));
      print('\u001b[0mRequest files:  [36m${request.files.map((f) => f.filename).toList()} [0m');
      if (isEditing) {
        request.fields['_method'] = 'PUT';
      }
      // Add authentication header
      final token = ApiService().accessToken;
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      final response = await request.send();
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessMessage(isEditing ? 'Bidhaa imesasishwa kikamilifu' : 'Bidhaa imeongezwa kikamilifu');
        // Reload inventory to show the new image
        if (mounted) {
          Provider.of<InventoryProvider>(context, listen: false).loadInventory();
        }
        Navigator.pop(context);
      } else {
        _showErrorMessage('Hitilafu: ${response.statusCode}');
      }
    } on ApiException catch (e) {
      _showErrorMessage('Hitilafu: ${e.message}');
    } catch (e) {
      _showErrorMessage('Hitilafu:  ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}