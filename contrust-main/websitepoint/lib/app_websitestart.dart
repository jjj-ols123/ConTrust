// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:backend/utils/be_snackbar.dart';

class WebsiteStartPage extends StatelessWidget {
  const WebsiteStartPage({super.key});

  bool get _isWeb => kIsWeb;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                _buildNavigationBar(context, isDesktop),
                _buildHeroSection(context, isDesktop, screenWidth),              
                _buildMainContent(context, isDesktop, screenWidth),               
                _buildFooter(context, isDesktop),
              ],
            ),
          ),     
          Positioned(
            top: 16,
            right: 16,
            child: _AdminButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/superadmin');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context, bool isDesktop) {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 60 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: isDesktop ? 40 : 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ConTrust',
                style: TextStyle(
                  fontSize: isDesktop ? 32 : 24,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1a1a1a),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDesktop, double screenWidth) {
    return Container(
      height: isDesktop ? 600 : 500,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const Image(
            image: AssetImage('assets/bgloginscreen.jpg'),
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.4),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 80 : 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: Column(
                      children: [
                        Text(
                          'Building Trust,',
                          style: TextStyle(
                            fontSize: isDesktop ? 64 : 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Delivering Excellence',
                          style: TextStyle(
                            fontSize: isDesktop ? 64 : 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _PulsingDivider(),
                  const SizedBox(height: 15),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: child,
                      );
                    },
                    child: Text(
                      'Your trusted platform for construction contract management',
                      style: TextStyle(
                        fontSize: isDesktop ? 20 : 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, bool isDesktop, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 30,
        vertical: isDesktop ? 100 : 60,
      ),
      child: Column(
        children: [
          Text(
            'What do you want to build?',
            style: TextStyle(
              fontSize: isDesktop ? 60 : 40,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1a1a1a),
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Choose your role to get started',
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              color: Colors.black54,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isDesktop ? 60 : 40),

          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : screenWidth),
            child: isDesktop
                ? Row(
                    children: [
                      Expanded(child: _buildContracteeCard(context)),
                      const SizedBox(width: 40),
                      Expanded(child: _buildContractorCard(context)),
                    ],
                  )
                : Column(
                    children: [
                      _buildContracteeCard(context),
                      const SizedBox(height: 30),
                      _buildContractorCard(context),
                    ],
                  ),
          ),
          if (!_isWeb) ...[
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Tip: This chooser is intended for web builds.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 80 : 30,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'ConTrust',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Building trust in construction, one contract at a time.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            children: [
              _FooterLink(text: 'About', onTap: () {}),
              _FooterLink(text: 'Services', onTap: () {}),
              _FooterLink(text: 'Contact', onTap: () {}),
              _FooterLink(text: 'Privacy', onTap: () {}),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text(
            '© 2025 ConTrust. All rights reserved.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  Widget _buildContracteeCard(BuildContext context) {
    return _RoleCard(
      color: const Color(0xFFFFA726),
      icon: Icons.person_outline,
      title: 'Contractee',
      description:
          'Browse contractors, view contracts, and monitor your projects seamlessly.',
      buttonText: 'Get Started',
      onPressed: () {
        try {
          Navigator.of(context).pushReplacementNamed('/contractee');
        } catch (e) {
          ConTrustSnackBar.error(context, 'Error navigating to Contractee: $e');
        }
      },
    );
  }

  Widget _buildContractorCard(BuildContext context) {
    return _RoleCard(
      color: const Color(0xFFFFA726),
      icon: Icons.engineering_outlined,
      title: 'Contractor',
      description:
          'Sign in to bid for projects, manage contracts, and track your ongoing work.',
      buttonText: 'Get Started',
      onPressed: () {
        try {
          Navigator.of(context).pushNamed('/contractor');
        } catch (e) {
          ConTrustSnackBar.error(context, 'Error navigating to Contractor: $e');
        }
      },
    );
  }
}

class _PulsingDivider extends StatefulWidget {
  const _PulsingDivider();

  @override
  State<_PulsingDivider> createState() => _PulsingDividerState();
}

class _PulsingDividerState extends State<_PulsingDivider>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: 4,
          width: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFFFA726),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFA726).withOpacity(0.6 * _controller.value),
                blurRadius: 20 * _controller.value,
                spreadRadius: 2 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _FooterLink({required this.text, required this.onTap});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 14,
            color: _isHovered
                ? const Color(0xFFFFA726)
                : Colors.white.withOpacity(0.7),
            fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w400,
            decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
            decorationColor: const Color(0xFFFFA726),
          ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}

class _AdminButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AdminButton({required this.onPressed});

  @override
  State<_AdminButton> createState() => _AdminButtonState();
}

class _AdminButtonState extends State<_AdminButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered
                ? const Color(0xFFFFA726).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFFFFA726)
                  : Colors.black26,
              width: _isHovered ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: _isHovered
                    ? const Color(0xFFFFA726)
                    : Colors.black54,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Admin',
                style: TextStyle(
                  color: _isHovered
                      ? const Color(0xFFFFA726)
                      : Colors.black54,
                  fontSize: 14,
                  fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 768;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()..translate(0.0, _isHovered ? -8.0 : 0.0),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: _isHovered ? widget.color : Colors.grey.shade200,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _isHovered 
                    ? widget.color.withOpacity(0.2)
                    : Colors.black.withOpacity(0.05),
                blurRadius: _isHovered ? 20 : 8,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: EdgeInsets.all(isWide ? 48 : 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: isWide ? 48 : 40,
                      ),
                    ),
                    SizedBox(height: isWide ? 32 : 24),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: isWide ? 32 : 24,
                        color: const Color(0xFF1a1a1a),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.description,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: isWide ? 16 : 14,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: isWide ? 32 : 24),
                    Row(
                      children: [
                        InkWell(
                          onTap: widget.onPressed,
                          child: Row(
                            children: [
                              Text(
                                widget.buttonText,
                                style: TextStyle(
                                  color: widget.color,
                                  fontSize: isWide ? 18 : 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                transform: Matrix4.identity()
                                  ..translate(_isHovered ? 4.0 : 0.0, 0.0),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: widget.color,
                                  size: isWide ? 24 : 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
