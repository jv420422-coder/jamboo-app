import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'email_auth_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Widget loginButton({
    required String image,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(
              color: Color(0xFFE9E3F5),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Image.asset(
                image,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF211A2D),
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF9A8EAA),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GOOGLE SIGN IN
  // ============================================================

  Future<void> signInWithGoogle(
    BuildContext context,
  ) async {
    try {
      final GoogleSignInAccount? googleUser =
          await GoogleSignIn().signIn();

      if (googleUser == null) {
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential =
          GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // --------------------------------------------------------
      // Firebase Authentication
      // --------------------------------------------------------

      final UserCredential userCredential =
          await FirebaseAuth.instance
              .signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception(
          "Google user could not be created.",
        );
      }

      // --------------------------------------------------------
      // Check existing Jamboo user profile
      // --------------------------------------------------------

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      // --------------------------------------------------------
      // Existing verified phone
      // --------------------------------------------------------

      if (userDoc.exists) {
        final data =
            userDoc.data();

        final phoneVerified =
            data?['phoneVerified'] == true;

        final savedPhone =
            (data?['phone'] ?? '')
                .toString()
                .trim();

        if (phoneVerified &&
            savedPhone.isNotEmpty) {
          // Update last login / FCM token
          await _updateGoogleUserData(
            user: user,
          );

          if (!context.mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const HomeScreen(),
            ),
          );

          return;
        }
      }

      // --------------------------------------------------------
      // Phone is not verified
      // Mandatory phone verification
      // --------------------------------------------------------

      if (!context.mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              GooglePhoneVerificationScreen(
            user: user,
            googleName:
                user.displayName ?? '',
            googleEmail:
                user.email ?? '',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Google sign-in failed: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // UPDATE GOOGLE USER DATA
  // ============================================================

  Future<void> _updateGoogleUserData({
    required User user,
  }) async {
    String? token;

    try {
      if (!kIsWeb) {
        token =
            await FirebaseMessaging.instance
                .getToken();
      }
    } catch (_) {
      token = null;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(
      {
        'name':
            user.displayName ?? '',
        'email':
            user.email ?? '',
        'loginMethod':
            'google',
        'lastLogin':
            Timestamp.now(),
        if (token != null)
          'fcmToken': token,
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F3FC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(
              24,
              28,
              24,
              24,
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),

                // ------------------------------------------------
                // LOGO
                // ------------------------------------------------

                Container(
                  width: 108,
                  height: 108,
                  padding:
                      const EdgeInsets.all(14),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors
                            .deepPurple
                            .withOpacity(
                          0.12,
                        ),
                        blurRadius: 25,
                        offset:
                            const Offset(
                          0,
                          10,
                        ),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    "assets/images/logo.png",
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 26),

                // ------------------------------------------------
                // TITLE
                // ------------------------------------------------

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    const Flexible(
                      child: Text(
                        "Hungry? Let’s Get Started",
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          fontSize: 32,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Icon(
                      Icons
                          .restaurant_menu,
                      color:
                          Colors.deepPurple,
                      size: 30,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                const Text(
                  "Sign in to discover great food and\n"
                  "order from your favourite restaurants.",
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color:
                        Color(0xFF766B82),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 14),

                // ------------------------------------------------
                // BADGE
                // ------------------------------------------------

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFEDE5FF,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      30,
                    ),
                  ),
                  child: const Text(
                    "Fast Delivery • Great Food • Easy Payments",
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Color(0xFF6F3FC2),
                    ),
                  ),
                ),

                const SizedBox(height: 34),

                // ------------------------------------------------
                // GOOGLE
                // ------------------------------------------------

                loginButton(
                  image:
                      "assets/images/google.png",
                  text:
                      "Continue with Google",
                  onTap: () {
                    signInWithGoogle(
                      context,
                    );
                  },
                ),

                const SizedBox(height: 14),

                // ------------------------------------------------
                // EMAIL
                // ------------------------------------------------

                loginButton(
                  image:
                      "assets/images/email.png",
                  text:
                      "Continue with Email",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const EmailAuthScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // OR
                // ------------------------------------------------

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color:
                            const Color(
                          0xFFDCD3E8,
                        ),
                      ),
                    ),
                    const Padding(
                      padding:
                          EdgeInsets
                              .symmetric(
                        horizontal: 14,
                      ),
                      child: Text(
                        "OR",
                        style:
                            TextStyle(
                          color:
                              Color(
                            0xFF91869D,
                          ),
                          fontSize: 13,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color:
                            const Color(
                          0xFFDCD3E8,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ------------------------------------------------
                // PHONE
                // ------------------------------------------------

                loginButton(
                  image:
                      "assets/images/phone.png",
                  text:
                      "Continue with Phone Number",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                const PhoneAuthScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ------------------------------------------------
                // SECURITY
                // ------------------------------------------------

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Container(
                      padding:
                          const EdgeInsets
                              .all(8),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFEDE5FF,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .lock_outline_rounded,
                        size: 16,
                        color:
                            Color(
                          0xFF7040C4,
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 9,
                    ),
                    const Text(
                      "Your account is secure with Jamboo",
                      style:
                          TextStyle(
                        fontSize: 12,
                        color:
                            Color(
                          0xFF766B82,
                        ),
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                const Text(
                  "By continuing, you agree to our\n"
                  "Terms & Conditions and Privacy Policy",
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color:
                        Color(0xFF93889F),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// GOOGLE PHONE VERIFICATION SCREEN
// ================================================================

class GooglePhoneVerificationScreen
    extends StatefulWidget {
  final User user;
  final String googleName;
  final String googleEmail;

  const GooglePhoneVerificationScreen({
    super.key,
    required this.user,
    required this.googleName,
    required this.googleEmail,
  });

  @override
  State<GooglePhoneVerificationScreen>
      createState() =>
          _GooglePhoneVerificationScreenState();
}

class _GooglePhoneVerificationScreenState
    extends State<
        GooglePhoneVerificationScreen> {
  final TextEditingController
      phoneController =
      TextEditingController();

  final TextEditingController
      otpController =
      TextEditingController();

  String? verificationId;

  bool isLoading = false;
  bool otpSent = false;

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> sendOtp() async {
    final phone =
        phoneController.text.trim();

    if (phone.length != 10) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a valid 10-digit mobile number.",
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance
          .verifyPhoneNumber(
        phoneNumber: "+91$phone",

        timeout:
            const Duration(
          seconds: 60,
        ),

        // --------------------------------------------------------
        // Automatic verification
        // --------------------------------------------------------

        verificationCompleted:
            (PhoneAuthCredential
                credential) async {
          try {
            await _linkPhoneAndFinish(
              credential,
              phone,
            );
          } catch (e) {
            if (!mounted) return;

            setState(() {
              isLoading = false;
            });

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(
              SnackBar(
                content: Text(
                  "Phone verification failed: $e",
                ),
              ),
            );
          }
        },

        // --------------------------------------------------------
        // Verification failed
        // --------------------------------------------------------

        verificationFailed:
            (FirebaseAuthException e) {
          if (!mounted) return;

          setState(() {
            isLoading = false;
          });

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            SnackBar(
              content: Text(
                e.message ??
                    "Unable to send OTP.",
              ),
            ),
          );
        },

        // --------------------------------------------------------
        // OTP sent
        // --------------------------------------------------------

        codeSent: (
          String id,
          int? resendToken,
        ) {
          if (!mounted) return;

          setState(() {
            verificationId = id;
            otpSent = true;
            isLoading = false;
          });

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(
            const SnackBar(
              content: Text(
                "OTP sent successfully.",
              ),
            ),
          );
        },

        // --------------------------------------------------------
        // Timeout
        // --------------------------------------------------------

        codeAutoRetrievalTimeout:
            (String id) {
          verificationId = id;
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            "Something went wrong: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> verifyOtp() async {
    final otp =
        otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter the 6-digit OTP.",
          ),
        ),
      );
      return;
    }

    final id = verificationId;

    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "OTP session expired. Please request a new OTP.",
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final credential =
          PhoneAuthProvider
              .credential(
        verificationId: id,
        smsCode: otp,
      );

      await _linkPhoneAndFinish(
        credential,
        phoneController.text.trim(),
      );
    } on FirebaseAuthException catch (
        e) {
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            "Verification failed: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // LINK PHONE + SAVE USER
  // ============================================================

  Future<void> _linkPhoneAndFinish(
    PhoneAuthCredential credential,
    String phone,
  ) async {
    final currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception(
        "Google session expired. Please login again.",
      );
    }

    // ----------------------------------------------------------
    // Link verified phone with Google account
    // ----------------------------------------------------------

    await currentUser.linkWithCredential(
      credential,
    );

    // ----------------------------------------------------------
    // Get FCM token
    // ----------------------------------------------------------

    String? token;

    try {
      if (!kIsWeb) {
        token =
            await FirebaseMessaging.instance
                .getToken();
      }
    } catch (_) {
      token = null;
    }

    // ----------------------------------------------------------
    // Save Google + verified phone information
    // ----------------------------------------------------------

    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .set(
      {
        'name':
            widget.googleName,
        'email':
            widget.googleEmail,
        'phone':
            phone,
        'phoneVerified':
            true,
        'loginMethod':
            'google',
        'lastLogin':
            Timestamp.now(),
        if (token != null)
          'fcmToken': token,
      },
      SetOptions(
        merge: true,
      ),
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    // ----------------------------------------------------------
    // Go to Home
    // ----------------------------------------------------------

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const HomeScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // CANCEL GOOGLE PHONE VERIFICATION
  // ============================================================

  Future<void> cancelVerification() async {
    try {
      await FirebaseAuth.instance
          .signOut();

      await GoogleSignIn().signOut();
    } catch (_) {}

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7F3FC),

      appBar: AppBar(
        backgroundColor:
            Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Verify Mobile Number",
          style: TextStyle(
            fontWeight:
                FontWeight.w700,
            color:
                Color(0xFF211A2D),
          ),
        ),
        actions: [
          TextButton(
            onPressed: isLoading
                ? null
                : cancelVerification,
            child: const Text(
              "Cancel",
              style: TextStyle(
                color:
                    Color(0xFF7040C4),
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            30,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              // ------------------------------------------------
              // LOGO
              // ------------------------------------------------

              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  padding:
                      const EdgeInsets.all(14),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      28,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors
                            .deepPurple
                            .withOpacity(
                          0.12,
                        ),
                        blurRadius: 24,
                        offset:
                            const Offset(
                          0,
                          10,
                        ),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    "assets/images/logo.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ------------------------------------------------
              // TITLE
              // ------------------------------------------------

              Text(
                otpSent
                    ? "Verify your number"
                    : "Add your mobile number",
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                  color:
                      Color(0xFF211A2D),
                ),
              ),

              const SizedBox(height: 10),

              // ------------------------------------------------
              // SUBTITLE
              // ------------------------------------------------

              Text(
                otpSent
                    ? "Enter the 6-digit OTP sent to\n"
                      "+91 ${phoneController.text.trim()}"
                    : "A mobile number is required for your Jamboo account.\n"
                      "We'll send you an OTP for verification.",
                textAlign:
                    TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color:
                      Color(0xFF766B82),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // ------------------------------------------------
              // PHONE FIELD
              // ------------------------------------------------

              if (!otpSent) ...[
                TextField(
                  controller:
                      phoneController,
                  keyboardType:
                      TextInputType.phone,
                  maxLength: 10,
                  decoration:
                      InputDecoration(
                    counterText: "",
                    prefixText:
                        "+91 ",
                    prefixStyle:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Color(0xFF211A2D),
                    ),
                    hintText:
                        "Mobile number",
                    prefixIcon:
                        const Icon(
                      Icons
                          .phone_outlined,
                      color:
                          Color(0xFF7040C4),
                    ),
                    filled: true,
                    fillColor:
                        Colors.white,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(
                          0xFFE9E3F5,
                        ),
                      ),
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(
                          0xFFE9E3F5,
                        ),
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(
                          0xFF7040C4,
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // SEND OTP
                // ------------------------------------------------

                SizedBox(
                  height: 58,
                  child:
                      ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : sendOtp,
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF7040C4,
                      ),
                      foregroundColor:
                          Colors.white,
                      elevation: 4,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          18,
                        ),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2.5,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Text(
                            "Send OTP",
                            style:
                                TextStyle(
                              fontSize:
                                  16,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                  ),
                ),
              ]

              // ------------------------------------------------
              // OTP
              // ------------------------------------------------

              else ...[
                TextField(
                  controller:
                      otpController,
                  keyboardType:
                      TextInputType.number,
                  maxLength: 6,
                  decoration:
                      InputDecoration(
                    counterText: "",
                    hintText:
                        "Enter OTP",
                    prefixIcon:
                        const Icon(
                      Icons
                          .lock_outline_rounded,
                      color:
                          Color(0xFF7040C4),
                    ),
                    filled: true,
                    fillColor:
                        Colors.white,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(
                          0xFFE9E3F5,
                        ),
                      ),
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(
                          0xFFE9E3F5,
                        ),
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(
                          0xFF7040C4,
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // VERIFY
                // ------------------------------------------------

                SizedBox(
                  height: 58,
                  child:
                      ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : verifyOtp,
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF7040C4,
                      ),
                      foregroundColor:
                          Colors.white,
                      elevation: 4,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          18,
                        ),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2.5,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Text(
                            "Verify & Continue",
                            style:
                                TextStyle(
                              fontSize:
                                  16,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 14),

                TextButton(
                  onPressed:
                      isLoading
                          ? null
                          : () {
                              setState(() {
                                otpSent =
                                    false;
                                verificationId =
                                    null;
                                otpController
                                    .clear();
                              });
                            },
                  child:
                      const Text(
                    "Change mobile number",
                    style:
                        TextStyle(
                      color:
                          Color(0xFF7040C4),
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ------------------------------------------------
              // SECURITY
              // ------------------------------------------------

              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets
                            .all(8),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFEDE5FF,
                      ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .verified_user_outlined,
                      size: 16,
                      color:
                          Color(
                        0xFF7040C4,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 9,
                  ),
                  const Text(
                    "Your mobile number is securely verified",
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Color(
                        0xFF766B82,
                      ),
                      fontWeight:
                          FontWeight.w500,
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

// ================================================================
// PHONE LOGIN SCREEN
// ================================================================

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({
    super.key,
  });

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

  bool isLoading = false;
  bool otpSent = false;

  @override
  void dispose() {
    phoneController.dispose();
    nameController.dispose();
    emailController.dispose();
    otpController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> sendOtp() async {
    final phone = phoneController.text.trim();
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a valid 10-digit mobile number.",
          ),
        ),
      );
      return;
    }

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter your full name.",
          ),
        ),
      );
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter a valid email address.",
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await auth.verifyPhoneNumber(
        phoneNumber: "+91$phone",
        timeout: const Duration(seconds: 60),

        // --------------------------------------------------------
        // AUTOMATIC VERIFICATION
        // --------------------------------------------------------

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          try {
            await auth.signInWithCredential(
              credential,
            );

            await _saveUserProfile(
              phone: phone,
              name: name,
              email: email,
            );

            if (!mounted) return;

            setState(() {
              isLoading = false;
            });

            _goToHome();
          } catch (e) {
            if (!mounted) return;

            setState(() {
              isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Verification failed: $e",
                ),
              ),
            );
          }
        },

        // --------------------------------------------------------
        // VERIFICATION FAILED
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
                    "Unable to send OTP.",
              ),
            ),
          );
        },

        // --------------------------------------------------------
        // OTP SENT
        // --------------------------------------------------------

        codeSent: (
          String id,
          int? resendToken,
        ) {
          if (!mounted) return;

          setState(() {
            verificationId = id;
            otpSent = true;
            isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "OTP sent successfully.",
              ),
            ),
          );
        },

        // --------------------------------------------------------
        // AUTO RETRIEVAL TIMEOUT
        // --------------------------------------------------------

        codeAutoRetrievalTimeout:
            (String id) {
          verificationId = id;
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Something went wrong: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter the 6-digit OTP.",
          ),
        ),
      );
      return;
    }

    final id = verificationId;

    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "OTP session expired. Please request a new OTP.",
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final credential =
          PhoneAuthProvider.credential(
        verificationId: id,
        smsCode: otp,
      );

      await auth.signInWithCredential(
        credential,
      );

      await _saveUserProfile(
        phone: phoneController.text.trim(),
        name: nameController.text.trim(),
        email: emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      _goToHome();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                "Invalid OTP.",
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
            "Verification failed: $e",
          ),
        ),
      );
    }
  }

  // ============================================================
  // SAVE USER PROFILE
  // ============================================================

  Future<void> _saveUserProfile({
    required String phone,
    required String name,
    required String email,
  }) async {
    final user = auth.currentUser;

    if (user == null) {
      throw Exception(
        "User authentication failed.",
      );
    }

    String? token;

    try {
      if (!kIsWeb) {
        token =
            await FirebaseMessaging.instance.getToken();
      }
    } catch (_) {
      token = null;
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(
      {
        'name': name,
        'email': email,
        'phone': phone,
        'phoneVerified': true,
        'loginMethod': 'phone',
        'lastLogin': Timestamp.now(),
        if (token != null) 'fcmToken': token,
      },
      SetOptions(
        merge: true,
      ),
    );
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
  // BUILD
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
          "Phone Login",
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
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: [
              // ------------------------------------------------
              // LOGO
              // ------------------------------------------------

              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  padding:
                      const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple
                            .withOpacity(0.12),
                        blurRadius: 24,
                        offset:
                            const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    "assets/images/logo.png",
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              Text(
                otpSent
                    ? "Verify your number"
                    : "Create your account",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF211A2D),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                otpSent
                    ? "Enter the 6-digit OTP sent to\n"
                        "+91 ${phoneController.text.trim()}"
                    : "Enter your details to continue with Jamboo.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF766B82),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // ------------------------------------------------
              // MOBILE NUMBER — FIRST
              // ------------------------------------------------

              if (!otpSent) ...[
                TextField(
                  controller: phoneController,
                  keyboardType:
                      TextInputType.phone,
                  maxLength: 10,
                  decoration: InputDecoration(
                    counterText: "",
                    prefixText: "+91 ",
                    prefixStyle:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.w600,
                      color: Color(0xFF211A2D),
                    ),
                    hintText:
                        "Mobile number",
                    prefixIcon:
                        const Icon(
                      Icons.phone_outlined,
                      color: Color(0xFF7040C4),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color: Color(0xFFE9E3F5),
                      ),
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color: Color(0xFFE9E3F5),
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color: Color(0xFF7040C4),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ------------------------------------------------
                // FULL NAME — SECOND
                // ------------------------------------------------

                TextField(
                  controller: nameController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: "Full name",
                    prefixIcon:
                        const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF7040C4),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color: Color(0xFFE9E3F5),
                      ),
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color: Color(0xFFE9E3F5),
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color: Color(0xFF7040C4),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ------------------------------------------------
                // EMAIL — THIRD
                // ------------------------------------------------

                TextField(
                  controller: emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText:
                        "Email address",
                    prefixIcon:
                        const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF7040C4),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color: Color(0xFFE9E3F5),
                      ),
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color: Color(0xFFE9E3F5),
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color: Color(0xFF7040C4),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // SEND OTP
                // ------------------------------------------------

                SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : sendOtp,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF7040C4,
                      ),
                      foregroundColor:
                          Colors.white,
                      elevation: 4,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Text(
                            "Send OTP",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ] else ...[
                // ------------------------------------------------
                // OTP FIELD
                // ------------------------------------------------

                TextField(
                  controller: otpController,
                  keyboardType:
                      TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    counterText: "",
                    hintText:
                        "Enter OTP",
                    prefixIcon:
                        const Icon(
                      Icons
                          .lock_outline_rounded,
                      color:
                          Color(0xFF7040C4),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(0xFFE9E3F5),
                      ),
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(0xFFE9E3F5),
                      ),
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                      borderSide:
                          const BorderSide(
                        color:
                            Color(0xFF7040C4),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ------------------------------------------------
                // VERIFY
                // ------------------------------------------------

                SizedBox(
                  height: 58,
                  child: ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : verifyOtp,
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF7040C4,
                      ),
                      foregroundColor:
                          Colors.white,
                      elevation: 4,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          18,
                        ),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color:
                                  Colors.white,
                            ),
                          )
                        : const Text(
                            "Verify & Continue",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 14),

                TextButton(
                  onPressed:
                      isLoading
                          ? null
                          : () {
                              setState(() {
                                otpSent = false;
                                verificationId =
                                    null;
                                otpController
                                    .clear();
                              });
                            },
                  child: const Text(
                    "Change mobile number",
                    style: TextStyle(
                      color:
                          Color(0xFF7040C4),
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ------------------------------------------------
              // SECURITY
              // ------------------------------------------------

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.all(8),
                    decoration:
                        BoxDecoration(
                      color:
                          const Color(
                        0xFFEDE5FF,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .verified_user_outlined,
                      size: 16,
                      color:
                          Color(0xFF7040C4),
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Text(
                    "Secure login with Firebase",
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          Color(0xFF766B82),
                      fontWeight:
                          FontWeight.w500,
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