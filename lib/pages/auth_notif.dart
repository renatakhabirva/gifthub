import 'package:flutter/material.dart';
import 'package:gifthub/themes/colors.dart';


class AuthNotif extends StatelessWidget {
  final VoidCallback onLoginPressed;
  final VoidCallback onRegistrationPressed;

  const AuthNotif({
    super.key,
    required this.onLoginPressed,
    required this.onRegistrationPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: onLoginPressed,
            child: Text("Войти", style: TextStyle(fontFamily: "segoeui")),
          ),
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: TextButton(
              onPressed: onRegistrationPressed,
              child: Text("Зарегистрироваться", style: TextStyle(color: darkGreen)),
            ),
          ),
        ],
      ),
    );
  }
}