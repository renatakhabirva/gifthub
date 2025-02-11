import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'package:gifthub/themes/primarytheme.dart';
import 'package:gifthub/themes/colors.dart';



class GiftHub extends StatelessWidget {
  const GiftHub({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: primTheme(),
      home: Scaffold(
        body: const AuthorizationForm(),
      ),
    );
  }
}

class AuthorizationForm extends StatefulWidget {
  const AuthorizationForm({super.key});

  @override
  AuthorizationFormState createState() {
    return AuthorizationFormState();
  }
}

class AuthorizationFormState extends State<AuthorizationForm> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(

        key: _formKey,
        child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new Container(
                  alignment: Alignment.center,
                  padding: new EdgeInsets.only(top: 130),
                  child: Text(
                    "GIFTHUB",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: buttonGreen, fontSize: 72, fontFamily: "plantype"),
                  ),),
                new Container(
                  padding: new EdgeInsets.only(top: 100),
                  width: 345.0,
                  child: new TextFormField(
                    decoration: new InputDecoration(labelText: "Email",
                    ),

                    style: TextStyle(fontSize: 24),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите электронную почту';
                      }
                      return null;
                    },
                  ),
                ),
                new Container(
                  padding: new EdgeInsets.only(top: 40),
                  width: 345,

                  child: TextFormField(
                    obscureText: true,
                    decoration: new InputDecoration(
                      labelText: "Пароль",

                    ),
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(fontSize: 24),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите пароль';
                      }
                      return null;
                    },
                  ),),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: ElevatedButton(
                    onPressed: () {
                      // Validate returns true if the form is valid, or false otherwise.
                      if (_formKey.currentState!.validate()) {
                        // If the form is valid, display a snackbar. In the real world,
                        // you'd often call a server or save the information in a database.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Processing Data')),
                        );
                      }
                    },
                    child: const Text('Submit'),
                  ),
                ),
              ],
            )));
  }
}
