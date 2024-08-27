import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snap_pulse/pages/addpostpage.dart';
import 'package:snap_pulse/pages/homepage.dart';
import 'package:snap_pulse/pages/profilepage.dart';


// Root page widget that manages the main navigation structure
class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  // Index of the currently selected navigation item
  int _selecteditem = 0;

  // List of pages corresponding to each navigation item
  List<Widget> pages = [
    HomePage(),
    AddPostPage(),
    ProfilePage(),
  ];

  // Function to handle back button press and app exit
  Future<bool> _onWillPop(BuildContext context) async {
    // If the currently selected item is the homepage (index 0)
    if (_selecteditem == 0) {
      // Show a dialog asking if the user wants to exit the app
      return (await showDialog(
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
          )) ??
          false; // If the dialog is dismissed by tapping outside, default to false
    } else {
      // If the currently selected item is not the homepage, go to the homepage
      setState(() {
        _selecteditem = 0;
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) {
          return;
        }
        final shouldpop = await _onWillPop(context);
        if (shouldpop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        // Display the currently selected page
        body: pages[_selecteditem],
        // Bottom navigation bar
        bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selecteditem,
            onTap: (tapped) {
              setState(() {
                _selecteditem = tapped;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            items: [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
              BottomNavigationBarItem(
                  icon: Icon(Icons.add_circle_outline), label: ''),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline), label: ''),
            ]),
      ),
    );
  }
}
