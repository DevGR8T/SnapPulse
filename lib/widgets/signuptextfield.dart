import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:snap_pulse/services/authservices.dart';

// StatefulWidget for the sign-up form
class SignUpWidget extends StatefulWidget {
  const SignUpWidget({required this.selectedImage, super.key});
  final selectedImage; // Stores the selected profile image

  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  // Instance of AuthServices for handling authentication
  final Authservices authservices = Authservices();

  // Controllers for form fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Flags to toggle password visibility
  bool hidePassword = true;
  bool hidePassword2 = true;

  // Form key for validation
  final formKey = GlobalKey<FormState>();

  // Dispose method to clean up controllers when the widget is removed
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            // Name TextField
            Container(
              height: size.height / 12,
              child: TextFormField(
                controller: nameController,
                cursorColor: Colors.grey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                maxLength: 20,
                validator: (name) {
                  if (name == '') {
                    return "Please enter your name";
                  }
                  return null;
                },
                decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(5),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.grey,
                        ),
                        borderRadius: BorderRadius.zero),
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey, width: 1.2),
                        borderRadius: BorderRadius.zero),
                    hintText: 'Name',
                    counterText: ''),
              ),
            ),

            // Email TextField
            Container(
              height: size.height / 12,
              child: TextFormField(
                controller: emailController,
                cursorColor: Colors.grey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (email) {
                  if (email == '') {
                    return "Please enter your email";
                  } else if (!EmailValidator.validate(email!)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(5),
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.grey,
                      ),
                      borderRadius: BorderRadius.zero),
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1.2),
                      borderRadius: BorderRadius.zero),
                  hintText: 'Email',
                ),
              ),
            ),

            // Password TextField
            Container(
              height: size.height / 12,
              child: TextFormField(
                controller: passwordController,
                cursorColor: Colors.grey,
                obscureText: hidePassword,
                validator: (password) {
                  if (password == '') {
                    return 'Enter a password';
                  } else if (password!.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1.2),
                      borderRadius: BorderRadius.zero),
                  hintText: 'Password',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                    icon: Icon(
                        hidePassword ? Icons.visibility_off : Icons.visibility),
                  ),
                ),
              ),
            ),

            // Confirm Password TextField
            Container(
              height: size.height / 12,
              child: TextFormField(
                controller: confirmPasswordController,
                cursorColor: Colors.grey,
                validator: (password) {
                  if (password == '') {
                    return 'Confirm password';
                  } else if (password!.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
                obscureText: hidePassword2,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey, width: 1.2),
                      borderRadius: BorderRadius.zero),
                  hintText: 'Confirm Password',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        hidePassword2 = !hidePassword2;
                      });
                    },
                    icon: Icon(hidePassword2
                        ? Icons.visibility_off
                        : Icons.visibility),
                  ),
                ),
              ),
            ),

            // Sign Up Button
            Container(
              margin: EdgeInsets.only(top: 25),
              width: size.width,
              child: ElevatedButton(
                  onPressed: () async {
                    // Validate the form
                    if (formKey.currentState!.validate()) {
                      // Check if passwords match
                      if (passwordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          duration: Duration(seconds: 1),
                          content: Text(
                            'Passwords do not match',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                        ));

                        return;
                      }
                      // Check if the user selected a profile photo
                      if (widget.selectedImage == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: Duration(seconds: 1),
                            content: Text(
                              'Please add a profile photo',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      try {
                        // Show Loading Dialog
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) {
                            return Dialog(
                              shape: RoundedRectangleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 20),
                                    Text('Registering...'),
                                  ],
                                ),
                              ),
                            );
                          },
                        );

                        // Attempt to sign up the user
                        await authservices.signup(
                            emailController.text,
                            passwordController.text,
                            nameController.text,
                            widget.selectedImage);

                        // Close the Loading Dialog
                        Navigator.pop(context);

                        // Show the success dialog
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Registration Successful'),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(3)),
                                content: Text(
                                    'You have been registered successfully'),
                              );
                            });

                        // Navigate to Homepage
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/rootpage', (Route<dynamic> route) => false);
                      } catch (e) {
                        // Close the Loading Dialog
                        Navigator.of(context).pop();

                        // Show Error Message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(),
                      backgroundColor: Colors.purple),
                  child: Text(
                    'Sign Up',
                    style: TextStyle(color: Colors.white),
                  )),
            )
          ],
        ),
      ),
    );
  }
}
