import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:snap_pulse/services/authservices.dart';

class SigningOut {
  //METHOD TO SHOW SIGN OUT CONFIRMATION DIALOG

  static void showSignOutDialog(BuildContext context) {
    print("Showing sign out dialog");
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        title: Text('Confirm Sign Out'),
        content: Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _performSignOut(context);
            },
            child: Text('Sign Out'),
          ),
        ],
      ),
    );
  }

//METHOD TO PERFOM THE SIGN OUT PROCESS
  static void _performSignOut(BuildContext context) {
    print("Starting sign out process");
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext loadingContext) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
            child: CircularProgressIndicator(
          backgroundColor: Colors.white,
        )),
      ),
    );

    // Perform sign out with a minimum duration
    Future.wait([
      Authservices().signOut(),
      Future.delayed(
          Duration(seconds: 2)), // Ensure loading shows for at least 2 seconds
    ]).then((_) {
      print("Sign out successful");
      _completeSignOut(context, true);
    }).catchError((error) {
      print("Error during sign out: $error");
      _completeSignOut(context, false);
    });
  }

  static void _completeSignOut(BuildContext context, bool success) {
    print("Completing sign out process");
    // DISMISS LOADING DIALOG
    Navigator.of(context, rootNavigator: true).pop();

    // Navigate to login page
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/loginpage', (route) => false);

    // SHOW TOAST
    String message =
        success ? 'Successfully signed out!' : 'Failed to sign out!';
    IconData icon = success ? Icons.check : Icons.error;
    Color color = success ? Colors.purple[500]! : Colors.red[500]!;
    _showToast(context, message, icon, color);
  }

  static void _showToast(
      BuildContext context, String message, IconData icon, Color color) {
    print("Showing toast: $message");
    DelightToastBar(
      snackbarDuration: Duration(seconds: 2),
      autoDismiss: true,
      position: DelightSnackbarPosition.top,
      builder: (context) => ToastCard(
        title: Text(message, style: TextStyle(color: Colors.white)),
        leading: Icon(icon, color: Colors.white),
        color: color,
      ),
    ).show(context);
  }
}
