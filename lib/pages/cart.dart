import 'package:flutter/material.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:gifthub/pages/auth.dart';

class CartPage extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Padding(
              padding: EdgeInsets.only(top: 10),
              child: TextButton(
                onPressed: () {},
                child: Text("Зарегистрироваться", style: TextStyle(color: darkGreen)),
              ),
            ),
          ],
        ));
  }
}
