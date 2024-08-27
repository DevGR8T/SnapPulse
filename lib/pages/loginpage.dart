import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snap_pulse/services/authservices.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers for email and password input fields
  TextEditingController _emailcontroller = TextEditingController();
  TextEditingController _passwordcontroller = TextEditingController();

  // Instance of authentication service
  Authservices authservices = Authservices();
  bool loading = false;
  final formkey = GlobalKey<FormState>();
  bool hidepassword = true;

  // Function to show exit confirmation dialog
  Future<bool> _onWillPop(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(),
            title: Text('Exit App'),
            content: Text('Do you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: Text('Yes'),
              ),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('No'))
            ],
          ),
        ) ??
        false; // If dialog is dismissed by tapping outside, default to false
  }

  // Dispose of controllers when the widget is removed from the widget tree
  @override
  void dispose() {
    _emailcontroller.dispose();
    _passwordcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return PopScope(
      // Prevent default back button behavior
      canPop: false,
      // Handle back button press or swipe
      onPopInvoked: (didPop) async {
        if (didPop) {
          // If a pop was already handled, do nothing
          return;
        }
        // Show exit confirmation
        final shouldPop = await _onWillPop(context);
        if (shouldPop) {
          // If user confirms exit, close the app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
            child: Center(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Form(
              key: formkey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 150),
                    Text(
                      'SnapPulse',
                      style: TextStyle(
                        fontSize: 30,
                      ),
                    ),
                    SizedBox(height: 50),

                    // Email input field
                    Container(
                      height: size.height / 12,
                      child: TextFormField(
                        controller: _emailcontroller,
                        cursorColor: Colors.grey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (email) {
                          if (email == '') {
                            return "please enter your Email ";
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
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.zero),
                          focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey, width: 1.2),
                              borderRadius: BorderRadius.zero),
                          hintText: 'Email',
                        ),
                      ),
                    ),

                    // Password input field
                    Container(
                      height: size.height / 12,
                      child: TextFormField(
                        controller: _passwordcontroller,
                        cursorColor: Colors.grey,
                        obscureText: hidepassword,
                        validator: (password) {
                          if (password == '') {
                            return 'Enter a password ';
                          } else if (password!.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(5),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.zero),
                          focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.grey, width: 1.2),
                              borderRadius: BorderRadius.zero),
                          hintText: 'Password',
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                hidepassword = !hidepassword;
                              });
                            },
                            icon: Icon(hidepassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                      ),
                    ),

                    // Sign In button
                    Container(
                      margin: EdgeInsets.only(top: 30),
                      width: size.width,
                      child: ElevatedButton(
                          onPressed: () async {
                            setState(() {
                              loading = true;
                            });
                            if (formkey.currentState!.validate()) {
                              try {
                                // Attempt to sign in
                                await authservices.signIn(_emailcontroller.text,
                                    _passwordcontroller.text);

                               

                                // Navigate to home page
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/rootpage',
                                    (Route<dynamic> route) => false);
                              } catch (error) {
                                // Handle sign-in errors
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  duration: Duration(seconds: 1),
                                  content: Text(
                                    error.toString(),
                                  ),
                                  backgroundColor: Colors.red,
                                ));
                              } finally {
                                setState(() {
                                  loading = false;
                                });
                              }
                            } else {
                              setState(() {
                                loading = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(),
                          ),
                          child: loading
                              ? Center(
                                  child: SizedBox(
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      backgroundColor: Colors.white,
                                      color: Colors.purple,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17),
                                )),
                    ),
                    SizedBox(height: size.height / 4.5),
                    // Sign up option for new users
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Don\'t have an account?'),
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/signup', (Route<dynamic> route) => false);
                            },
                            child: Text(
                              'SignUp',
                              style: TextStyle(fontSize: 15),
                            ))
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        )),
      ),
    );
  }
}
