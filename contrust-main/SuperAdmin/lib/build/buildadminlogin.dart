// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';

class BuildAdminLogin {
  static Widget buildLoginHeader(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.admin_panel_settings,
          size: 80,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 24),
        Text(
          'ConTrust SuperAdmin',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  static Widget buildEmailField({
    required TextEditingController controller,
    required FocusNode? nextFocusNode,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Email',
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        prefixIcon: const Icon(Icons.email),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF8E7CFF), width: 1.2),
        ),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
      ),
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      onSubmitted: (_) {
        nextFocusNode?.requestFocus();
      },
    );
  }

  static Widget buildPasswordField({
    required TextEditingController controller,
    required VoidCallback onSubmitted,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Password',
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: onToggleVisibility,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
        ),
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
      ),
      obscureText: obscureText,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmitted(),
    );
  }

  static Widget buildErrorMessage(String? error) {
    if (error == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildSuccessMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildSignInButton({
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          side: const BorderSide(color: Color(0xFF8E7CFF), width: 1),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.black,
                  strokeWidth: 2,
                  ),
                )
                : const Text(
                  'Sign In',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
      ),
    );
  }

  static Widget buildLoginForm({
    required BuildContext context,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required FocusNode passwordFocusNode,
    required bool isLoading,
    required bool obscurePassword,
    required String? errorMessage,
    required VoidCallback onSignIn,
    required VoidCallback onTogglePasswordVisibility,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final maxCardWidth = screenWidth < 420
            ? screenWidth * 0.92
            : screenWidth < 768
                ? 480.0
                : 560.0;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B0B0B), Color(0xFF111111)],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxCardWidth),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFF9E86FF)],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      buildLoginHeader(context),
                      const SizedBox(height: 28),
                      buildEmailField(
                        controller: emailController,
                        nextFocusNode: passwordFocusNode,
                      ),
                      const SizedBox(height: 16),
                      buildPasswordField(
                        controller: passwordController,
                        onSubmitted: onSignIn,
                        obscureText: obscurePassword,
                        onToggleVisibility: onTogglePasswordVisibility,
                      ),
                      const SizedBox(height: 16),
                      if (errorMessage != null) ...[
                        buildErrorMessage(errorMessage),
                        const SizedBox(height: 12),
                      ],
                      buildSignInButton(
                        isLoading: isLoading,
                        onPressed: onSignIn,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
