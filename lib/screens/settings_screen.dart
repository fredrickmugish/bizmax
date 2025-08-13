// lib/screens/settings_screen.dart


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../services/backup_service.dart';

import '../providers/business_provider.dart';

import '../providers/inventory_provider.dart';

import '../providers/records_provider.dart';

import '../providers/auth_provider.dart'; // Ensure this is imported

import 'user_management_screen.dart';

import 'package:flutter/foundation.dart';

import '../models/business.dart';

import '../services/api_service.dart';


class SettingsScreen extends StatefulWidget {

const SettingsScreen({Key? key}) : super(key: key);


@override

State<SettingsScreen> createState() => _SettingsScreenState();

}


class _SettingsScreenState extends State<SettingsScreen> {

bool _isLoading = false;


@override

void initState() {

super.initState();

// Your existing initState code...

WidgetsBinding.instance.addPostFrameCallback((_) async {

// The commented out code here is fine.

});

}


void _showAddBusinessDialog(BuildContext context) {

// Your existing _showAddBusinessDialog code...

final _nameController = TextEditingController();

final List<String> businessTypes = [

'Duka la Jumla',

'Duka la Rejareja',

'Mgahawa',

'Huduma',

'Ofisi',

'Kiwanda',

'Nyingine',

];

String selectedType = businessTypes[0];

showDialog(

context: context,

builder: (context) => StatefulBuilder(

builder: (context, setState) => AlertDialog(

title: Text('Add New Business'),

content: Column(

mainAxisSize: MainAxisSize.min,

children: [

TextField(

controller: _nameController,

decoration: InputDecoration(labelText: 'Business Name'),

),

const SizedBox(height: 16),

DropdownButtonFormField<String>(

value: selectedType,

items: businessTypes

.map((type) => DropdownMenuItem(

value: type,

child: Text(type),

))

.toList(),

onChanged: (value) {

if (value != null) setState(() => selectedType = value);

},

decoration: InputDecoration(labelText: 'Business Type'),

),

],

),

actions: [

TextButton(

onPressed: () => Navigator.pop(context),

child: Text('Cancel'),

),

ElevatedButton(

onPressed: () async {

final name = _nameController.text.trim();

if (name.isNotEmpty) {

final api = ApiService();

try {

final response = await api.post('/businesses', {'name': name, 'type': selectedType});

if (response['success'] == true) {

Navigator.pop(context);

} else {

ScaffoldMessenger.of(context).showSnackBar(

SnackBar(content: Text(response['message'] ?? 'Failed to add business'), backgroundColor: Colors.red),

);

}

} catch (e) {

ScaffoldMessenger.of(context).showSnackBar(

SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),

);

}

}

},

child: Text('Add'),

),

],

),

),

);

}


@override

Widget build(BuildContext context) {

final businessProvider = Provider.of<BusinessProvider>(context);

final authProvider = Provider.of<AuthProvider>(context, listen: false);

final businessId = authProvider.user != null ? authProvider.user!['business_id']?.toString() : null;

// --- Get the current user role using the new getter ---

final currentUserRole = authProvider.currentUserRole;


// Optional: For debugging, you can add this line to see the extracted role

if (kDebugMode) {

print('SettingsScreen: Extracted current user role: $currentUserRole');

}

// -----------------------------------------------------


return Scaffold(

appBar: AppBar(

title: const Text('Mipangilio'),

backgroundColor: Colors.blue,

foregroundColor: Colors.white,

automaticallyImplyLeading: true,

),

body: ListView(

padding: const EdgeInsets.all(16),

children: [

_buildSettingsSection(

'Biashara',

[

_buildSettingsTile(

'Jina la Biashara',

businessProvider.businessName,

Icons.business,

() => _showBusinessNameDialog(businessProvider),

),

_buildSettingsTile(

'Aina ya Biashara',

businessProvider.businessType,

Icons.category,

() => _showBusinessTypeDialog(businessProvider),

),

],

),

const SizedBox(height: 20),

    // if (!kIsWeb)
    // _buildSettingsSection(
    //
    // 'Data',
    //
    // [
    //
    // _buildSettingsTile(
    //
    // 'Backup Data',
    //
    // 'Hifadhi nakala ya data zako',
    //
    // Icons.backup,
    //
    // () => _createBackup(),
    //
    // ),
    //
    // _buildSettingsTile(
    //
    // 'Rejesha Data',
    //
    // 'Rejesha data kutoka backup',
    //
    // Icons.restore,
    //
    // () => _restoreBackup(),
    //
    // ),
    //
    // _buildSettingsTile(
    //
    // 'Share Backup',
    //
    // 'Shiriki backup ya data zako',
    //
    // Icons.share,
    //
    // () => _shareBackup(),
    //
    // ),
    //
    // ],
    //
    // ),

const SizedBox(height: 20),

_buildSettingsSection(

'Wauzaji',

[

// --- MODIFY THIS CONDITION TO USE currentUserRole ---

if (currentUserRole == 'owner') // This condition will now correctly check the role

_buildSettingsTile(

'Simamia Wauzaji',

'Ongeza au ondoa wauzaji (salesperson)',

Icons.group,

() => Navigator.push(

context,

MaterialPageRoute(

builder: (context) => const UserManagementScreen(),

),

),

),

],

),

const SizedBox(height: 20),

_buildSettingsSection(

'Kuhusu',

[

_buildSettingsTile(

'Toleo la App',

'v1.0.0',

Icons.info,

() => _showAppInfo(),

),

],

),

],

),

);

}


// Your existing helper methods like _buildSettingsSection, _buildSettingsTile,

// _showBusinessNameDialog, _showBusinessTypeDialog, _createBackup,

// _restoreBackup, _shareBackup, _showAppInfo, _showSuccessMessage, _showErrorMessage

// remain unchanged below this point.

Widget _buildSettingsSection(String title, List<Widget> children) {

return Column(

crossAxisAlignment: CrossAxisAlignment.start,

children: [

Text(

title,

style: const TextStyle(

fontSize: 18,

fontWeight: FontWeight.bold,

color: Colors.blue,

),

),

const SizedBox(height: 10),

Card(

child: Column(children: children),

),

],

);

}


Widget _buildSettingsTile(

String title,

String subtitle,

IconData icon,

VoidCallback onTap, {

bool isDestructive = false,

}) {

return ListTile(

leading: Icon(

icon,

color: isDestructive ? Colors.red : Colors.blue,

),

title: Text(

title,

style: TextStyle(

color: isDestructive ? Colors.red : null,

fontWeight: FontWeight.w500,

),

),

subtitle: Text(subtitle),

trailing: _isLoading

? const SizedBox(

width: 20,

height: 20,

child: CircularProgressIndicator(strokeWidth: 2),

)

: const Icon(Icons.arrow_forward_ios, size: 16),

onTap: _isLoading ? null : onTap,

);

}


void _showBusinessNameDialog(BusinessProvider businessProvider) {

final authProvider = Provider.of<AuthProvider>(context, listen: false);

final businessId = authProvider.user != null ? authProvider.user!['business_id']?.toString() : null;

final controller = TextEditingController(text: businessProvider.businessName);

showDialog(

context: context,

builder: (context) => AlertDialog(

title: const Text('Badilisha Jina la Biashara'),

content: TextField(

controller: controller,

decoration: const InputDecoration(

labelText: 'Jina la Biashara',

border: OutlineInputBorder(),

),

),

actions: [

TextButton(

onPressed: () => Navigator.pop(context),

child: const Text('Ghairi'),

),

ElevatedButton(

onPressed: () async {

setState(() => _isLoading = true);

if (businessId != null) {

await businessProvider.setBusinessName(controller.text, businessId);

}

setState(() => _isLoading = false);

Navigator.pop(context);

_showSuccessMessage('Jina la biashara limebadilishwa');

},

child: const Text('Hifadhi'),

),

],

),

);

}


void _showBusinessTypeDialog(BusinessProvider businessProvider) {

final authProvider = Provider.of<AuthProvider>(context, listen: false);

final businessId = authProvider.user != null ? authProvider.user!['business_id']?.toString() : null;

  final types = [

'Duka la Jumla',

'Duka la Rejareja',

'Pharmacy',

'Hoteli/Mgahawa',

'Salon/Spa',

'Stationery',

'Hardware',

'Huduma za Teknolojia',

'Kilimo',

'Nyingine'

];


showDialog(

context: context,

builder: (context) => AlertDialog(

title: const Text('Chagua Aina ya Biashara'),

content: SizedBox(

width: double.maxFinite,

child: ListView.builder(

shrinkWrap: true,

itemCount: types.length,

itemBuilder: (context, index) {

return ListTile(

title: Text(types[index]),

onTap: () async {

setState(() => _isLoading = true);

if (businessId != null) {

await businessProvider.setBusinessType(types[index], businessId);

}

setState(() => _isLoading = false);

Navigator.pop(context);

_showSuccessMessage('Aina ya biashara imebadilishwa');

},

);

},

),

),

),

);

}


void _createBackup() async {
if (kIsWeb) {
_showErrorMessage('This feature is not available on the web.');
return;
}

setState(() => _isLoading = true);

try {

await BackupService.instance.createBackup();

_showSuccessMessage('Backup imehifadhiwa kikamilifu');

} catch (e) {

_showErrorMessage('Imeshindikana kuhifadhi backup: $e');

} finally {

setState(() => _isLoading = false);

}

}


void _restoreBackup() async {
if (kIsWeb) {
_showErrorMessage('This feature is not available on the web.');
return;
}

setState(() => _isLoading = true);

try {

FilePickerResult? result = await FilePicker.platform.pickFiles();

if (result != null && result.files.single.path != null) {

await BackupService.instance.restoreFromBackup(result.files.single.path!);

_showSuccessMessage('Backup imerejeshwa kikamilifu');

}

} catch (e) {

_showErrorMessage('Imeshindikana kurejesha backup: $e');

} finally {

setState(() => _isLoading = false);

}

}


void _shareBackup() async {
if (kIsWeb) {
_showErrorMessage('This feature is not available on the web.');
return;
}

setState(() => _isLoading = true);

try {

await BackupService.instance.shareBackup();

_showSuccessMessage('Backup imeshirikiwa kikamilifu');

} catch (e) {

_showErrorMessage('Imeshindikana kushiriki backup: $e');

} finally {

setState(() => _isLoading = false);

}

}


void _showAppInfo() {

showDialog(

context: context,

builder: (context) => AlertDialog(

title: const Text('Kuhusu Bizmax'),

content: const Column(

mainAxisSize: MainAxisSize.min,

crossAxisAlignment: CrossAxisAlignment.start,

children: [

Text('Bizmax - Business Management App'),

SizedBox(height: 8),

Text('Toleo: 1.0.0'),

SizedBox(height: 8),

Text('Imeundwa na: Pinova Technologies'),

SizedBox(height: 8),

Text('© 2025 Haki zote zimehifadhiwa'),

],

),

actions: [

TextButton(

onPressed: () => Navigator.pop(context),

child: const Text('Sawa'),

),

],

),

);

}


void _showSuccessMessage(String message) {

ScaffoldMessenger.of(context).showSnackBar(

SnackBar(content: Text(message), backgroundColor: Colors.green),

);

}


void _showErrorMessage(String message) {

ScaffoldMessenger.of(context).showSnackBar(

SnackBar(content: Text(message), backgroundColor: Colors.red),

);

}

}