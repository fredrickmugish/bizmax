import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';

class CustomersProvider with ChangeNotifier {
  final CustomerRepository _customerRepository;
  List<Customer> _customers = [];
  bool _isLoading = false;

  CustomersProvider(this._customerRepository);

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();
    _customers = await _customerRepository.getCustomers();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCustomer(String name, String phone) async {
    final newCustomer = Customer(id: Uuid().v4(), name: name, phone: phone, isDirty: true);
    await _customerRepository.addCustomer(newCustomer);
    _customers.removeWhere((c) => c.name == name && c.id == '0');
    await loadCustomers();
  }

  Future<void> updateCustomer(String id, String name, String phone) async {
    final updatedCustomer = Customer(id: id, name: name, phone: phone, isDirty: true);
    // This will be handled by the repository and sync service
    // For now, we just update the local list
    final index = _customers.indexWhere((c) => c.id == id);
    if (index != -1) {
      _customers[index] = updatedCustomer;
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(String id) async {
    await _customerRepository.deleteCustomer(id);
    await loadCustomers();
  }
} 