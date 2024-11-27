import 'package:avaguard/resources/auth_methods.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool emailError = false;
  bool passwordError = false;
  bool isLoading = false;
  String? errorMessage;

  SharedPreferences? prefs;

  showSnackBar(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
      ),
    );
  }

  void _onLogin() async {
    try {
      final email = _emailController.text;
      final password = _passwordController.text;

      final isEmailValid =
          RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
      final isPasswordValid = password.isNotEmpty;

      setState(() {
        emailError = !isEmailValid;
        passwordError = !isPasswordValid;
      });

      if (isEmailValid && isPasswordValid) {
        setState(() {
          isLoading = true;
        });

        await AuthMethods.loginUser(
          email: email,
          password: password,
          prefs: prefs!,
          showSnackBar: showSnackBar,
          context: context,
        );
      } else {
        setState(() {
          errorMessage = "Por favor, corrija os erros antes de continuar.";
        });
      }
    } catch (e) {
      print(e);
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    initSharedPref();
  }

  void initSharedPref() async {
    prefs = await SharedPreferences.getInstance();
  }

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 125),
              Center(
                child: Image.asset(
                  'assets/logo_avaguard.png',
                ),
              ),
              SizedBox(height: 125),

              // Campo de Email
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Digite o seu email",
                  prefixIcon: Icon(Icons.person, color: Color(0xFF5360F5)),
                  errorText: emailError ? "Email inválido" : null,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 16),

              // Campo de Senha
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Digite a sua senha",
                  prefixIcon: Icon(Icons.lock, color: Color(0xFF5360F5)),
                  errorText:
                      passwordError ? "A senha não pode estar vazia" : null,
                  border: OutlineInputBorder(),
                  suffixIcon:
                      Icon(Icons.remove_red_eye, color: Color(0xFF5360F5)),
                ),
              ),
              SizedBox(height: 16),

              // Mensagem de erro
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),

              SizedBox(height: 125),

              // Botão de Login
              Center(
                child: ElevatedButton(
                  onPressed: isLoading ? null : _onLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5360F5),
                    fixedSize: Size(200, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Entrar"),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_right_alt, color: Colors.white),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
