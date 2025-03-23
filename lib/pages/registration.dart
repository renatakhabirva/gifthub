import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:gifthub/pages/mainpages.dart';
import 'package:gifthub/pages/messages.dart';

class Registration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RegistrationForm(),
    );
  }
}

class RegistrationForm extends StatefulWidget {
  @override
  RegistrationFormState createState() => RegistrationFormState();
}

class RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  bool _passwordVisible = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();

  int? _selectedCity;
  List<Map<String, dynamic>> _cities = [];

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    final response = await Supabase.instance.client.from('City').select('CityID, City');
    if (response != null) {
      setState(() {
        _cities = List<Map<String, dynamic>>.from(response);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _birthdayController.text = pickedDate.toIso8601String().split('T')[0];
      });
    }
  }
  bool isValidPassword(String password) {
    return RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{6,}$').hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Регистрация')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(labelText: "Отображаемое имя"),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите отображаемое имя';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: "Номер телефона"),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите номер телефона';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible, // Меняет видимость пароля
                decoration: InputDecoration(
                  labelText: "Пароль",
                  suffixIcon: IconButton(
                    icon: Icon(_passwordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible; // Переключение состояния
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите пароль';
                  }
                  if (!isValidPassword(value)) {
                    return 'Пароль должен содержать заглавную, строчную буквы и цифру';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Имя"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _surnameController,
                decoration: InputDecoration(labelText: "Фамилия"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите фамилию';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: "Город"),
                value: _selectedCity,
                items: _cities.map((city) {
                  return DropdownMenuItem<int>(
                    value: city["CityID"],
                    child: Text(city["City"]),
                  );
                }).toList(),
                onChanged: (int? value) {
                  setState(() {
                    _selectedCity = value;
                  });
                },
                validator: (value) => value == null ? "Выберите город" : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _birthdayController,
                decoration: InputDecoration(labelText: "Дата рождения"),
                keyboardType: TextInputType.datetime,
                onTap: () => _selectDate(context),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text("Зарегистрироваться"),
                onPressed: _signUp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Регистрация..v.")),
    );

    final supabase = Supabase.instance.client;

    final String displayName = _displayNameController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text;
    final String name = _nameController.text.trim();
    final String surname = _surnameController.text.trim();
    final String birthday = _birthdayController.text.trim();
    final int? city = _selectedCity;

    try {
      print("Начало регистрации...");

      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print("Пользователь зарегистрирован: ${response.user!.id}");

        await supabase.auth.updateUser(UserAttributes(
          data: {
            "display_name": displayName,
            "phone": phone,
            "role": "Client",
          },
        ));

        await supabase.from("Client").insert({
          "ClientID": response.user!.id,
          "ClientSurName": surname,
          "ClientName": name,
          "ClientCity": city,
          "ClientBirthday": birthday.isNotEmpty ? birthday : null,
        });


        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Регистрация успешна!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NavigationExample()),
        );
      }
    } on AuthException catch (e) {
      print("Ошибка регистрации: ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка: ${e.message}")),
      );
    }
  }
}
