import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class Customer {
  int? id;
  String fullName;
  String mobileNo;
  String emailId;
  String address; 
  double latitude;
  double longitude;
  String geoAddress; 
  String? imagePath; 

  Customer({
    this.id,
    required this.fullName,
    required this.mobileNo,
    required this.emailId,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.geoAddress,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'mobileNo': mobileNo,
      'emailId': emailId,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'geoAddress': geoAddress,
      'imagePath': imagePath,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      fullName: map['fullName'],
      mobileNo: map['mobileNo'],
      emailId: map['emailId'],
      address: map['address'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      geoAddress: map['geoAddress'],
      imagePath: map['imagePath'],
    );
  }
}

class DatabaseHelper extends GetxService {
  static Database? _database;
  static const String _dbName = 'customer_database.db';
  static const String _tableName = 'customers';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT NOT NULL,
        mobileNo TEXT NOT NULL,
        emailId TEXT NOT NULL,
        address TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        geoAddress TEXT NOT NULL,
        imagePath TEXT
      )
    ''');
  }

  Future<int> createCustomer(Customer customer) async {
    final db = await database;
    return await db.insert(_tableName, customer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName, orderBy: 'fullName ASC');
    if (maps.isEmpty) return [];
    return List.generate(maps.length, (i) {
      return Customer.fromMap(maps[i]);
    });
  }
}

class CustomerController extends GetxController {
  final dbHelper = Get.find<DatabaseHelper>();
  final ImagePicker _picker = ImagePicker();

  // For Customer List
  var customers = <Customer>[].obs;
  var isLoadingList = true.obs;

  // For Add Customer Form
  final GlobalKey<FormState> addCustomerFormKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController mobileNoController = TextEditingController();
  final TextEditingController emailIdController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  
  var geoAddress = ''.obs;
  var customerImagePath = RxnString();
  var isSaving = false.obs;
  var isFetchingLocation = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    try {
      isLoadingList.value = true;
      customers.value = await dbHelper.getCustomers();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load customers: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoadingList.value = false;
    }
  }

  void pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70, maxWidth: 800);
      if (pickedFile != null) {
        customerImagePath.value = pickedFile.path;
      }
    } catch (e) {
      Get.snackbar('Image Picker Error', e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> captureCurrentLocationAndAddress() async {
    isFetchingLocation.value = true;
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('Location Error', 'Location services are disabled.', backgroundColor: Colors.orange);
        isFetchingLocation.value = false;
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('Location Error', 'Location permissions are denied.', backgroundColor: Colors.orange);
          isFetchingLocation.value = false;
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        Get.snackbar('Location Error', 'Location permissions are permanently denied, we cannot request permissions.', backgroundColor: Colors.red);
        isFetchingLocation.value = false;
        _showPermissionDialog();
        return;
      } 

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      
      latitudeController.text = position.latitude.toString();
      longitudeController.text = position.longitude.toString();

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        geoAddress.value =
            "${place.street}, ${place.locality}, ${place.postalCode}, ${place.country}";
      } else {
        geoAddress.value = "Could not fetch address";
      }
    } catch (e) {
      geoAddress.value = "Error fetching address: ${e.toString()}";
      Get.snackbar('Location Error', 'Failed to get location/address: ${e.toString()}',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isFetchingLocation.value = false;
    }
  }

  void _showPermissionDialog() {
    Get.defaultDialog(
      title: "Permission Required",
      middleText: "Location permission is required to use this feature. Please enable it in app settings.",
      textConfirm: "Open Settings",
      textCancel: "Cancel",
      confirmTextColor: Colors.white,
      onConfirm: () {
        openAppSettings();
        Get.back();
      },
    );
  }

  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) return 'Full Name is required';
    return null;
  }

  String? validateMobileNo(String? value) {
    if (value == null || value.isEmpty) return 'Mobile No is required';
    if (!GetUtils.isPhoneNumber(value)) return 'Enter a valid mobile number';
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email ID is required';
    if (!GetUtils.isEmail(value)) return 'Enter a valid email address';
    return null;
  }
  
  String? validateAddress(String? value) {
    if (value == null || value.isEmpty) return 'Address is required';
    return null;
  }

  String? validateLatitude(String? value) {
    if (value == null || value.isEmpty) return 'Latitude is required';
    if (double.tryParse(value) == null) return 'Enter a valid latitude';
    return null;
  }
  
  String? validateLongitude(String? value) {
    if (value == null || value.isEmpty) return 'Longitude is required';
    if (double.tryParse(value) == null) return 'Enter a valid longitude';
    return null;
  }

  Future<void> saveCustomer() async {
    if (addCustomerFormKey.currentState!.validate()) {
      if (customerImagePath.value == null) {
         Get.snackbar('Validation Error', 'Please select a customer image.',
            backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }
      if (geoAddress.value.isEmpty || geoAddress.value.startsWith("Error") || geoAddress.value.startsWith("Could not")) {
         Get.snackbar('Validation Error', 'Please capture a valid Geo Address.',
            backgroundColor: Colors.orange, colorText: Colors.white);
        return;
      }

      isSaving.value = true;
      try {
        final newCustomer = Customer(
          fullName: fullNameController.text,
          mobileNo: mobileNoController.text,
          emailId: emailIdController.text,
          address: addressController.text,
          latitude: double.parse(latitudeController.text),
          longitude: double.parse(longitudeController.text),
          geoAddress: geoAddress.value,
          imagePath: customerImagePath.value,
        );
        await dbHelper.createCustomer(newCustomer);
        Get.snackbar('Success', 'Customer saved successfully!',
            backgroundColor: Colors.green, colorText: Colors.white);
        clearAddCustomerForm();
        await fetchCustomers(); 
        Get.offNamed('/customer_list'); 
      } catch (e) {
        Get.snackbar('Error', 'Failed to save customer: ${e.toString()}',
            backgroundColor: Colors.red, colorText: Colors.white);
      } finally {
        isSaving.value = false;
      }
    }
  }

  void clearAddCustomerForm() {
    fullNameController.clear();
    mobileNoController.clear();
    emailIdController.clear();
    addressController.clear();
    latitudeController.clear();
    longitudeController.clear();
    geoAddress.value = '';
    customerImagePath.value = null;
  }

  Future<void> openMapForCustomer(Customer customer) async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Get.snackbar('Location Error', 'Location services are disabled to get current location for directions.', backgroundColor: Colors.orange);
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Get.snackbar('Location Error', 'Location permissions are denied.', backgroundColor: Colors.orange);
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
         Get.snackbar('Location Error', 'Location permissions are permanently denied.', backgroundColor: Colors.red);
         _showPermissionDialog();
        return;
      }
      
      Position currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      
      String googleMapsUrl = 
          'https://www.google.com/maps/dir/?api=1&origin=${currentPosition.latitude},${currentPosition.longitude}&destination=${customer.latitude},${customer.longitude}&travelmode=driving';
      
      Uri uri = Uri.parse(googleMapsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Map Error', 'Could not launch Google Maps.', backgroundColor: Colors.red);
      }
    } catch (e) {
       Get.snackbar('Map Error', 'Error opening map: ${e.toString()}', backgroundColor: Colors.red);
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    mobileNoController.dispose();
    emailIdController.dispose();
    addressController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.onClose();
  }
}

class CustomerListPage extends StatelessWidget {
  CustomerListPage({super.key});
  final CustomerController controller = Get.find<CustomerController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer List'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.fetchCustomers(),
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingList.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.customers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text('No customers found.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                const SizedBox(height: 8),
                Text('Tap the "+" button to add a new customer.', style: TextStyle(color: Colors.grey[600])),
              ],
            )
          );
        }
        return ListView.builder(
          itemCount: controller.customers.length,
          itemBuilder: (context, index) {
            final customer = controller.customers[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.indigo[100],
                  backgroundImage: customer.imagePath != null && customer.imagePath!.isNotEmpty
                      ? FileImage(File(customer.imagePath!))
                      : null,
                  child: customer.imagePath == null || customer.imagePath!.isEmpty
                      ? Text(customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : '?', 
                                style: const TextStyle(fontSize: 24, color: Colors.indigo))
                      : null,
                ),
                title: Text(customer.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('📱 ${customer.mobileNo}'),
                    Text('📧 ${customer.emailId}'),
                    const SizedBox(height: 2),
                    Text('📍 ${customer.geoAddress}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.directions, color: Colors.green[600], size: 28),
                  onPressed: () => controller.openMapForCustomer(customer),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          controller.clearAddCustomerForm();
          Get.toNamed('/add_customer');
        },
        icon: const Icon(Icons.add),
        label: const Text("Add Customer"),
        backgroundColor: Colors.amber[700],
      ),
    );
  }
}

class AddCustomerPage extends StatelessWidget {
  AddCustomerPage({super.key});

  final CustomerController controller = Get.find<CustomerController>();

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (builder) {
          return SafeArea(
            child: Wrap(
              children: <Widget>[
                ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Gallery'),
                    onTap: () {
                      controller.pickImage(ImageSource.gallery);
                      Navigator.of(context).pop();
                    }),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Camera'),
                  onTap: () {
                    controller.pickImage(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Customer'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: controller.addCustomerFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Obx(() => GestureDetector(
                    onTap: () => _showImagePickerOptions(context),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.indigo[50],
                      backgroundImage: controller.customerImagePath.value != null
                          ? FileImage(File(controller.customerImagePath.value!))
                          : null,
                      child: controller.customerImagePath.value == null
                          ? Icon(Icons.camera_alt, size: 50, color: Colors.indigo[300])
                          : null,
                    ),
                  )),
              const SizedBox(height: 8),
              Center(child: Text("Tap to select customer image", style: TextStyle(color: Colors.grey[600]))),
              const SizedBox(height: 24),
              _buildTextField(controller.fullNameController, 'Full Name', Icons.person, controller.validateFullName),
              _buildTextField(controller.mobileNoController, 'Mobile No', Icons.phone, controller.validateMobileNo, inputType: TextInputType.phone),
              _buildTextField(controller.emailIdController, 'Email ID', Icons.email, controller.validateEmail, inputType: TextInputType.emailAddress),
              _buildTextField(controller.addressController, 'Address (e.g., Building, Street)', Icons.home_work, controller.validateAddress),
              
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(controller.latitudeController, 'Latitude', Icons.gps_fixed, controller.validateLatitude, inputType: const TextInputType.numberWithOptions(decimal: true))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(controller.longitudeController, 'Longitude', Icons.gps_fixed, controller.validateLongitude, inputType: const TextInputType.numberWithOptions(decimal: true))),
                ],
              ),
              const SizedBox(height: 16),
              Obx(() => ElevatedButton.icon(
                onPressed: controller.isFetchingLocation.value ? null : controller.captureCurrentLocationAndAddress,
                icon: controller.isFetchingLocation.value 
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                      : const Icon(Icons.my_location),
                label: const Text('Capture Geo Address & Coords'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              )),
              const SizedBox(height: 8),
              Obx(() => Text(
                controller.geoAddress.value.isEmpty ? 'Geo Address will appear here' : 'Geo Address: ${controller.geoAddress.value}',
                style: TextStyle(color: controller.geoAddress.value.startsWith("Error") || controller.geoAddress.value.startsWith("Could not") ? Colors.red : Colors.black54, fontSize: 13),
                textAlign: TextAlign.center,
              )),
              const SizedBox(height: 30),
              Obx(() => ElevatedButton(
                    onPressed: controller.isSaving.value ? null : controller.saveCustomer,
                    child: controller.isSaving.value
                        ? const SizedBox(height:20, width:20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                        : const Text('Save Customer'),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, IconData icon, FormFieldValidator<String>? validator, {TextInputType? inputType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        keyboardType: inputType ?? TextInputType.text,
        validator: validator,
      ),
    );
  }
}