import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirm = true;
  bool isLoading = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final response = await supabase.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        data: {
          'first_name': firstNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'phone': phoneController.text.trim(),
        },
      );

      if (response.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Register Success 🎉")),
        );
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity, // ✅ ทำให้เต็มจอแน่นอน
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3E5F5), Color(0xFFFFF3E0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight, // ✅ บังคับขั้นต่ำเต็มจอ
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Icon(Icons.person_add,
                              size: 70, color: Colors.purple),
                          const SizedBox(height: 16),
                          const Text(
                            "Create Account",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 30),

                          Row(
                            children: [
                              Expanded(
                                child: buildTextField(
                                  controller: firstNameController,
                                  label: "First Name",
                                  icon: Icons.person_outline,
                                  validator: (value) =>
                                      value!.isEmpty ? "Required" : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: buildTextField(
                                  controller: lastNameController,
                                  label: "Last Name",
                                  icon: Icons.person_outline,
                                  validator: (value) =>
                                      value!.isEmpty ? "Required" : null,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          buildTextField(
                            controller: emailController,
                            label: "Email",
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null ||
                                  !RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                      .hasMatch(value)) {
                                return "Enter valid email";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          buildTextField(
                            controller: passwordController,
                            label: "Password",
                            icon: Icons.lock_outline,
                            obscureText: obscurePassword,
                            suffix: IconButton(
                              icon: Icon(obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () => setState(() =>
                                  obscurePassword = !obscurePassword),
                            ),
                            validator: (value) {
                              if (value == null || value.length < 8) {
                                return "Minimum 8 characters";
                              }
                              if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                return "Add uppercase letter";
                              }
                              if (!RegExp(r'[0-9]').hasMatch(value)) {
                                return "Add a number";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          buildTextField(
                            controller: confirmPasswordController,
                            label: "Confirm Password",
                            icon: Icons.lock_outline,
                            obscureText: obscureConfirm,
                            suffix: IconButton(
                              icon: Icon(obscureConfirm
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () => setState(
                                  () => obscureConfirm = !obscureConfirm),
                            ),
                            validator: (value) {
                              if (value != passwordController.text) {
                                return "Passwords do not match";
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          buildTextField(
                            controller: phoneController,
                            label: "Phone (Optional)",
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _register,
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text(
                                      "Register",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Already have an account? Login",
                              style:
                                  TextStyle(color: Colors.purple),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.purple),
        suffixIcon: suffix,
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}