import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gifthub/pages/mainpages.dart';
import 'package:gifthub/services/messages.dart';

class Registration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: RegistrationForm());
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
    final response = await Supabase.instance.client.from('City').select(
        'CityID, City');
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
                decoration: InputDecoration(labelText: "Никнейм"),
                validator: (value) {
                  if (value == null || value
                      .trim()
                      .isEmpty) return MessagesRu.fieldRequired;
                  if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value))
                    return MessagesRu.displayNameFormatError;
                  return null;
                },
              ),

              SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@._+-]')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return MessagesRu.emailOrPhoneRequired;
                  }
                  if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                    return MessagesRu.invalidEmail;
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: "Номер телефона"),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[+\d]')),
                ],
                maxLength: 12,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return MessagesRu.fieldRequired;
                  }
                  if (value.length < 11) {
                    return 'Минимальная длина номера - 11 символов';
                  }
                  if (value.length > 12) {
                    return 'Максимальная длина номера - 12 символов';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: "Пароль",
                  suffixIcon: IconButton(
                    icon: Icon(_passwordVisible ? Icons.visibility : Icons
                        .visibility_off),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return MessagesRu.fieldRequired;
                  if (value.length < 8 ||
                      !RegExp(r'(?=.*[A-Z])').hasMatch(value) ||
                      !RegExp(r'(?=.*[a-z])').hasMatch(value) ||
                      !RegExp(r'(?=.*\d)').hasMatch(value)) {
                    return MessagesRu.passwordTooWeak;
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Имя"),
                validator: (value) =>
                value == null || value
                    .trim()
                    .isEmpty ? MessagesRu.fieldRequired : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _surnameController,
                decoration: InputDecoration(labelText: "Фамилия"),
                validator: (value) =>
                value == null || value
                    .trim()
                    .isEmpty ? MessagesRu.fieldRequired : null,
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  labelText: "Город",

                ),
                value: _selectedCity,
                items: _cities.map((city) {
                  return DropdownMenuItem<int>(
                    value: city["CityID"],
                    child: Text(
                      city["City"],

                    ),
                  );
                }).toList(),
                onChanged: (int? value) {
                  setState(() {
                    _selectedCity = value;
                  });
                },
                validator: (value) => value == null ? MessagesRu.fieldRequired : null,
                dropdownColor: lightGrey,
                style: TextStyle(
                  color: darkGreen,
                  fontFamily: 'segoeui',
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _birthdayController,
                decoration: InputDecoration(
                  labelText: "Дата рождения (необязательно)",
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),

                validator: (value) {
                  if (value != null && value.isNotEmpty &&
                      !RegExp(r'^[\d.\-]+$').hasMatch(value)) {
                    return MessagesRu.invalidBirthday;
                  }
                  return null;
                },
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


  ///Регистрация пользователя
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(MessagesRu.loading)),
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

      final AuthResponse response = await supabase.auth.signUp(
        email: email,
        password: password,

        data: {"display_name": displayName, "role": "Client", },
      );

      if (response.user != null) {
        final userId = response.user!.id;
        print('Создан пользователь с ID: $userId');


        await supabase.from("Client").insert({
          "ClientID": userId,
          "ClientSurName": surname,
          "ClientName": name,
          "ClientCity": city,
          "ClientBirthday": birthday.isNotEmpty ? birthday : null,
          "ClientPhone": phone,
          "ClientDisplayname": displayName
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(MessagesRu.registration)),
        );
        Navigator.pushNamed(
            context,
            '/main'
        );
      }
    } catch (e) {
      print('Ошибка регистрации: $e');
      String errorMessage = MessagesRu.registrationError;

      if (e.toString().contains('User already registered')) {
        errorMessage = MessagesRu.emailExists;
      } else if (e.toString().contains('Client_ClientPhone_key')) {
        errorMessage = MessagesRu.phoneExists;
        await Supabase.instance.client.rpc('delete_current_user');
      } else {
        errorMessage = MessagesRu.displayNameExists;
      }


      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.auth.admin.deleteUser(user.id);
        print('Удалён пользователь с ID: ${user.id}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }
}