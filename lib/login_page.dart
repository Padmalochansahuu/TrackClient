import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final TextEditingController userIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final String validUserId = 'user@maxmobility.in';
  final String validPassword = 'Abc@#123';

  var obscurePassword = true.obs;

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  String? validateUserId(String? value) {
    if (value == null || value.isEmpty) {
      return 'User ID cannot be empty';
    }
    if (value != validUserId) {
      return 'Invalid User ID';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty';
    }
    if (value != validPassword) {
      return 'Invalid Password';
    }
    return null;
  }

  void login() {
    if (formKey.currentState!.validate()) {
      Get.snackbar('Login Success', 'Welcome!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white);
      Get.offAllNamed('/customer_list'); 
    } else {
      Get.snackbar('Login Failed', 'Please check your credentials',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }
  }

  @override
  void onClose() {
    userIdController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}

class LoginPage extends StatelessWidget {
  LoginPage({super.key});

  final LoginController loginController = Get.find<LoginController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Max Mobility Login'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: loginController.formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Image.asset(
                  'assets/logo/maxmobility_pvt_ltd__logo.jpeg', 
                  height: 100,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.business, size: 100, color: Colors.indigo),
                ),
                const SizedBox(height: 30),
                Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: loginController.userIdController,
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                    hintText: 'e.g., user@maxmobility.in',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: loginController.validateUserId,
                ),
                const SizedBox(height: 20),
                Obx(() => TextFormField(
                      controller: loginController.passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(loginController.obscurePassword.value
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: loginController.togglePasswordVisibility,
                        ),
                      ),
                      obscureText: loginController.obscurePassword.value,
                      validator: loginController.validatePassword,
                    )),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: loginController.login,
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}