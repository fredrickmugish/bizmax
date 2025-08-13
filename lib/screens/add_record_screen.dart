import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/business_record.dart';
import '../models/inventory_item.dart';
import '../providers/records_provider.dart';
import '../providers/inventory_provider.dart';
import '../services/api_exception.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../services/insufficient_stock_exception.dart';
import '../utils/app_utils.dart';
import '../utils/app_utils.dart'; // Import AppUtils
import 'package:rahisisha/providers/auth_provider.dart'; // Add this line

class CartItem {
  final InventoryItem product;
  final int quantity;
  final String priceType;
  final double price;
  final double? customPrice;
  CartItem({
    required this.product,
    required this.quantity,
    required this.priceType,
    required this.price,
    this.customPrice,
  });
}

class AddRecordScreen extends StatefulWidget {
  final String recordType;

  const AddRecordScreen({Key? key, required this.recordType}) : super(key: key);

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _customerController = TextEditingController();
  final _supplierController = TextEditingController();
  final _amountPaidController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isCreditSale = false;
  InventoryItem? _selectedProduct;
  bool _isLoading = false;
  double _totalAmount = 0.0;
  double _amountPaid = 0.0;
  double _debtAmount = 0.0;
  
  // New: Funding source for purchases
  String _fundingSource = 'personal'; // 'revenue' or 'personal'

  // Add local sales type for the currently selected product
  String _currentSelectedPriceType = 'retail'; // 'retail' or 'wholesale'

  // Add this field to the _AddRecordScreenState class:
  String? _productSearchQuery = '';

  List<CartItem> _cart = [];

  bool _isCartCreditSale = false;
  final TextEditingController _cartAmountPaidController = TextEditingController();
  double get _cartTotal => _cart.fold<double>(0, (sum, item) => sum + item.price * item.quantity);
  double get _cartAmountPaid => double.tryParse(_cartAmountPaidController.text) ?? 0.0;
  double get _cartDebt => (_cartTotal - _cartAmountPaid) > 0 ? (_cartTotal - _cartAmountPaid) : 0.0;

  double? _customSelectedPrice;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only load inventory if the record type involves products (sale or purchase)
      if (widget.recordType == 'sale' || widget.recordType == 'purchase') {
        final inventoryProvider = context.read<InventoryProvider>();
        if (inventoryProvider.items.isEmpty) {
          inventoryProvider.loadInventory();
        }
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _quantityController.dispose();
    _customerController.dispose();
    _supplierController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    print('AddRecordScreen: isLoading=[32m[0m, items=[32m[0m');
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: _getAppBarColor(),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            top: 16,
          ),
          child: Form(
            key: _formKey,
          child: Column(
            children: [
              // FOR EXPENSES ONLY - Description and Amount
              if (widget.recordType == 'expense') ...[
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Maelezo ya Matumizi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tafadhali ingiza maelezo ya matumizi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(
                    labelText: 'Kiasi cha Matumizi (TSH)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tafadhali ingiza kiasi cha matumizi';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Tafadhali ingiza namba halali';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // FOR SALES AND PURCHASES - Product selection
              if (widget.recordType == 'sale' || widget.recordType == 'purchase') ...[
                _buildProductSelectionField(),
                const SizedBox(height: 16),
                  
                  // 🔥 NEW: Sales Type Checkboxes (for sales only, after product selection)
                  if (widget.recordType == 'sale' && _selectedProduct != null && 
                      (_selectedProduct!.wholesalePrice != null || _selectedProduct!.retailPrice != null)) ...[
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            const Text(
                              'Aina ya Mauzo',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CheckboxListTile(
                              title: const Text(
                                'Mauzo ya Jumla',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Bei ya jumla: @TSH ${_getWholesalePrice().toStringAsFixed(0)}'),
                              value: _currentSelectedPriceType == 'wholesale',
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _currentSelectedPriceType = 'wholesale';
                                    _customSelectedPrice = null;
                                  }
                                  _updateCalculatedAmount();
                                });
                              },
                            ),
                            CheckboxListTile(
                              title: const Text(
                                'Mauzo ya Rejareja',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Bei ya rejareja: @TSH ${_getRetailPrice().toStringAsFixed(0)}'),
                              value: _currentSelectedPriceType == 'retail',
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _currentSelectedPriceType = 'retail';
                                    _customSelectedPrice = null;
                                  }
                                  _updateCalculatedAmount();
                                });
                              },
                            ),
                            ListTile(
                              title: Row(
                                children: [
                                  const Text(
                                    'Mauzo ya Punguzo',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 16, color: Colors.orange),
                                    tooltip: 'Weka Bei ya Punguzo',
                                    onPressed: () async {
                                      final newPrice = await showDialog<double>(
                                        context: context,
                                        builder: (context) {
                                          final controller = TextEditingController(
                                            text: _customSelectedPrice?.toStringAsFixed(0) ?? _getRetailPrice().toStringAsFixed(0)
                                          );
                                          return AlertDialog(
                                            title: const Text('Weka Bei ya Punguzo'),
                                            content: TextField(
                                              controller: controller,
                                              keyboardType: TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: 'Bei ya Punguzo (TSH)',
                                                hintText: 'Ingiza bei ya punguzo',
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Ghairi'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  final value = double.tryParse(controller.text);
                                                  if (value != null && value > 0) {
                                                    Navigator.pop(context, value);
                                                  }
                                                },
                                                child: const Text('Hifadhi'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      if (newPrice != null && newPrice > 0) {
                                        setState(() {
                                          _currentSelectedPriceType = 'discount';
                                          _customSelectedPrice = newPrice;
                                          _updateCalculatedAmount();
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              subtitle: Text(_customSelectedPrice != null 
                                ? 'Bei ya punguzo: @TSH ${_customSelectedPrice!.toStringAsFixed(0)}'
                                : 'Bofya edit icon kuweka bei ya punguzo'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ],
              
              // SALES SECTION - Customer and Credit Management
              if (widget.recordType == 'sale') ...[
                // Credit sale toggle
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        CheckboxListTile(
                          title: const Text(
                            'Mauzo ya Mkopo',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text('Chagua kama ni mauzo ya mkopo'),
                          value: _isCreditSale,
                          onChanged: (value) {
                            setState(() {
                              _isCreditSale = value ?? false;
                                _updateCreditSection();
                            });
                          },
                        ),
                        if (_isCreditSale)
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info, color: Colors.orange, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Jina la mteja ni lazima kwa mauzo ya mkopo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Customer name field
                TextFormField(
                  controller: _customerController,
                  decoration: InputDecoration(
                    labelText: _isCreditSale ? 'Jina la Mteja *' : 'Jina la Mteja (si lazima)',
                    hintText: _isCreditSale 
                        ? 'Ingiza jina la mteja'
                        : 'Ingiza jina la mteja (si lazima kwa fedha taslimu)',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.person,
                      color: _isCreditSale ? Colors.red : Colors.grey,
                    ),
                    labelStyle: TextStyle(
                      color: _isCreditSale ? Colors.red : null,
                    ),
                  ),
                  validator: (value) {
                    if (_isCreditSale && (value == null || value.trim().isEmpty)) {
                        return 'Jina la mteja ni lazima kwa mauzo ya mkopo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                  // 🔥 RESTORED: Credit sale payment details
                  if (_isCreditSale && _cart.length == 1) ...[
                  Card(
                    color: Colors.orange.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.credit_card, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'Usimamizi wa Mkopo',
                                  style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _amountPaidController,
                            decoration: const InputDecoration(
                                labelText: 'Kiasi kilicholipwa sasa (TSH)',
                              border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.payments),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => _calculateDebt(),
                            validator: (value) {
                                if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                                  return 'Ingiza kiasi halali';
                                }
                                if (value != null && value.isNotEmpty && double.tryParse(value)! < 0) {
                                  return 'Kiasi lazima kiwe kikubwa au sawa na sifuri';
                                }
                                if (value != null && value.isNotEmpty && double.tryParse(value)! > _totalAmount) {
                                  return 'Kiasi kilicholipwa hakiwezi kuzidi jumla ya mkopo';
                              }
                              return null;
                            },
                          ),
                            const SizedBox(height: 8),
                            Text('Jumla ya mkopo: TSh ${_totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Deni linalobaki: TSh ${_debtAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                                    ),
                      ),
                                ),
                  ] else if (_isCreditSale && _cart.length > 1) ...[
                    Card(
                      color: Colors.orange.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                                  children: [
                            Icon(Icons.info, color: Colors.orange.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Kwa bidhaa nyingi, tafadhali weka malipo ya mkopo kupitia sehemu ya madeni baada ya mauzo.',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                    ),
                                      ),
                                    ),
                                  ],
                                ),
                    ),
                  ),
                ],
              ],

              // FOR PURCHASES - Supplier name
              if (widget.recordType == 'purchase') ...[
                TextFormField(
                  controller: _supplierController,
                  decoration: const InputDecoration(
                    labelText: 'Jina la Msambazaji (si lazima)',
                      hintText: 'Ingiza jina la msambazaji',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Manunuzi ya Mkopo', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Chagua kama unanunua kwa mkopo'),
                  value: _isCreditSale,
                  onChanged: (value) {
                    setState(() {
                      _isCreditSale = value ?? false;
                      if (!_isCreditSale) {
                        _amountPaidController.text = _totalAmount.toStringAsFixed(0);
                        _debtAmount = 0.0;
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (_isCreditSale) ...[
                  TextFormField(
                    controller: _amountPaidController,
                    decoration: const InputDecoration(
                      labelText: 'Kiasi Ulicholipa (TSH)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payments),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _calculateDebt(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingiza kiasi ulicholipa';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Ingiza kiasi halali';
                      }
                      if (value != null && value.isNotEmpty && double.tryParse(value)! < 0) {
                        return 'Kiasi lazima kiwe kikubwa au sawa na sifuri';
                      }
                      if (value != null && value.isNotEmpty && double.tryParse(value)! > _totalAmount) {
                        return 'Kiasi kilicholipwa hakiwezi kuzidi jumla ya mkopo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Text('Jumla ya mkopo: TSh ${_totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Deni linalobaki: TSh ${_debtAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ],
                const SizedBox(height: 16),
                
                // Funding source selection
                if (_selectedProduct != null) ...[ // Add this condition
                  Card(
                    //
                    child: Padding(
                        padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                            const Text(
                              'Chanzo cha Fedha',
                              style: TextStyle(
                              fontWeight: FontWeight.bold,
                                fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            title: const Text(
                              'Mauzo ya Biashara',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text('Kutoka mauzo ya biashara'),
                            value: _fundingSource == 'revenue',
                            onChanged: (value) {
                              setState(() {
                                _fundingSource = 'revenue';
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text(
                              'Fedha ya binafsi',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: const Text('Kutoka fedha yangu binafsi'),
                            value: _fundingSource == 'personal',
                            onChanged: (value) {
                              setState(() {
                                _fundingSource = 'personal';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],

              // Date selection
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Tarehe'),
                  subtitle: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.arrow_drop_down),
                  onTap: _selectDate,
                ),
                const SizedBox(height: 16),

              // Save button
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getAppBarColor(),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          '${_getTitle()}',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductSelectionField() {
    return Consumer<InventoryProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const SizedBox(
                  height: 48, // Icon size + padding
                  width: 48,
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Inapakia bidhaa...', // Loading products...
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (provider.items.isEmpty) {
          return Container(
              padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
              child: Column(
                children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Colors.orange.shade600,
                ),
                  const SizedBox(height: 8),
                  Text(
                    'Ongeza bidhaa kwanza kabla ya kurekodi ${widget.recordType == 'sale' ? 'mauzo' : 'manunuzi'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  TextFormField(
          decoration: const InputDecoration(
                      labelText: 'Tafuta Bidhaa',
            border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
                        _productSearchQuery = value;
                      });
                    },
                    enabled: _selectedProduct == null,
                  ),
                  const SizedBox(height: 8),
                  if (_selectedProduct == null)
                    SizedBox(
                      height: 120,
                      child: ListView(
                        children: provider.items
                            .where((product) => _productSearchQuery == null || _productSearchQuery!.isEmpty || product.name.toLowerCase().contains(_productSearchQuery!.toLowerCase()))
                            .map((product) => ListTile(
                                  leading: (product.productImage != null && product.productImage!.isNotEmpty)
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: CachedNetworkImage(
                                            imageUrl: product.productImage!,
                                            width: 32,
                                            height: 32,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => const CircularProgressIndicator(),
                                            errorWidget: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 24),
                                          ),
                                        )
                                      : Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Icon(Icons.inventory_2, size: 20, color: Colors.white),
                                        ),
                                  title: Text(product.name, overflow: TextOverflow.ellipsis),
                                  subtitle: Text(widget.recordType == 'sale'
                                      ? (product.wholesalePrice != null && product.retailPrice != null
                                          ? 'Jumla: @TSH ${product.wholesalePrice!.toStringAsFixed(0)}, Reja: @TSH ${product.retailPrice!.toStringAsFixed(0)} - Zilizopo: ${product.currentStock}'
                                          : 'Bei: @TSH ${product.sellingPrice.toStringAsFixed(0)} - Zilizopo: ${product.currentStock}')
                                      : 'Bei: @TSH ${product.buyingPrice.toStringAsFixed(0)} - Zilizopo: ${product.currentStock}'),
                                  onTap: () {
                                    setState(() {
                                      _selectedProduct = product;
              _quantityController.text = '1';
                                      _productSearchQuery = '';
            });
          },
                                  selected: _selectedProduct?.id == product.id,
                                ))
                            .toList(),
                      ),
                    )
                  else
                    Row(
                      children: [
                        (_selectedProduct!.productImage != null && _selectedProduct!.productImage!.isNotEmpty)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  imageUrl: _selectedProduct!.productImage!,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const CircularProgressIndicator(),
                                  errorWidget: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 24),
                                ),
                              )
                            : Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.inventory_2, size: 20, color: Colors.white),
                              ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedProduct!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Idadi',
                              isDense: true,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart, color: Colors.green),
                          tooltip: 'Ongeza kwenye Orodha',
                          onPressed: () {
                            final qty = int.tryParse(_quantityController.text) ?? 1;
                            if (_selectedProduct != null && qty > 0) {
                              setState(() {
                                _cart.add(CartItem(
                                  product: _selectedProduct!,
                                  quantity: qty,
                                  priceType: widget.recordType == 'sale' ? _currentSelectedPriceType : 'buying',
                                  price: widget.recordType == 'sale'
                                      ? (_currentSelectedPriceType == 'wholesale' ? _getWholesalePrice() : _getRetailPrice())
                                      : _selectedProduct!.buyingPrice,
                                  customPrice: _customSelectedPrice,
                                ));
                                _selectedProduct = null;
                                _quantityController.clear();
                                _currentSelectedPriceType = 'retail';
                                _customSelectedPrice = null;
                                _updateCreditSection();
                              });
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() {
                              _selectedProduct = null;
                              _quantityController.clear();
                              _updateCreditSection();
                            });
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_cart.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade100),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.blue.shade50,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bidhaa Zilizochaguliwa:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    ..._cart.map((item) => ListTile(
                          leading: (item.product.productImage != null && item.product.productImage!.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: CachedNetworkImage(
                                    imageUrl: item.product.productImage!,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const CircularProgressIndicator(),
                                    errorWidget: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 24),
                                  ),
                                )
                              : Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.inventory_2, size: 20, color: Colors.white),
                                ),
                          title: Text(item.product.name, overflow: TextOverflow.ellipsis),
                          subtitle: Text('Idadi: ${item.quantity} | Bei: @TSH ${(item.customPrice ?? item.price).toStringAsFixed(0)}${item.customPrice != null ? ' (Punguzo)' : ''} | Jumla: TSh ${((item.customPrice ?? item.price) * item.quantity).toStringAsFixed(0)}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _cart.remove(item);
                                _updateCreditSection();
                              });
          },
                          ),
                        )),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text('Jumla ya Malipo:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text(
                          _cart.fold<double>(0, (sum, item) => sum + (item.customPrice ?? item.price) * item.quantity).toStringAsFixed(0),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: InputDecoration(
        labelText: 'Idadi *',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.numbers),
        suffixText: _selectedProduct != null ? 'Max: ${_selectedProduct!.currentStock}' : null,
        helperText: _selectedProduct != null && widget.recordType == 'sale' 
            ? 'Idadi iliyopo: ${_selectedProduct!.currentStock}' 
            : null,
      ),
      keyboardType: TextInputType.number,
      onChanged: (value) => _calculateTotalAmount(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingiza idadi';
        }
        final quantity = int.tryParse(value);
        if (quantity == null || quantity <= 0) {
          return 'Ingiza idadi sahihi';
        }
        // Check stock availability for sales
        if (widget.recordType == 'sale' && _selectedProduct != null) {
          if (quantity > _selectedProduct!.currentStock) {
            return 'Idadi haitoshi! Ipo: ${_selectedProduct!.currentStock}';
          }
          if (_selectedProduct!.currentStock <= 0) {
            return 'Bidhaa hii haina hifadhi!';
          }
        }
        return null;
      },
    );
  }

  Widget _buildCalculatedAmountField() {
    return TextFormField(
      controller: _amountController,
      decoration: const InputDecoration(
        labelText: 'Jumla ya Kiasi (TSH)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.calculate),
        filled: true,
        fillColor: Colors.lightBlue,
      ),
      readOnly: true,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: Colors.white,
      ),
    );
  }

  void _calculateTotalAmount() {
    if (_selectedProduct != null && _quantityController.text.isNotEmpty) {
      final quantity = int.tryParse(_quantityController.text) ?? 0;
      double price;
      
      if (widget.recordType == 'sale') {
        // 🔥 NEW: Use wholesale/retail pricing for sales
        if (_currentSelectedPriceType == 'wholesale') {
          price = _getWholesalePrice();
        } else {
          price = _getRetailPrice();
        }
      } else {
        // For purchases, use buying price
        price = _selectedProduct!.buyingPrice;
      }
      
      setState(() {
        _totalAmount = quantity * price;
        _amountController.text = _totalAmount.toStringAsFixed(0);
        
        // For non-credit sales, paid amount equals total amount
        if (!_isCreditSale) {
          _amountPaidController.text = _totalAmount.toStringAsFixed(0);
        }
        
        _calculateDebt();
      });
    }
  }

  void _calculateDebt() {
    if (_isCreditSale && _cart.length == 1) {
      _updateCreditSection();
      return;
    }
    setState(() {
      _amountPaid = double.tryParse(_amountPaidController.text) ?? 0;
      _debtAmount = _totalAmount - _amountPaid;
      if (_debtAmount < 0) _debtAmount = 0;
    });
  }

  String _getTitle() {
    switch (widget.recordType) {
      case 'sale':
        return 'Ongeza Mauzo';
      case 'purchase':
        return 'Ongeza Ununuzi';
      case 'expense':
        return 'Ongeza Matumizi';
      default:
        return 'Ongeza Rekodi';
    }
  }

  String _getSuccessMessageTitle() {
    switch (widget.recordType) {
      case 'sale':
        return 'Mauzo';
      case 'purchase':
        return 'Manunuzi';
      case 'expense':
        return 'Matumizi';
      default:
        return 'Rekodi';
    }
  }

  Color _getAppBarColor() {
    switch (widget.recordType) {
      case 'sale':
        return Colors.blue;
      case 'purchase':
        return Colors.blue;
      case 'expense':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    if ((widget.recordType == 'sale' || widget.recordType == 'purchase') && _cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tafadhali ongeza bidhaa angalau moja kwenye orodha.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool overallSuccess = true; // Track overall success for all record types

    try {
      if (widget.recordType == 'expense') {
        // Expense: single record
        final record = BusinessRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: widget.recordType,
          description: _descriptionController.text.trim(),
          amount: double.parse(_amountController.text),
          date: _selectedDate,
          customerName: null,
          supplierName: null,
          inventoryItemId: null,
          quantity: null,
          costOfGoodsSold: null,
          fundingSource: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isCreditSale: false,
          unitPrice: 0.0,
          totalAmount: null,
          amountPaid: null,
          debtAmount: null,
          user: context.read<AuthProvider>().user, // Add this line
        );
        overallSuccess = await context.read<RecordsProvider>().addRecord(record);
      } else {
        // Sale or purchase: submit each cart item as a record
        final totalAmount = _cart.fold<double>(0, (sum, item) => sum + item.price * item.quantity);
        final amountPaid = _isCreditSale ? double.tryParse(_amountPaidController.text) ?? 0.0 : null;
        
        // Generate a unique transaction ID for this cart if it's a sale
        final String? transactionId = widget.recordType == 'sale' && _cart.isNotEmpty
            ? DateTime.now().millisecondsSinceEpoch.toString() + '-' + UniqueKey().hashCode.toString()
            : null;

        List<BusinessRecord> recordsToSave = [];

        for (int i = 0; i < _cart.length; i++) {
          final item = _cart[i];
          final effectivePrice = item.customPrice ?? item.price;
          final itemTotal = effectivePrice * item.quantity;
          double itemAmountPaid = itemTotal;
          double itemDebt = 0.0;
          if (_isCreditSale) {
            if ((amountPaid ?? 0.0) <= 0.0) {
              // No payment made, full debt for each product
              itemAmountPaid = 0.0;
              itemDebt = itemTotal;
            } else {
              // Distribute amount paid proportionally (default logic)
              itemAmountPaid = (amountPaid ?? 0.0) * (itemTotal / (totalAmount > 0 ? totalAmount : 1));
              itemDebt = itemTotal - itemAmountPaid;
            }
          }
          recordsToSave.add(BusinessRecord(
            id: Uuid().v4(),
            type: widget.recordType,
            description: item.product.name,
            amount: itemAmountPaid,
            date: _selectedDate,
            customerName: _customerController.text.trim().isNotEmpty
                ? _customerController.text.trim()
                : null,
            supplierName: widget.recordType == 'purchase' && _supplierController.text.trim().isNotEmpty
                ? _supplierController.text.trim()
                : null,
            inventoryItemId: item.product.id,
            quantity: item.quantity,
            costOfGoodsSold: widget.recordType == 'sale' ? item.product.buyingPrice * item.quantity : null,
            fundingSource: widget.recordType == 'purchase' ? _fundingSource : null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isCreditSale: _isCreditSale,
            unitPrice: effectivePrice,
            totalAmount: itemTotal,
            amountPaid: _isCreditSale ? itemAmountPaid : itemTotal,
            debtAmount: _isCreditSale ? itemDebt : 0.0,
            saleType: widget.recordType == 'sale' ? item.priceType : null,
            transactionId: transactionId, // Pass the generated transaction ID
          ));
        }

        // Now send all records to the provider
        for (final record in recordsToSave) {
          final recordAddedSuccessfully = await context.read<RecordsProvider>().addRecord(record);
          if (!recordAddedSuccessfully) {
            overallSuccess = false; // Mark overall as false if any record fails
            // The error message for insufficient stock is already handled by RecordsProvider
            // No need to log here unless for specific debugging
            break; // Stop processing further records if one fails
          }
        }
      }

    } on InsufficientStockException catch (e) {
      AppUtils.showErrorSnackBar(e.message);
      overallSuccess = false;
    } on ApiException catch (e) {
      AppUtils.showErrorSnackBar('API Error: ${e.message}');
      overallSuccess = false;
    } catch (e) {
      String errorMessage = 'Hitilafu isiyotarajiwa: ${e.toString()}';
      AppUtils.showErrorSnackBar(errorMessage);
      overallSuccess = false;
    } finally {
      if (overallSuccess) {
        // If all records were saved successfully, navigate back and show success message
        Navigator.pop(context);
        String successMessage = '${_getSuccessMessageTitle()} yamehifadhiwa!';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Refresh inventory to show updated stock levels
      if (widget.recordType == 'sale' || widget.recordType == 'purchase') {
        await context.read<InventoryProvider>().loadInventory();
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  // Build funding source toggle widget
  Widget _buildFundingSourceToggle({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 NEW: Get wholesale price
  double _getWholesalePrice() {
    if (_selectedProduct == null) return 0.0;
    return _selectedProduct!.effectiveWholesalePrice;
  }

  // 🔥 NEW: Get retail price
  double _getRetailPrice() {
    if (_selectedProduct == null) return 0.0;
    return _selectedProduct!.effectiveRetailPrice;
  }

  // 🔥 NEW: Update calculated amount based on sales type
  void _updateCalculatedAmount() {
    if (_selectedProduct == null) return;
    
    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final unitPrice = _currentSelectedPriceType == 'wholesale' ? _getWholesalePrice() : _getRetailPrice();
    _totalAmount = quantity * unitPrice;
    
    _amountController.text = _totalAmount.toStringAsFixed(0);
    _calculateDebt();
  }

  // Update the credit sale calculation to use effective prices
  void _updateCreditSection() {
    if (_isCreditSale && _cart.length == 1) {
      final item = _cart.first;
      final effectivePrice = item.customPrice ?? item.price;
      _totalAmount = effectivePrice * item.quantity;
      _amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
      _debtAmount = _totalAmount - _amountPaid;
      if (_debtAmount < 0) _debtAmount = 0;
      _amountController.text = _totalAmount.toStringAsFixed(0);
    } else {
      _totalAmount = _cart.fold<double>(0, (sum, item) => sum + (item.customPrice ?? item.price) * item.quantity);
      _amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
      _debtAmount = _totalAmount - _amountPaid;
      if (_debtAmount < 0) _debtAmount = 0;
      _amountController.text = _totalAmount.toStringAsFixed(0);
    }
    setState(() {});
  }

  double _getSelectedPrice() {
    if (_selectedProduct == null) return 0.0;
    switch (_currentSelectedPriceType) {
      case 'wholesale':
        return _getWholesalePrice();
      case 'retail':
        return _getRetailPrice();
      case 'discount':
        return _customSelectedPrice ?? _getRetailPrice();
      default:
        return _getRetailPrice();
    }
  }

  Color _getPriceTypeColor() {
    switch (_currentSelectedPriceType) {
      case 'wholesale':
        return Colors.green;
      case 'retail':
        return Colors.blue;
      case 'discount':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriceTypeIcon() {
    switch (_currentSelectedPriceType) {
      case 'wholesale':
        return Icons.check_circle;
      case 'retail':
        return Icons.shopping_cart;
      case 'discount':
        return Icons.local_offer;
      default:
        return Icons.attach_money;
    }
  }

  String _getPriceTypeDisplayText() {
    switch (_currentSelectedPriceType) {
      case 'wholesale':
        return 'Bei ya jumla itatumika: TSh ${_getWholesalePrice().toStringAsFixed(0)}';
      case 'retail':
        return 'Bei ya rejareja itatumika: TSh ${_getRetailPrice().toStringAsFixed(0)}';
      case 'discount':
        return _customSelectedPrice != null 
          ? 'Bei ya punguzo itatumika: TSh ${_customSelectedPrice!.toStringAsFixed(0)}'
          : 'Weka bei ya punguzo kwa kubofya edit icon';
      default:
        return 'Chagua aina ya mauzo';
    }
  }
}