import 'package:flutter/material.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';
import 'auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();

  // Text Controllers to grab what the user types
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String _selectedRole = 'Kisan'; // Default role
  final List<String> _roles = ['Kisan', 'Vyapari', 'Grahak'];
  bool _isLoading = false;

  // 🔥 State variables for password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _signUp() async {
    // Basic validations before calling Firebase
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!")));
      return;
    }
    if (_phoneController.text.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid 10-digit phone number.")));
      return;
    }
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your complete address.")));
      return;
    }

    setState(() => _isLoading = true);

    // Call our Firebase Brain
    String result = await _authService.registerUser(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text.trim(),
      role: _selectedRole,
      aadhar: _aadharController.text.trim(),
      address: _addressController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result == "Success") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registration Successful! Please login.")));
      // Send them back to the Login Screen
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    } else {
      // Show the exact error (like duplicate Aadhar)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // BACKGROUND: Low Opacity Logo Watermark
          Center(
            child: Opacity(
              opacity: 0.10, // 10% visibility
              child: Image.asset(
                'assets/images/logo.png',
                width: 300,
              ),
            ),
          ),

          // FOREGROUND: The Registration Form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text("Create an Account", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    const SizedBox(height: 5),
                    const Text("Join the KisaanUnnati network", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 30),

                    // Profile Type Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedRole,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.darkGreen),
                          items: _roles.map((String role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Text("Register as: $role", style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() => _selectedRole = newValue!);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form Fields (Notice they all jump to the next field automatically)
                    _buildTextField("Full Name", Icons.person, _nameController),
                    _buildTextField("Email (Gmail)", Icons.email, _emailController, isEmail: true),
                    _buildTextField("Phone Number", Icons.phone, _phoneController, isNumber: true),
                    _buildTextField("Complete Address (Village/City)", Icons.location_on, _addressController),
                    _buildTextField("Aadhar Number (Optional)", Icons.credit_card, _aadharController, isNumber: true),

                    // 🔥 Password Field
                    _buildTextField(
                      "Password",
                      Icons.lock,
                      _passwordController,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),

                    // 🔥 Confirm Password Field (Triggers registration on Enter)
                    _buildTextField(
                      "Confirm Password",
                      Icons.lock_outline,
                      _confirmPasswordController,
                      isPassword: true,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done, // Change keyboard button to "Done"
                      onSubmitted: (_) => _signUp(), // Execute signUp when "Done" is pressed
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Register", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Login Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? ", style: TextStyle(fontSize: 15)),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                          },
                          child: const Text("Login here", style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.bold, fontSize: 15)),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Helper function updated to support keyboard actions and custom suffix icons
  Widget _buildTextField(
      String hint,
      IconData icon,
      TextEditingController controller, {
        bool isPassword = false,
        bool isEmail = false,
        bool isNumber = false,
        bool obscureText = false,
        Widget? suffixIcon,
        TextInputAction textInputAction = TextInputAction.next,
        Function(String)? onSubmitted,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        keyboardType: isNumber ? TextInputType.number : (isEmail ? TextInputType.emailAddress : TextInputType.text),
        textInputAction: textInputAction, // Connects to the keyboard "Next" or "Done" button
        onSubmitted: onSubmitted, // Fires when the keyboard "Done" button is tapped
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.darkGreen),
          suffixIcon: suffixIcon, // Inserts the Eye icon here
          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2)),
        ),
      ),
    );
  }
}