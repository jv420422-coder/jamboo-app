import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import 'home_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() =>
      _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController phoneController =
      TextEditingController();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController otpController =
      TextEditingController();

  final FirebaseAuth auth = FirebaseAuth.instance;

  String? verificationId;
int? resendToken;
int resendCountdown = 0;
bool isResendingOtp = false;

bool isLoading = false;
bool otpSent = false;
bool isLogin = false;
bool isFinishing = false;

Timer? resendTimer;

  @override
void dispose() {
  resendTimer?.cancel();

  phoneController.dispose();
  nameController.dispose();
  emailController.dispose();
  otpController.dispose();

  super.dispose();
}

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
  // ============================================================
// RESEND OTP COUNTDOWN
// ============================================================

void _startResendCountdown() {
  resendTimer?.cancel();

  if (!mounted) return;

  setState(() {
    resendCountdown = 30;
  });

  resendTimer = Timer.periodic(
    const Duration(seconds: 1),
    (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (resendCountdown <= 1) {
        timer.cancel();

        setState(() {
          resendCountdown = 0;
        });
      } else {
        setState(() {
          resendCountdown--;
        });
      }
    },
  );
}

  // ============================================================
  // SWITCH BETWEEN LOGIN AND SIGNUP
  // ============================================================

  void _switchMode() {
    if (isLoading) return;

    setState(() {
      isLogin = !isLogin;
      otpSent = false;
      verificationId = null;
      otpController.clear();
      nameController.clear();
      emailController.clear();
    });
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> sendOtp() async {
    final phone = phoneController.text.trim();
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
      _showMessage(
        'Please enter a valid 10-digit mobile number.',
      );
      return;
    }

    // Name and email are required only during signup.
    if (!isLogin) {
      if (name.isEmpty) {
        _showMessage('Please enter your full name.');
        return;
      }

      if (email.isEmpty ||
          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
              .hasMatch(email)) {
        _showMessage('Please enter a valid email address.');
        return;
      }
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      isFinishing = false;
    });

    try {
      await auth.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        timeout: const Duration(seconds: 60),

        // ------------------------------------------------------
        // AUTOMATIC OTP VERIFICATION
        // ------------------------------------------------------

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          await _completePhoneAuth(
            credential,
            phone,
            name,
            email,
          );
        },

        // ------------------------------------------------------
        // VERIFICATION FAILED
        // ------------------------------------------------------

        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;

          setState(() {
            isLoading = false;
          });

          _showMessage(
            e.message ?? 'Unable to send OTP.',
          );
        },

        // ------------------------------------------------------
        // OTP SENT
        // ------------------------------------------------------

        codeSent: (
  String id,
  int? token,
) {
  if (!mounted) return;

  setState(() {
    verificationId = id;
    resendToken = token;
    otpSent = true;
    isLoading = false;
  });

  _startResendCountdown();
  _showMessage('OTP sent successfully.');
},
        // ------------------------------------------------------
        // AUTO RETRIEVAL TIMEOUT
        // ------------------------------------------------------

        codeAutoRetrievalTimeout: (String id) {
          verificationId = id;
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage('Something went wrong: $e');
    }
  }
  // ============================================================
// RESEND OTP
// ============================================================

Future<void> resendOtp() async {
  if (isLoading || resendCountdown > 0) return;

  final phone = phoneController.text.trim();

  if (verificationId == null || verificationId!.isEmpty) {
    _showMessage('Please request OTP first.');
    return;
  }

  FocusScope.of(context).unfocus();

  setState(() {
    isLoading = true;
    isResendingOtp = true;
  });

  try {
    await auth.verifyPhoneNumber(
      phoneNumber: '+91$phone',
      timeout: const Duration(seconds: 60),

      // Reuse the resend token provided by Firebase when available.
      forceResendingToken: resendToken,

      verificationCompleted: (PhoneAuthCredential credential) async {
        await _completePhoneAuth(
          credential,
          phone,
          nameController.text.trim(),
          emailController.text.trim(),
        );
      },

      verificationFailed: (FirebaseAuthException e) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
          isResendingOtp = false;
        });

        _showMessage(e.message ?? 'Unable to resend OTP.');
      },

      codeSent: (String id, int? token) {
        if (!mounted) return;

        setState(() {
          verificationId = id;
          resendToken = token ?? resendToken;
          isLoading = false;
          isResendingOtp = false;
          otpController.clear();
        });

        _startResendCountdown();
        _showMessage('A new OTP has been sent.');
      },

      codeAutoRetrievalTimeout: (String id) {
        verificationId = id;
      },
    );
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoading = false;
      isResendingOtp = false;
    });

    _showMessage('Unable to resend OTP: $e');
  }
}

  // ============================================================
  // VERIFY OTP MANUALLY
  // ============================================================

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      _showMessage('Please enter the 6-digit OTP.');
      return;
    }

    final id = verificationId;

    if (id == null || id.isEmpty) {
      _showMessage(
        'OTP session expired. Please request a new OTP.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
      isFinishing = false;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: id,
        smsCode: otp,
      );

      await _completePhoneAuth(
        credential,
        phoneController.text.trim(),
        nameController.text.trim(),
        emailController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      String message = 'OTP verification failed.';

      if (e.code == 'invalid-verification-code') {
        message = 'Invalid OTP. Please try again.';
      } else if (e.code == 'session-expired') {
        message = 'OTP expired. Please request a new OTP.';
      } else if (e.code == 'credential-already-in-use') {
        message =
            'This number is already linked to another account.';
      }

      _showMessage(message);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage('Verification failed: $e');
    }
  }

  // ============================================================
  // COMPLETE PHONE AUTHENTICATION
  // ============================================================

  Future<void> _completePhoneAuth(
    PhoneAuthCredential credential,
    String phone,
    String name,
    String email,
  ) async {
    if (isFinishing) return;

    isFinishing = true;

    try {
      // Authenticate the phone number with Firebase.
      final UserCredential result =
          await auth.signInWithCredential(credential);

      final User? user = result.user;

      if (user == null) {
        throw Exception('Authentication failed.');
      }

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      // Check whether a Jamboo profile already exists.
      final userDoc = await userRef.get();

      // --------------------------------------------------------
      // EXISTING USER LOGIN
      // --------------------------------------------------------

      if (isLogin) {
        if (!userDoc.exists) {
          // Do not create a Jamboo profile during login.
          await auth.signOut();

          if (!mounted) return;

          setState(() {
            isLoading = false;
            otpSent = false;
            verificationId = null;
            otpController.clear();
          });

          _showMessage(
            'Account not found. Please create an account first.',
          );

          return;
        }

        // Update only login information.
        // Do not overwrite the existing name or email.
        String? token;

        try {
          if (!kIsWeb) {
            token = await FirebaseMessaging.instance.getToken();
          }
        } catch (_) {
          token = null;
        }

        await userRef.set(
          {
            'lastLogin': Timestamp.now(),
            if (token != null) 'fcmToken': token,
          },
          SetOptions(merge: true),
        );

        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        _goToHome();
        return;
      }

      // --------------------------------------------------------
      // SIGNUP: PREVENT DUPLICATE PROFILE CREATION
      // --------------------------------------------------------

      if (userDoc.exists) {
        // This number already has a Jamboo profile.
        await auth.signOut();

        if (!mounted) return;

        setState(() {
          isLoading = false;
          otpSent = false;
          verificationId = null;
          otpController.clear();
          isLogin = true;
        });

        _showMessage(
          'Account already exists. Please login with your number.',
        );

        return;
      }

      // --------------------------------------------------------
      // CREATE NEW USER PROFILE
      // --------------------------------------------------------

      String? token;

      try {
        if (!kIsWeb) {
          token = await FirebaseMessaging.instance.getToken();
        }
      } catch (_) {
        token = null;
      }

      await userRef.set(
        {
          'name': name,
          'email': email,
          'phone': phone,
          'phoneVerified': true,
          'loginMethod': 'phone',
          'lastLogin': Timestamp.now(),
          if (token != null) 'fcmToken': token,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _goToHome();
    } catch (e) {
      isFinishing = false;

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _showMessage('Authentication failed: $e');
    }
  }

  // ============================================================
  // GO TO HOME
  // ============================================================

  void _goToHome() {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? prefixText,
  }) {
    return InputDecoration(
      counterText: '',
      hintText: hint,
      prefixText: prefixText,
      prefixStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF211A2D),
      ),
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF7040C4),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFE9E3F5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFE9E3F5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF7040C4),
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // PRIMARY BUTTON
  // ============================================================

  Widget _primaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7040C4),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  // ============================================================
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF211A2D),
        title: const Text(
          'Phone Login',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LOGO

              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // TITLE

              Text(
                otpSent
                    ? 'Verify your number'
                    : isLogin
                        ? 'Welcome Back!'
                        : 'Create your account',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF211A2D),
                ),
              ),

              const SizedBox(height: 10),

              // SUBTITLE

              Text(
                otpSent
                    ? 'Enter the 6-digit OTP sent to\n'
                        '+91 ${phoneController.text.trim()}'
                    : isLogin
                        ? 'Enter your mobile number to login to Jamboo.'
                        : 'Enter your details to continue with Jamboo.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF766B82),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // MOBILE NUMBER

              if (!otpSent) ...[
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: _inputDecoration(
                    hint: 'Mobile number',
                    icon: Icons.phone_outlined,
                    prefixText: '+91 ',
                  ),
                ),

                // NAME AND EMAIL: SIGNUP ONLY

                if (!isLogin) ...[
                  const SizedBox(height: 16),

                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDecoration(
                      hint: 'Full name',
                      icon: Icons.person_outline_rounded,
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration(
                      hint: 'Email address',
                      icon: Icons.email_outlined,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                _primaryButton(
                  text: 'Send OTP',
                  onPressed: sendOtp,
                ),
              ] else ...[
                // OTP FIELD

                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: _inputDecoration(
                    hint: 'Enter OTP',
                    icon: Icons.lock_outline_rounded,
                  ),
                ),

                const SizedBox(height: 20),

                _primaryButton(
                  text: 'Verify & Continue',
                  onPressed: verifyOtp,
                ),

                const SizedBox(height: 8),

// RESEND OTP

Center(
  child: TextButton(
    onPressed: isLoading || resendCountdown > 0
        ? null
        : resendOtp,
    child: Text(
      resendCountdown > 0
          ? 'Resend OTP in ${resendCountdown}s'
          : 'Resend OTP',
      style: TextStyle(
        color: resendCountdown > 0
            ? Colors.grey
            : const Color(0xFF7040C4),
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
),

const SizedBox(height: 4),

// CHANGE MOBILE NUMBER

TextButton(
  onPressed: isLoading
      ? null
      : () {
          resendTimer?.cancel();

          setState(() {
            otpSent = false;
            verificationId = null;
            resendToken = null;
            resendCountdown = 0;
            otpController.clear();
          });
        },
  child: const Text(
    'Change mobile number',
    style: TextStyle(
      color: Color(0xFF7040C4),
      fontWeight: FontWeight.w600,
    ),
  ),
),
              ],

              const SizedBox(height: 20),

              // SWITCH LOGIN / SIGNUP

              if (!otpSent)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        isLogin
                            ? "Don't have an account? "
                            : 'Already have an account? ',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF766B82),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _switchMode,
                      child: Text(
                        isLogin
                            ? 'Create Account'
                            : 'Login here',
                        style: const TextStyle(
                          color: Color(0xFF7040C4),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // SECURITY

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE5FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified_user_outlined,
                      size: 16,
                      color: Color(0xFF7040C4),
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Flexible(
                    child: Text(
                      'Secure login with Firebase',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF766B82),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}