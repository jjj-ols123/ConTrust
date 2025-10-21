// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';

class BuildAdminLogin {

  static Widget buildLoginHeader(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.admin_panel_settings,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'ConTrust SuperAdmin',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
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
      decoration: const InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
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
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: onToggleVisibility,
        ),
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
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Colors.red),
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
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.green),
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
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Sign In'),
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildLoginHeader(context),
              const SizedBox(height: 32),
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
              if (errorMessage != null)
                buildErrorMessage(errorMessage),
              const SizedBox(height: 24),
              buildSignInButton(
                isLoading: isLoading,
                onPressed: onSignIn,
              ),
            ],
          ),
        ),
      ),
    );
  }
}