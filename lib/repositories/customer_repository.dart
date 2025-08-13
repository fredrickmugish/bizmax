import 'package:rahisisha/models/customer.dart';
import 'package:rahisisha/services/api_service.dart';
import 'package:rahisisha/services/database_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class CustomerRepository {
  final ApiService _apiService;
  final DatabaseService? _databaseService;
  final Connectivity _connectivity;

  CustomerRepository(this._apiService, this._databaseService, this._connectivity);

  Future<List<Customer>> getCustomers() async {
    if (_databaseService == null) {
      // Web implementation: always fetch from API
      final apiCustomers = await _apiService.get('customers');
      return (apiCustomers['data'] as List).map((e) => Customer.fromJson(e)).toList();
    }

    List<Customer> localCustomers = await _databaseService!.getAllCustomers();
    final connectivityResult = await _connectivity.checkConnectivity();

    if (connectivityResult != ConnectivityResult.none) {
      // Online: Try to fetch from API
      try {
        final apiCustomers = await _apiService.get('customers');
        final customersFromApi = (apiCustomers['data'] as List).map((e) => Customer.fromJson(e)).toList();

        // Get dirty customers from local DB
        final dirtyLocalCustomers = await _databaseService!.getDirtyCustomers();
        final dirtyLocalCustomerIds = dirtyLocalCustomers.map((c) => c.id).toSet();

        // Create a map for quick lookup of API customers
        final apiCustomersMap = {for (var customer in customersFromApi) customer.id: customer};

        // Merge customers: API customers + local dirty customers
        List<Customer> mergedCustomers = [];
        Set<String?> mergedCustomerIds = {};

        // Add API customers first
        for (var customer in customersFromApi) {
          mergedCustomers.add(customer.copyWith(isDirty: false, isDeleted: false)); // Ensure API customers are clean
          mergedCustomerIds.add(customer.id);
        }

        // Add local dirty customers, prioritizing them if they conflict with API customers
        for (var customer in dirtyLocalCustomers) {
          if (!mergedCustomerIds.contains(customer.id)) {
            // Only add if not already present from API (meaning it's a new local customer or a local update)
            mergedCustomers.add(customer);
            mergedCustomerIds.add(customer.id);
          } else {
            // If it's a dirty customer that also exists in API, it means it's an update
            // We should keep the local dirty version until it's synced
            final index = mergedCustomers.indexWhere((c) => c.id == customer.id);
            if (index != -1) {
              mergedCustomers[index] = customer;
            }
          }
        }

        // Identify customers to be hard deleted from local DB (those not in API and not dirty)
        final customersToDeleteLocally = localCustomers.where((localCustomer) =>
            !mergedCustomerIds.contains(localCustomer.id) && !localCustomer.isDirty && localCustomer.isDeleted != true
        ).toList();

        // Perform hard deletes for customers no longer present on the server and not dirty locally
        for (final customer in customersToDeleteLocally) {
          await _databaseService!.hardDeleteCustomer(customer.id!);
        }

        // Update local database with merged customers (upsert)
        for (final customer in mergedCustomers) {
          await _databaseService!.upsertCustomer(customer);
        }

        if (kDebugMode) {
          print('CustomerRepository: Fetched ${customersFromApi.length} customers from API and merged with ${dirtyLocalCustomers.length} dirty local customers. Total merged: ${mergedCustomers.length}');
        }
        return mergedCustomers;
      } catch (e) {
        if (kDebugMode) {
          print('CustomerRepository: Failed to fetch customers from API ($e). Returning local customers.');
        }
        // Fallback to local customers if API fetch fails
        return localCustomers;
      }
    } else {
      // Offline: Return local customers directly
      if (kDebugMode) {
        print('CustomerRepository: Offline. Returning ${localCustomers.length} customers from local storage.');
      }
      return localCustomers;
    }
  }

  Future<void> addCustomer(Customer customer) async {
    if (_databaseService == null) {
      // Web implementation: always use API
      await _apiService.post('/customers', customer.toJson());
      return;
    }
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        final apiResponse = await _apiService.post('/customers', customer.toJson());
        final newCustomer = Customer.fromJson(apiResponse['data']);
        await _databaseService!.upsertCustomer(newCustomer.copyWith(isDirty: false));
      } else {
        await _databaseService!.upsertCustomer(customer.copyWith(isDirty: true));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to add customer to API, saving locally as dirty: $e');
      }
      await _databaseService!.upsertCustomer(customer.copyWith(isDirty: true));
    }
  }

  Future<void> deleteCustomer(String id) async {
    if (_databaseService == null) {
      // Web implementation: always use API
      await _apiService.delete('/customers/$id');
      return;
    }
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        await _apiService.delete('/customers/$id');
        await _databaseService!.hardDeleteCustomer(id);
      } else {
        final customerToDelete = await _databaseService!.getAllCustomers().then((customers) => customers.firstWhere((c) => c.id == id));
        await _databaseService!.upsertCustomer(customerToDelete.copyWith(isDirty: true, isDeleted: true));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete customer from API, marking locally as dirty and deleted: $e');
      }
      final customerToDelete = await _databaseService!.getAllCustomers().then((customers) => customers.firstWhere((c) => c.id == id));
      await _databaseService!.upsertCustomer(customerToDelete.copyWith(isDirty: true, isDeleted: true));
    }
  }
}