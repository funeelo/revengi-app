import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:revengi/dio.dart';
import 'package:revengi/screens/home.dart';
import 'package:revengi/platform.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isLoading = false;
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await dio.post(
          _isLogin ? '/login' : '/register',
          data:
              _isLogin
                  ? {
                    'username': _usernameController.text,
                    'password': _passwordController.text,
                  }
                  : {
                    'username': _usernameController.text,
                    'email': _emailController.text,
                    'password': _passwordController.text,
                    'confirm_password': _confirmPasswordController.text,
                  },
        );

        if (mounted) {
          // Save user session data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('username', _usernameController.text);

          final apiKey = response.data['api_key'];
          if (apiKey != null) {
            await prefs.setString('apiKey', apiKey);
            dio.options.headers['X-API-Key'] = apiKey;
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${_isLogin ? 'Login' : 'Registration'} successful',
                ),
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        }
      } on DioException catch (e) {
        String errorMessage = 'An error occurred';
        if (e.response?.data != null && e.response?.data['detail'] != null) {
          errorMessage = e.response?.data['detail'];
        } else if (e.type == DioExceptionType.connectionTimeout) {
          errorMessage = 'Connection timeout';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'No internet connection';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color:
          Theme.of(context).brightness == Brightness.dark
              ? const Color.fromARGB(87, 18, 18, 18)
              : const Color.fromARGB(177, 245, 245, 245),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isLogin ? 'Welcome Back!' : 'Create Account',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter username';
                  }
                  if (value.length < 5 || value.length > 15) {
                    return 'Username must be between 5 and 15 characters';
                  }
                  return null;
                },
              ),
              if (!_isLogin) const SizedBox(height: 16),
              if (!_isLogin)
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    if (!RegExp(
                      r'^[a-zA-Z0-9\.]+@gmail\.com$',
                    ).hasMatch(value)) {
                      return 'Please enter a valid Gmail address';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              if (!_isLogin) const SizedBox(height: 16),
              if (!_isLogin)
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? const Color.fromARGB(37, 18, 18, 18)
                            : const Color.fromARGB(177, 245, 245, 245),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Text(
                            _isLogin ? 'Login' : 'Register',
                            style: const TextStyle(fontSize: 16),
                          ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                child: Text(
                  _isLogin
                      ? 'Need an account? Register'
                      : 'Have an account? Login',
                  style: TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed:
                    _isLoading
                        ? null
                        : () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isLoggedIn', true);
                          await prefs.setString('username', 'guest');

                          if (mounted) {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const DashboardScreen(),
                              ),
                            );
                          }
                        },
                child: const Text(
                  'Continue as Guest',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF121212), const Color(0xFFF5F5F5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child:
                    isWeb()
                        ? Center(child: SizedBox(width: 400, child: card))
                        : isWindows()
                        ? Center(child: SizedBox(width: 400, child: card))
                        : isLinux()
                        ? Center(child: SizedBox(width: 400, child: card))
                        : card,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
