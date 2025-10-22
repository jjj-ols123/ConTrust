// ignore_for_file: deprecated_member_use

import 'package:contractee/pages/cee_welcome.dart';
import 'package:contractor/Screen/cor_login.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:superadmin/pages/login.dart';

class WebsiteStartPage extends StatelessWidget {
  const WebsiteStartPage({super.key});

  bool get _isWeb => kIsWeb;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 900;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          const Image(
            image: AssetImage('assets/bgloginscreen.jpg'),
            fit: BoxFit.cover,
          ),

          // Gradient Overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.2),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          // Content
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1100 : screenWidth * 0.9,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Text(
                      'Welcome to ConTrust',
                      style: TextStyle(
                        fontSize: isDesktop ? 48 : 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Choose how you want to continue',
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: isDesktop ? 48 : 32),

                    // Cards
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: isDesktop
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(child: _buildContracteeCard(context)),
                                const SizedBox(width: 32),
                                Expanded(child: _buildContractorCard(context)),
                              ],
                            )
                          : Column(
                              children: [
                                _buildContracteeCard(context),
                                const SizedBox(height: 24),
                                _buildContractorCard(context),
                              ],
                            ),
                    ),

                    const SizedBox(height: 32),

                    if (!_isWeb)
                      const Text(
                        'Tip: This chooser is intended for web builds.',
                        style: TextStyle(color: Colors.white70),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Super Admin Button
          Positioned(
            bottom: 16,
            right: 16,
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SuperAdminLoginScreen()),
                );
              },
              icon: const Icon(Icons.admin_panel_settings, color: Colors.white70),
              label: const Text(
                'Super Admin Module',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContracteeCard(BuildContext context) {
    return _RoleCard(
      color: Colors.amber[600]!,
      icon: Icons.person_outline,
      title: 'Contractee',
      description:
          'Browse contractors, view contracts, and monitor your projects seamlessly.',
      buttonText: 'Continue as Contractee',
      onPressed: () {
        try {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WelcomePage()),
          );
        } catch (e) {
          ConTrustSnackBar.error(context, 'Error navigating to Contractee: $e');
        }
      },
    );
  }

  Widget _buildContractorCard(BuildContext context) {
    return _RoleCard(
      color: Colors.amber[600]!,
      icon: Icons.engineering_outlined,
      title: 'Contractor',
      description:
          'Sign in to bid for projects, manage contracts, and track your ongoing work.',
      buttonText: 'Continue as Contractor',
      onPressed: () {
        try {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => LoginScreen()),
          );
        } catch (e) {
          ConTrustSnackBar.error(context, 'Error navigating to Contractor: $e');
        }
      },
    );
  }
}

class _RoleCard extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onPressed;

  const _RoleCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 768;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: Matrix4.identity()..scale(_isHovered ? 1.04 : 1.0),
        curve: Curves.easeOut,
        child: Card(
          color: Colors.white.withOpacity(0.9),
          elevation: _isHovered ? 16 : 6,
          shadowColor: widget.color.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onPressed,
            child: Padding(
              padding: EdgeInsets.all(isWide ? 28 : 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(_isHovered ? 0.25 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: isWide ? 44 : 36,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: isWide ? 22 : 18,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                      fontSize: isWide ? 15 : 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: _isHovered ? 10 : 4,
                    ),
                    onPressed: widget.onPressed,
                    child: Text(
                      widget.buttonText,
                      style: TextStyle(
                        fontSize: isWide ? 16 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
