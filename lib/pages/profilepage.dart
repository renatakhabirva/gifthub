import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gifthub/pages/mainpages.dart';
import '../themes/colors.dart';
import '../services/messages.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _birthdayController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _passwordError;

  List<Map<String, dynamic>> _cities = [];
  int? _selectedCity;

  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCities();
    _loadUserEmail();
  }

  Future<void> _loadUserData() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final response = await Supabase.instance.client
        .from('Client')
        .select('*')
        .eq('ClientID', userId)
        .single();

    setState(() {
      _nameController.text = response['ClientName'] ?? '';
      _surnameController.text = response['ClientSurName'] ?? '';
      _phoneController.text = response['ClientPhone'] ?? '';
      _selectedCity = response['ClientCity'];
      _birthdayController.text = response['ClientBirthday'] ?? '';

      _displayNameController.text = response['ClientDisplayname'] ?? '';
    });
  }

  Future<void> _loadUserEmail() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _userEmail = user.email;
        _emailController.text = _userEmail ?? '';
      });
    }
  }

  Future<void> _loadCities() async {
    final response =
        await Supabase.instance.client.from('City').select('CityID, City');
    if (response != null) {
      setState(() {
        _cities = List<Map<String, dynamic>>.from(response);
      });
    }
  }

  Future<void> _updateUserData() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client.from('Client').update({
        'ClientName': _nameController.text,
        'ClientSurName': _surnameController.text,
        'ClientPhone': _phoneController.text,
        'ClientCity': _selectedCity,
        'ClientBirthday': _birthdayController.text.isNotEmpty
            ? _birthdayController.text
            : null,
      }).eq('ClientID', userId);

      //  изменился ли email
      final currentEmail = Supabase.instance.client.auth.currentUser?.email;
      final newEmail = _emailController.text.trim();

      if (newEmail.isNotEmpty && newEmail != currentEmail) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(email: newEmail),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${MessagesRu.updateEmail} $newEmail')),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Данные успешно обновлены')),
      );
    } catch (e) {
      String errorMessage = MessagesRu.registrationError;
      if (e.toString().contains('User already registered')) {
        errorMessage = MessagesRu.emailExists;
      } else if (e.toString().contains('Client_ClientPhone_key')) {
        errorMessage = MessagesRu.phoneExists;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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
      appBar: AppBar(
        title: Text('Профиль'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Раздел "Личные данные"
              _buildSectionHeader('Личные данные'),

              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(labelText: 'Никнейм'),
                enabled: false,
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '${MessagesRu.fieldRequired}';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return '${MessagesRu.invalidEmail}';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Имя'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? '${MessagesRu.fieldRequired}'
                    : null,
              ),
              SizedBox(height: 12),

              TextFormField(
                controller: _surnameController,
                decoration: InputDecoration(labelText: 'Фамилия'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? '${MessagesRu.fieldRequired}'
                    : null,
              ),
              SizedBox(height: 12),

              DropdownButtonFormField<int>(
                decoration: InputDecoration(labelText: 'Город'),
                value: _selectedCity,
                items: _cities.map((city) {
                  return DropdownMenuItem<int>(
                    value: city['CityID'],
                    child: Text(city['City']),
                  );
                }).toList(),
                onChanged: (int? value) {
                  setState(() {
                    _selectedCity = value;
                  });
                },
                validator: (value) =>
                    value == null ? MessagesRu.fieldRequired : null,
                dropdownColor: lightGrey,
                style: TextStyle(
                  color: darkGreen,
                  fontFamily: 'segoeui',
                  fontSize: 16,
                ),
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
                  }),
              SizedBox(height: 12),

              TextFormField(
                controller: _birthdayController,
                decoration: InputDecoration(
                  labelText: 'Дата рождения',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context),
                  ),
                ),
                readOnly: true,
              ),
              SizedBox(height: 12),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: _updateUserData,
                icon: Icon(Icons.save),
                label: Text('Сохранить изменения'),
              ),

              SizedBox(height: 20),

              // Раздел "Действия"
              _buildSectionHeader('Действия'),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: wishListIcon,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () async {
                  final bool? confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      content: const Text('Вы уверены, что хотите выйти?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Отмена'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Выйти'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed ?? false) {
                    try {
                      await Supabase.instance.client.auth.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => NavigationExample()),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ошибка при выходе')),
                      );
                    }
                  }
                },
                icon: Icon(Icons.logout),
                label: Text('Выйти из аккаунта'),
              ),
              SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: wishListIcon,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onPressed: () async {
                  final user = Supabase.instance.client.auth.currentUser;
                  if (user == null) return;

                  //контроллер для пароля
                  final passwordController = TextEditingController();

                  showDialog(
                    context: context,
                    builder: (BuildContext context) => StatefulBuilder(
                      builder: (context, setState) => AlertDialog(
                        title: const Text('Подтвердите удаление аккаунта'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Введите пароль для подтверждения:'),
                            TextFormField(
                              controller: passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Пароль',
                                errorText: _passwordError,
                              ),
                              onChanged: (value) {
                                if (_passwordError != null) {
                                  setState(() {
                                    _passwordError = null;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Отмена'),
                            style: ButtonStyle(
                                foregroundColor:
                                    MaterialStateProperty.all<Color>(
                                        darkGreen)),
                          ),
                          TextButton(
                            onPressed: () async {
                              final password = passwordController.text.trim();
                              if (password.isEmpty) {
                                setState(() {
                                  _passwordError = 'Введите пароль';
                                });
                                return;
                              }
                              try {
                                final response = await Supabase
                                    .instance.client.auth
                                    .signInWithPassword(
                                        email: user.email!, password: password);

                                if (response.user == null) {
                                  throw 'invalid_password';
                                }

                                await Supabase.instance.client
                                    .rpc('delete_current_user');
                                await Supabase.instance.client.auth.signOut();

                                Navigator.of(context).pop();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(MessagesRu.deleteProfile)),
                                );

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          NavigationExample()),
                                );
                              } catch (e) {
                                if (e.toString() == 'invalid_password' ||
                                    e.toString().contains(
                                        'Invalid login credentials')) {
                                  setState(() {
                                    _passwordError = 'Неверный пароль';
                                  });
                                  return;
                                }

                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text(MessagesRu.errorDeleteProfile)),
                                );
                              }
                            },
                            child: Text(
                              'Удалить',
                              style: TextStyle(
                                fontFamily: 'segoeui',
                                color: wishListIcon,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.delete_forever),
                label: Text('Удалить аккаунт'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
