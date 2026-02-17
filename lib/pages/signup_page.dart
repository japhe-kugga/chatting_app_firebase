import 'package:chatting_app_firebase/components/my_button.dart';
import 'package:chatting_app_firebase/components/my_textfield.dart';
import 'package:chatting_app_firebase/components/password_field.dart';
import 'package:chatting_app_firebase/services/auth_service.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  final void Function()? onTap;

  const SignupPage({super.key, required this.onTap});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  // text controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();

  // loading state
  bool _isLoading = false;

  // sign up method
  void signUp() async {
    if (passwordController.text != confirmPasswordController.text) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => const AlertDialog(
            title: Text("Passwords don't match!"),
          ),
        );
      }
      return;
    }

    // set loading to true
    setState(() {
      _isLoading = true;
    });

    // get auth service
    final authService = AuthService();

    try {
      await authService.signUpWithEmailPassword(
        emailController.text,
        passwordController.text,
        nameController.text,
      );
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(e.toString()),
          ),
        );
      }
    } finally {
      // set loading to false
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),

                  // logo
                  Icon(
                    Icons.message,
                    size: 100,
                    color: Theme.of(context).colorScheme.primary,
                  ),

                  const SizedBox(height: 50),

                  // create account message
                  Text(
                    "Let's create an account for you!",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // name textfield
                  MyTextField(
                    controller: nameController,
                    hintText: 'Name',
                    obscureText: false,
                  ),

                  const SizedBox(height: 10),

                  // email textfield
                  MyTextField(
                    controller: emailController,
                    hintText: 'Email',
                    obscureText: false,
                  ),

                  const SizedBox(height: 10),

                  // password field (reusable)
                  PasswordField(controller: passwordController),

                  const SizedBox(height: 10),

                  // confirm password field (reusable)
                  PasswordField(
                      controller: confirmPasswordController,
                      hintText: 'Confirm Password'),

                  const SizedBox(height: 25),

                  // sign up button
                  MyButton(
                    onTap: signUp,
                    text: 'Sign Up',
                    isLoading: _isLoading,
                  ),

                  const SizedBox(height: 50),

                  // already a member
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already a member?',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onTap,
                        child: Text(
                          'Login now',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
