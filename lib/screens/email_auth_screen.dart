import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
    bool showPassword = false;
    bool showConfirmPassword = false;
    bool isLogin = true;
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;

  Future<void> signUp() async {
    if (passwordController.text !=
    confirmPasswordController.text) {

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Passwords do not match"),
    ),
  );

  return;
}
    try {
      setState(() => isLoading = true);

      UserCredential userCredential =
    await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: emailController.text.trim(),
  password: passwordController.text.trim(),
);

User? user = userCredential.user;

await FirebaseFirestore.instance
    .collection('users')
    .doc(user!.uid)
    .set({
  'name': nameController.text.trim(),
  'email': user.email,
  'loginMethod': 'email',
  'createdAt': Timestamp.now(),
});
print("USER SAVED TO FIRESTORE");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> login() async {
    try {
      setState(() => isLoading = true);

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => isLoading = false);
  }
  Future<void> resetPassword() async {
  if (emailController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please enter your email first"),
      ),
    );
    return;
  }

  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: emailController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Password reset email sent"),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString()),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Email Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!isLogin) ...[
  TextField(
    controller: nameController,
    decoration: const InputDecoration(
      labelText: "Full Name",
    ),
  ),
  const SizedBox(height: 20),
],
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),
            const SizedBox(height: 20),
            TextField(
  controller: passwordController,
  obscureText: !showPassword,
  decoration: InputDecoration(
    labelText: "Password",
    suffixIcon: IconButton(
      icon: Icon(
        showPassword
            ? Icons.visibility_off
            : Icons.visibility,
      ),
      onPressed: () {
        setState(() {
          showPassword = !showPassword;
        });
      },
    ),
  ),
),
if (!isLogin) ...[
const SizedBox(height: 20),

TextField(
  controller: confirmPasswordController,
  obscureText: !showConfirmPassword,
  decoration: InputDecoration(
    labelText: "Confirm Password",
    suffixIcon: IconButton(
      icon: Icon(
        showConfirmPassword
            ? Icons.visibility_off
            : Icons.visibility,
      ),
      onPressed: () {
        setState(() {
          showConfirmPassword = !showConfirmPassword;
        });
      },
    ),
  ),
),
],
            const SizedBox(height: 30),
            if (isLogin)
  Align(
    alignment: Alignment.centerRight,
    child: TextButton(
      onPressed: resetPassword,
      child: const Text("Forgot Password?"),
    ),
  ),

            if (isLoading)
              const CircularProgressIndicator(),

            if (!isLoading)
  Column(
    children: [

      ElevatedButton(
        onPressed: isLogin ? login : signUp,
        child: Text(
          isLogin ? "Login" : "Create Account",
        ),
      ),

      const SizedBox(height: 15),

      TextButton(
        onPressed: () {
          setState(() {
            isLogin = !isLogin;
          });
        },
        child: Text(
          isLogin
              ? "Don't have an account? Sign Up"
              : "Already have an account? Login",
        ),
      ),
    ],
  ),
          ],
        ),
      ),
    );
  }
}