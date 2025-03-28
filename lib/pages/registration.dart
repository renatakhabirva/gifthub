import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:gifthub/pages/mainpages.dart';
import 'package:gifthub/pages/messages.dart';

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
  bool _passwordVisible = false; // Флаг для отображения пароля

  // Контроллеры полей формы
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

  /// Загрузка городов из таблицы City
  Future<void> _loadCities() async {
    final response = await Supabase.instance.client
        .from('City')
        .select('CityID, City');
    if (response != null) {
      setState(() {
        _cities = List<Map<String, dynamic>>.from(response);
      });
    }
  }

  /// Выбор даты через календарь
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
              // Display Name
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(labelText: "Отображаемое имя"),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? "Введите отображаемое имя"
                            : null,
              ),
              SizedBox(height: 12),
              // Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return MessagesRu.emailOrPhoneRequired;
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                    return "Некорректный email";
                  return null;
                },
              ),
              SizedBox(height: 12),
              // Телефон
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: "Номер телефона"),
                keyboardType: TextInputType.phone,
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? "Введите номер телефона"
                            : null,
              ),
              SizedBox(height: 12),
              // Пароль
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible, // Меняет видимость пароля
                decoration: InputDecoration(
                  labelText: "Пароль",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible =
                            !_passwordVisible; // Переключение состояния
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: 12),
              // Имя
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Имя"),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? "Введите имя"
                            : null,
              ),
              SizedBox(height: 12),
              // Фамилия
              TextFormField(
                controller: _surnameController,
                decoration: InputDecoration(labelText: "Фамилия"),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? "Введите фамилию"
                            : null,
              ),
              SizedBox(height: 12),
              // Город
              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: "Город"),
                value: _selectedCity,
                items:
                    _cities.map((city) {
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
              // Дата рождения
              TextFormField(
                controller: _birthdayController,
                decoration: InputDecoration(
                  labelText: "Дата рождения (необязательно)",
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Кнопка регистрации
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

  /// Регистрация пользователя
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
        data: {"display_name": displayName, "role": "Client"},
      );

      if (response.user != null) {
        await supabase.from("Client").insert({
          "ClientID": response.user!.id,
          "ClientSurName": surname,
          "ClientName": name,
          "ClientCity": city,
          "ClientBirthday": birthday.isNotEmpty ? birthday : null,
          "ClientPhone": phone
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(MessagesRu.registration)),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NavigationExample()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${MessagesRu.registrationError}: $e")),
      );
    }
  }
}
