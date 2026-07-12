import 'package:flutter/material.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';
import 'package:kisan_unnati/auth/auth_service.dart';
import 'package:kisan_unnati/auth/register_screen.dart';
import 'package:kisan_unnati/screens/dashboard/dashboard_screen.dart';
import 'package:kisan_unnati/features/dashboard/buyer_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _identifierController = TextEditingController(); // Replaced email with identifier
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true; // 🔥 State for showing/hiding password

  void _login() async {
    if (_identifierController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    setState(() => _isLoading = true);

    // 1. Log the user in
    // (Note: Currently passes to 'email'. To fully support raw phone/aadhar login later,
    // you would look up the email associated with the phone/aadhar in Firestore first!)
    String result = await _authService.loginUser(
      email: _identifierController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (result == "Success") {
      // 2. Fetch their role
      String role = await _authService.getUserRole();
      var userDoc = await _authService.getUserProfile();
      String name = userDoc['fullName'] ?? 'User';

      setState(() => _isLoading = false);

      // 3. The "Traffic Cop" - Send them to the right dashboard!
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Welcome back, $name! 👋"),
            backgroundColor: AppColors.primaryGreen,
            duration: const Duration(seconds: 3), // Disappears after 3 seconds
          )
      );
      if (role == 'Kisan') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BuyerDashboardScreen(role: role)));
      }
    } else {
      setState(() => _isLoading = false);
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
              opacity: 0.10,
              child: Image.asset(
                'assets/images/logo.png',
                width: 300,
              ),
            ),
          ),

          // FOREGROUND: The Login Form
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/logo.png', height: 80),
                    const SizedBox(height: 30),

                    const Text("Welcome Back!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    const SizedBox(height: 10),
                    const Text("Login to your KisaanUnnati account", style: TextStyle(color: Colors.grey, fontSize: 16)),
                    const SizedBox(height: 40),

                    // 🔥 Multi-Login Field
                    _buildTextField("Email, Phone, or Aadhar", Icons.person, _identifierController),

                    // 🔥 Password Field (Now supports toggle)
                    _buildTextField("Password", Icons.lock, _passwordController, isPassword: true),

                    const SizedBox(height: 10),

                    // Forgot Password (Extra UI polish)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text("Forgot Password?", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 25),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // 🔥 Alternative Login Options Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Text("Or continue with", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 🔥 Social / Alternative Login Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialButton(Icons.g_mobiledata, Colors.red, "Google", () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Google Login coming soon!")));
                        }),
                        const SizedBox(width: 15),
                        _buildSocialButton(Icons.phone_android, Colors.blue, "OTP", () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Phone OTP coming soon!")));
                        }),
                        const SizedBox(width: 15),
                        _buildSocialButton(Icons.fingerprint, Colors.orange, "Aadhar", () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Aadhar Login coming soon!")));
                        }),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(fontSize: 15)),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                          },
                          child: const Text("Register here", style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.bold, fontSize: 15)),
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

  // Helper function for the main text fields
  Widget _buildTextField(String hint, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false, // 🔥 Toggle obscureText
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.darkGreen),

          // 🔥 Add the Eye Icon if it's a password field
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          )
              : null,

          filled: true,
          fillColor: Colors.white.withOpacity(0.9),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2)),
        ),
      ),
    );
  }

  // Helper function for the new Social/Alternative Login buttons
  Widget _buildSocialButton(IconData icon, Color color, String tooltip, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        width: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}