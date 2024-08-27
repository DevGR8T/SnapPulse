import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:snap_pulse/pages/commentpage.dart';
import 'package:snap_pulse/pages/homepage.dart';
import 'package:snap_pulse/pages/loginpage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snap_pulse/pages/postreadypage.dart';
import 'package:snap_pulse/pages/profile_editpage.dart';
import 'package:snap_pulse/pages/rootpage.dart';
import 'package:snap_pulse/pages/signuppage.dart';

// Main function to initialize Firebase and run the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with specific options
  await Firebase.initializeApp(
    options: FirebaseOptions(
        apiKey: 'AIzaSyDMW3Esrkr3L2qnLXk2qwA9AxvvOV1uKOU',
        appId: '1:448267594220:android:ed24b2da259e643a3a38c9',
        messagingSenderId: '448267594220',
        projectId: 'snappulse-4d764',
        storageBucket: 'gs://snappulse-4d764.appspot.com'),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Custom page route builder for transitions
  PageRouteBuilder<dynamic> customPageRouteBuilder(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      // Route generator for handling navigation
      onGenerateRoute: (RouteSettings settings) {
        Widget page;
        switch (settings.name) {
          case '/loginpage':
            page = LoginPage();
            break;
          case '/signup':
            page = SignUpPage();
            break;
          case '/profileEditpage':
            page = ProfileEditpage();
            break;
          case '/rootpage':
            page = RootPage();
            break;
          case '/homepage':
            page = HomePage();
            break;
          case '/commentpage':
            // Handle comment page navigation with postId
            if (settings.arguments != null && settings.arguments is String) {
              page = CommentPage(postId: settings.arguments as String);
            } else {
              page = RootPage();
            }
            break;
          case '/postreadypage':
            // Handle post ready page navigation with selected image
            if (settings.arguments != null && settings.arguments is File) {
              page = PostReadyPage(selectedImage: settings.arguments as File);
            } else {
              page = RootPage();
            }
            break;
          default:
            page = RootPage();
        }

        return customPageRouteBuilder(page);
      },
      // Theme configuration for the app
      theme: ThemeData(
          textTheme: GoogleFonts.aDLaMDisplayTextTheme(),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(color: Colors.white),
          bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: Colors.white, shape: RoundedRectangleBorder()),
          snackBarTheme: SnackBarThemeData(
              contentTextStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold))),
      home: LoginPage(),
    );
  }
}
