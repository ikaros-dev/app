
import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart' as FlToast;

// class MessageUtils {
//   static void showToast(String message) {
//     if (Platform.isIOS || Platform.isAndroid) {
//       FlToast.Fluttertoast.showToast(
//           msg: message,
//           toastLength: FlToast.Toast.LENGTH_SHORT,
//           gravity: FlToast.ToastGravity.CENTER,
//           timeInSecForIosWeb: 5,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//           fontSize: 16.0);
//       return;
//     }
//
//     return;
//   }
// }

class Toast {
  static void show(BuildContext context, String message,
      {Duration duration = const Duration(seconds: 2)}) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.8,
        left: MediaQuery.of(context).size.width * 0.1,
        width: MediaQuery.of(context).size.width * 0.8,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }
}