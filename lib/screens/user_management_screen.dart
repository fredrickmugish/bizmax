import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Import connectivity_plus
import '../providers/auth_provider.dart';
import '../services/api_service.dart'; // Import ApiService
import '../services/api_exception.dart'; // Import ApiException
import '../utils/app_utils.dart'; // Import AppUtils for snackbars
import '../utils/error_handler.dart';
import '../widgets/sidebar_scaffold.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        setState(() {
          _error = 'Ingia online ili kusimamia wauzaji';
        });
        AppUtils.showErrorSnackBar('Ingia online ili kusimamia wauzaji');
        return;
      }

      final apiService = ApiService();
      final response = await apiService.get('/users');
      
      if (response['success'] == true && response['data'] is List) {
        setState(() {
          _users = response['data'];
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Imeshindikana kupata orodha ya wauzaji';
        });
        AppUtils.showErrorSnackBar(_error!);
      }
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
      });
      AppUtils.showErrorSnackBar(e.message);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      AppUtils.showErrorSnackBar('Hitilafu isiyotarajiwa: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addUserDialog() async {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final phoneController = TextEditingController();
    bool isSubmitting = false;
    String? errorMsg;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ongeza Muuzaji'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Jina Kamili'),
                        validator: (v) => v == null || v.isEmpty ? 'Jina linahitajika' : null,
                      ),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Namba ya Simu'),
                        validator: (v) => v == null || v.isEmpty ? 'Namba ya simu inahitajika' : null,
                      ),
                      TextFormField(
                        controller: passwordController,
                        decoration: const InputDecoration(labelText: 'Nywila'),
                        obscureText: true,
                        validator: (v) => v == null || v.length < 6 ? 'Nywila angalau herufi 6' : null,
                      ),
                      TextFormField(
                        controller: confirmPasswordController,
                        decoration: const InputDecoration(labelText: 'Thibitisha Nywila'),
                        obscureText: true,
                        validator: (v) => v != passwordController.text ? 'Nywila hazifanani' : null,
                      ),
                      if (errorMsg != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(errorMsg!, style: const TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Ghairi'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => isSubmitting = true);
                          try {
                            final connectivityResult = await (Connectivity().checkConnectivity());
                            if (connectivityResult == ConnectivityResult.none) {
                              setState(() => errorMsg = 'Ingia online ili kuongeza muuzaji');
                              AppUtils.showErrorSnackBar('Ingia online ili kuongeza muuzaji');
                              isSubmitting = false;
                              return;
                            }

                            final apiService = ApiService();
                            final response = await apiService.post(
                              '/users',
                              {
                                'name': nameController.text.trim(),
                                'phone': phoneController.text.trim(),
                                'password': passwordController.text,
                                'password_confirmation': confirmPasswordController.text,
                              },
                            );
                            if (response['success'] == true) {
                              Navigator.pop(context);
                              await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Akaunti Imeundwa'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Muuzaji ameongezwa. Mpe taarifa hizi ili aweze kuingia:'),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Text('Namba ya Simu: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Expanded(child: Text(phoneController.text.trim())),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Text('Nywila: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Expanded(child: Text(passwordController.text)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Sawa'),
                                    ),
                                  ],
                                ),
                              );
                              _fetchUsers();
                            } else {
                              setState(() => errorMsg = response['message'] ?? 'Imeshindikana kuongeza muuzaji');
                            }
                          } on ApiException catch (e) {
                            ErrorHandler.handleError(context, e);
                            String errorMessage = e.message; // For display in dialog
                            if (e.errors != null && e.errors!.isNotEmpty) {
                              errorMessage = e.errors!.values.first.join('\n');
                            }
                            setState(() => errorMsg = errorMessage);
                          } catch (e) {
                            setState(() => errorMsg = e.toString());
                          } finally {
                            setState(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Ongeza'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _resetPasswordDialog(int userId, String userPhone) async {
    final _formKey = GlobalKey<FormState>();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isSubmitting = false;
    String? errorMsg;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Weka Nywila Mpya'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Badilisha nywila ya $userPhone'),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Nywila Mpya'),
                      obscureText: true,
                      validator: (v) => v == null || v.length < 6 ? 'Nywila angalau herufi 6' : null,
                    ),
                    TextFormField(
                      controller: confirmPasswordController,
                      decoration: const InputDecoration(labelText: 'Thibitisha Nywila'),
                      obscureText: true,
                      validator: (v) => v != passwordController.text ? 'Nywila hazifanani' : null,
                    ),
                    if (errorMsg != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(errorMsg!, style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Ghairi'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => isSubmitting = true);
                          try {
                            final connectivityResult = await (Connectivity().checkConnectivity());
                            if (connectivityResult == ConnectivityResult.none) {
                              setState(() => errorMsg = 'Ingia online ili kubadilisha nywila');
                              AppUtils.showErrorSnackBar('Ingia online ili kubadilisha nywila');
                              isSubmitting = false;
                              return;
                            }

                            final apiService = ApiService();
                            final responseData = await apiService.post(
                              '/users/$userId/reset-password',
                              {
                                'password': passwordController.text,
                                'password_confirmation': confirmPasswordController.text,
                              },
                            );
                            if (responseData['success'] == true) {
                              Navigator.pop(context);
                              await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Nywila Imebadilishwa'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Nywila mpya imesetiwa. Mpe muuzaji taarifa hizi:'),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Text('Namba ya Simu: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Expanded(child: Text(userPhone)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Text('Nywila Mpya: ', style: TextStyle(fontWeight: FontWeight.bold)),
                                          Expanded(child: Text(passwordController.text)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Sawa'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              setState(() => errorMsg = responseData['message'] ?? 'Imeshindikana kubadilisha nywila');
                            }
                          } catch (e) {
                            setState(() => errorMsg = e.toString());
                          } finally {
                            setState(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Weka Mpya'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _removeUser(int userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ondoa Muuzaji'),
        content: const Text('Una uhakika unataka kumwondoa muuzaji huyu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hapana'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ndiyo'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) {
        AppUtils.showErrorSnackBar('Ingia online ili kuondoa muuzaji');
        setState(() => _isLoading = false);
        return;
      }

      final apiService = ApiService();
      final response = await apiService.delete('/users/$userId');
      if (response['success'] == true) {
        _fetchUsers();
        AppUtils.showSuccessSnackBar('Muuzaji ameondolewa kikamilifu');
      } else {
        AppUtils.showErrorSnackBar(response['message'] ?? 'Imeshindikana kuondoa muuzaji');
      }
    } on ApiException catch (e) {
      AppUtils.showErrorSnackBar(e.message);
    } catch (e) {
      AppUtils.showErrorSnackBar('Hitilafu isiyotarajiwa: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Text('Simamia Wauzaji'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(user['name'] ?? ''),
                      subtitle: Text(user['phone'] ?? ''),
                      trailing: user['role'] == 'owner'
                          ? const Text('Mmiliki', style: TextStyle(color: Colors.blue))
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.lock_reset, color: Colors.orange),
                                  tooltip: 'Weka Nywila Mpya',
                                  onPressed: () => _resetPasswordDialog(user['id'], user['phone']),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeUser(user['id']),
                                ),
                              ],
                            ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUserDialog,
        child: const Icon(Icons.person_add),
        tooltip: 'Ongeza Muuzaji',
      ),
    );
    if (kIsWeb && MediaQuery.of(context).size.width >= 840) {
      return SidebarScaffold(content: scaffold);
    } else {
      return scaffold;
    }
  }
} 