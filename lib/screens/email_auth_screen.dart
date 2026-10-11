import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

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
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;

  // ============================================================
  // EMAIL SIGN UP
  // ============================================================

  Future<void> signUp() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // Name validation
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your full name"),
        ),
      );
      return;
    }

    // Phone validation
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a valid 10-digit mobile number",
          ),
        ),
      );
      return;
    }

    // Email validation
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your email"),
        ),
      );
      return;
    }

    // Password validation
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your password"),
        ),
      );
      return;
    }

    // Confirm password validation
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
      setState(() {
        isLoading = true;
      });

      // ----------------------------------------------------------
      // 1. Create Email/Password Firebase account
      // ----------------------------------------------------------

      final UserCredential userCredential =
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception(
          "Account could not be created.",
        );
      }

      // ----------------------------------------------------------
      // 2. Send OTP to mobile number
      // ----------------------------------------------------------

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91$phone",

        // --------------------------------------------------------
        // Android automatic verification
        // --------------------------------------------------------

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          try {
            await user.linkWithCredential(
              credential,
            );

            final currentUser =
                FirebaseAuth.instance.currentUser;

            if (currentUser == null) {
              throw Exception(
                "User session was lost.",
              );
            }

            await _completeEmailSignup(
              user: currentUser,
              name: name,
              phone: phone,
            );
          } on FirebaseAuthException catch (e) {
            if (!mounted) return;

            setState(() {
              isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e.message ??
                      "Phone verification failed.",
                ),
              ),
            );
          } catch (e) {
            if (!mounted) return;

            setState(() {
              isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Phone verification failed: $e",
                ),
              ),
            );
          }
        },

        // --------------------------------------------------------
        // OTP sending failed
        // --------------------------------------------------------

        verificationFailed:
            (FirebaseAuthException e) {
          if (!mounted) return;

          setState(() {
            isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.message ??
                    "Failed to send OTP.",
              ),
            ),
          );
        },

        // --------------------------------------------------------
        // OTP sent successfully
        // --------------------------------------------------------

        codeSent: (
          String verificationId,
          int? resendToken,
        ) async {
          if (!mounted) return;

          setState(() {
            isLoading = false;
          });

          // Show OTP dialog
          final otp = await _showOtpDialog();

          // User cancelled OTP dialog
          if (otp == null) {
            return;
          }

          // OTP length validation
          if (otp.length != 6) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Please enter a valid 6-digit OTP.",
                ),
              ),
            );

            return;
          }

          if (!mounted) return;

          setState(() {
            isLoading = true;
          });

          try {
            // ----------------------------------------------------
            // Create phone credential
            // ----------------------------------------------------

            final credential =
                PhoneAuthProvider.credential(
              verificationId: verificationId,
              smsCode: otp,
            );

            // ----------------------------------------------------
            // Link verified phone to email account
            // ----------------------------------------------------

            await user.linkWithCredential(
              credential,
            );

            final currentUser =
                FirebaseAuth.instance.currentUser;

            if (currentUser == null) {
              throw Exception(
                "User session was lost.",
              );
            }

            // ----------------------------------------------------
            // Save user to Firestore
            // ----------------------------------------------------

            await _completeEmailSignup(
              user: currentUser,
              name: name,
              phone: phone,
            );
          } on FirebaseAuthException catch (e) {
            if (!mounted) return;

            setState(() {
              isLoading = false;
            });

            String message =
                "Invalid OTP. Please try again.";

            if (e.code ==
                "credential-already-in-use") {
              message =
                  "This mobile number is already linked to another account.";
            } else if (e.code ==
                "invalid-verification-code") {
              message =
                  "Invalid OTP. Please enter the correct OTP.";
            } else if (e.code ==
                "session-expired") {
              message =
                  "OTP expired. Please request a new OTP.";
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
              ),
            );
          } catch (e) {
            if (!mounted) return;

            setState(() {
              isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e.toString(),
                ),
              ),
            );
          }
        },

        // --------------------------------------------------------
        // OTP auto retrieval timeout
        // --------------------------------------------------------

        codeAutoRetrievalTimeout:
            (String verificationId) {},
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? e.code,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }
  }

  // ============================================================
  // COMPLETE EMAIL SIGNUP AFTER OTP VERIFICATION
  // ============================================================

  Future<void> _completeEmailSignup({
    required User user,
    required String name,
    required String phone,
  }) async {
    String? token;

    if (!kIsWeb) {
      try {
        token =
            await FirebaseMessaging.instance.getToken();
      } catch (_) {
        token = null;
      }
    }

    // Save user data only AFTER phone OTP verification
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(
      {
        'name': name,
        'email': user.email ?? '',
        'phone': phone,
        'phoneVerified': true,
        'loginMethod': 'email',
        'createdAt': Timestamp.now(),
        'lastLogin': Timestamp.now(),
        if (token != null) 'fcmToken': token,
      },
      SetOptions(merge: true),
    );

    debugPrint(
      "EMAIL USER SAVED TO FIRESTORE AFTER OTP VERIFICATION",
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  // ============================================================
  // OTP DIALOG
  // ============================================================

  Future<String?> _showOtpDialog() async {
    final otpController =
        TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            "Verify Mobile Number",
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter the 6-digit OTP sent to your mobile number.",
              ),

              const SizedBox(height: 18),

              TextField(
                controller: otpController,
                keyboardType:
                    TextInputType.number,
                maxLength: 6,
                autofocus: true,
                decoration:
                    const InputDecoration(
                  labelText: "Enter OTP",
                  hintText: "6-digit OTP",
                  border:
                      OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                "Cancel",
              ),
            ),

            ElevatedButton(
              onPressed: () {
                final otp =
                    otpController.text.trim();

                if (otp.length != 6) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please enter 6-digit OTP.",
                      ),
                    ),
                  );

                  return;
                }

                Navigator.pop(
                  dialogContext,
                  otp,
                );
              },
              child: const Text(
                "Verify",
              ),
            ),
          ],
        );
      },
    );

    otpController.dispose();

    return result;
  }

  // ============================================================
  // EMAIL LOGIN
  // ============================================================

  Future<void> login() async {
    try {
      setState(() => isLoading = true);

      await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user =
          FirebaseAuth.instance.currentUser;

      String? token;

      if (!kIsWeb) {
        token =
            await FirebaseMessaging.instance.getToken();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'lastLogin': Timestamp.now(),
        'fcmToken': token,
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const HomeScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }

    setState(() => isLoading = false);
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<void> resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter your email first",
          ),
        ),
      );

      return;
    }

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Password reset email sent",
          ),
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

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: Colors.deepPurple,
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(
          color: Colors.deepPurple,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
        ),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide:
              BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.deepPurple
                .withOpacity(0.08),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide:
              const BorderSide(
            color: Colors.deepPurple,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PASSWORD FIELD
  // ============================================================

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool showPassword,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !showPassword,
      decoration: InputDecoration(
        labelText: label,
        hintText: "Enter your password",
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Colors.deepPurple,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            showPassword
                ? Icons.visibility_off
                : Icons.visibility,
            color: Colors.grey.shade600,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(
          color: Colors.deepPurple,
        ),
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
        ),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide:
              BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Colors.deepPurple
                .withOpacity(0.08),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(16),
          borderSide:
              const BorderSide(
            color: Colors.deepPurple,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F0FF),

      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF5F0FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          isLogin
              ? "Email Login"
              : "Create Account",
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
        centerTitle: false,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            24,
            10,
            24,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // ------------------------------------------------
              // LOGO
              // ------------------------------------------------

              Center(
                child: Container(
                  width: 78,
                  height: 78,
                  padding:
                      const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple
                            .withOpacity(0.12),
                        blurRadius: 18,
                        offset:
                            const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    "assets/images/logo.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // TITLE
              // ------------------------------------------------

              Center(
                child: Text(
                  isLogin
                      ? "Let’s Get You In 😋"
                      : "Join the Jamboo Family 🎉",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ------------------------------------------------
              // SUBTITLE
              // ------------------------------------------------

              Center(
                child: Text(
                  isLogin
                      ? "Sign in and get your favourite food\ndelivered to your door."
                      : "Create your account and start\nexploring delicious food.",
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------
              // SIGN UP FIELDS
              // ------------------------------------------------

              if (!isLogin) ...[
                _inputField(
                  controller:
                      nameController,
                  label: "Full Name",
                  hint:
                      "Enter your full name",
                  icon:
                      Icons.person_outline,
                  keyboardType:
                      TextInputType.name,
                ),

                const SizedBox(height: 16),

                _inputField(
                  controller:
                      phoneController,
                  label: "Phone Number",
                  hint:
                      "Enter your phone number",
                  icon:
                      Icons.phone_outlined,
                  keyboardType:
                      TextInputType.phone,
                ),

                const SizedBox(height: 16),
              ],

              // ------------------------------------------------
              // EMAIL
              // ------------------------------------------------

              _inputField(
                controller:
                    emailController,
                label: "Email Address",
                hint: "Enter your email",
                icon:
                    Icons.email_outlined,
                keyboardType:
                    TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // PASSWORD
              // ------------------------------------------------

              _passwordField(
                controller:
                    passwordController,
                label: "Password",
                showPassword:
                    showPassword,
                onToggle: () {
                  setState(() {
                    showPassword =
                        !showPassword;
                  });
                },
              ),

              // ------------------------------------------------
              // CONFIRM PASSWORD
              // ------------------------------------------------

              if (!isLogin) ...[
                const SizedBox(height: 16),

                _passwordField(
                  controller:
                      confirmPasswordController,
                  label:
                      "Confirm Password",
                  showPassword:
                      showConfirmPassword,
                  onToggle: () {
                    setState(() {
                      showConfirmPassword =
                          !showConfirmPassword;
                    });
                  },
                ),
              ],

              // ------------------------------------------------
              // FORGOT PASSWORD
              // ------------------------------------------------

              if (isLogin) ...[
                const SizedBox(height: 8),

                Align(
                  alignment:
                      Alignment.centerRight,
                  child: TextButton(
                    onPressed:
                        resetPassword,
                    style:
                        TextButton.styleFrom(
                      foregroundColor:
                          Colors.deepPurple,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 4,
                      ),
                    ),
                    child:
                        const Text(
                      "Forgot Password?",
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else
                const SizedBox(height: 20),

              // ------------------------------------------------
              // LOADING / BUTTON
              // ------------------------------------------------

              if (isLoading)
                const Center(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    child:
                        CircularProgressIndicator(
                      color:
                          Colors.deepPurple,
                    ),
                  ),
                )
              else ...[
                const SizedBox(height: 8),

                SizedBox(
                  width:
                      double.infinity,
                  height: 56,
                  child:
                      ElevatedButton(
                    onPressed:
                        isLogin
                            ? login
                            : signUp,
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          Colors.deepPurple,
                      foregroundColor:
                          Colors.white,
                      elevation: 3,
                      shadowColor:
                          Colors.deepPurple
                              .withOpacity(
                        0.3,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          17,
                        ),
                      ),
                    ),
                    child: Text(
                      isLogin
                          ? "Login"
                          : "Create Account",
                      style:
                          const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ------------------------------------------------
                // LOGIN / SIGNUP SWITCH
                // ------------------------------------------------

                Center(
                  child:
                      TextButton(
                    onPressed: () {
                      setState(() {
                        isLogin =
                            !isLogin;
                      });
                    },
                    style:
                        TextButton.styleFrom(
                      foregroundColor:
                          Colors.deepPurple,
                    ),
                    child:
                        RichText(
                      text:
                          TextSpan(
                        style:
                            const TextStyle(
                          color:
                              Colors.black54,
                          fontSize:
                              15,
                        ),
                        children: [
                          TextSpan(
                            text: isLogin
                                ? "Don't have an account? "
                                : "Already have an account? ",
                          ),
                          TextSpan(
                            text: isLogin
                                ? "Sign Up"
                                : "Login",
                            style:
                                const TextStyle(
                              color:
                                  Colors.deepPurple,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // ------------------------------------------------
              // SECURITY TEXT
              // ------------------------------------------------

              Center(
                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 17,
                      color: Colors
                          .deepPurple
                          .shade300,
                    ),
                    const SizedBox(
                        width: 7),
                    Text(
                      "Your account is secure with Jamboo",
                      style:
                          TextStyle(
                        color:
                            Colors.grey
                                .shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // TERMS
              // ------------------------------------------------

              Center(
                child: Text(
                  "By continuing, you agree to our\n"
                  "Terms & Conditions and Privacy Policy",
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors
                        .grey
                        .shade500,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    emailController.dispose();
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }
}