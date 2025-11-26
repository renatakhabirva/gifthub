import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:gifthub/services/messages.dart';
import 'package:gifthub/pages/mainpages.dart';

void AuthorizationMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey:
        dotenv.env['SUPABASE_ANON_KEY']!,
  );
}

class Authorization extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthorizationForm(),
    );
  }
}

class AuthorizationForm extends StatefulWidget {

  @override
  AuthorizationFormState createState() => AuthorizationFormState();
}

class AuthorizationFormState extends State<AuthorizationForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AppBar(
              title: Text('Авторизация'),
            ),

            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.only(top: 130, bottom: 100),
              child: Text(
                "GIFTHUB",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: buttonGreen,
                  fontSize: 72,
                  fontFamily: "plantype",
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.only(bottom: 30),
              width: 345,
              child: TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",

                ),
                validator: (value) => value == null || value.isEmpty
                    ? MessagesRu.emailOrPhoneRequired
                    : null,
              ),
            ),

            Container(
              padding: EdgeInsets.only(bottom: 30),
              width: 345,
              child: TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Пароль",

                ),

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите пароль';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final response = await Supabase.instance.client.auth.signInWithPassword(
                        email: _emailController.text.contains('@')
                            ? _emailController.text
                            : null,
                        password: _passwordController.text,
                      );

                      if (response.user != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(MessagesRu.loginSuccess)),
                        );
                        Navigator.pushNamed(
                          context,
                          '/main',
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(MessagesRu.invalidCredentials)),
                        );
                      }
                    } catch (e) {
                      if (e is AuthException) {
                        String errorMessage = MessagesRu.invalidCredentials;
                        if (e.message.contains('not found')) {
                          errorMessage = MessagesRu.userNotFound;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMessage)),
                        );
                      }
                    }
                  }
                },
                child: const Text('Войти'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


