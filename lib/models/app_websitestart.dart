// ignore_for_file: deprecated_member_use

import 'package:contractee/pages/cee_welcome.dart';
import 'package:contractor/Screen/cor_login.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WebsiteStartPage extends StatelessWidget {
  const WebsiteStartPage({super.key});

  bool get _isWeb => kIsWeb;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 900;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bgloginscreen.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 1100 : screenWidth * 0.9,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 24 : 16,
                vertical: 32,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Welcome to ConTrust',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      fontSize: isDesktop ? null : 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how you want to continue',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.black54,
                      fontSize: isDesktop ? null : 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isDesktop ? 32 : 24),
                  isDesktop
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildContracteeCard(context)),
                            const SizedBox(width: 24),
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
                  SizedBox(height: isDesktop ? 24 : 16),
                  if (!_isWeb)
                    const Text(
                      'Tip: This chooser is intended for web builds.',
                      style: TextStyle(color: Colors.black45),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContracteeCard(BuildContext context) {
    return _RoleCard(
      color: Colors.amber[700]!,
      icon: Icons.person_outline,
      title: 'Contractee',
      description:
          'Browse contractors, manage contracts and monitor your projects.',
      buttonText: 'Continue as Contractee',
      onPressed: () {
        try {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WelcomePage()),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error navigating to Contractee: $e')),
          );
        }
      },
    );
  }

  Widget _buildContractorCard(BuildContext context) {
    return _RoleCard(
      color: Colors.amber[700]!,
      icon: Icons.engineering_outlined,
      title: 'Contractor',
      description:
          'Sign in to manage bids, contracts, clients, and ongoing projects.',
      buttonText: 'Continue as Contractor',
      onPressed: () {
        try {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => LoginScreen()),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error navigating to Contractor: $e')),
          );
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
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        child: Card(
          elevation: _isHovered ? 12 : 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              widget.onPressed();
            },
            child: Padding(
              padding: EdgeInsets.all(isWide ? 24 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(isWide ? 16 : 12), 
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: isWide ? 36 : 28, 
                    ),
                  ),
                  SizedBox(height: isWide ? 16 : 12),
                  Text(
                    widget.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: isWide ? null : 18, 
                    ),
                  ),
                  SizedBox(height: isWide ? 8 : 6),
                  Text(
                    widget.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                      fontSize: isWide ? null : 14, 
                    ),
                  ),
                  SizedBox(height: isWide ? 16 : 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: isWide ? 14 : 12, 
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: _isHovered ? 8 : 4,
                      ),
                      onPressed: () {
                        widget.onPressed();
                      },
                      child: Text(
                        widget.buttonText,
                        style: TextStyle(
                          fontSize: isWide ? 16 : 14, 
                          fontWeight: FontWeight.w600,
                        ),
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

