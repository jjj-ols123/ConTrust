// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'about_page.dart';
import 'services_page.dart';

class WebsiteStartPage extends StatefulWidget {
  const WebsiteStartPage({super.key});

  @override
  State<WebsiteStartPage> createState() => _WebsiteStartPageState();
}

class _WebsiteStartPageState extends State<WebsiteStartPage> {
  bool get _isWeb => kIsWeb;

  @override
  void initState() {
    super.initState();
    _enforceRedirectGuard();
  }

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 900;
    final bool isTablet = screenWidth >= 600 && screenWidth < 900;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildNavigationBar(context, isDesktop, isTablet, isMobile),
                  _buildHeroSection(context, isDesktop, isTablet, isMobile),              
                  _buildMainContent(context, isDesktop, isTablet, isMobile),               
                  _buildFooter(context, isDesktop, isTablet, isMobile),
                ],
              ),
            ),     
          ],
        ),
      ),
    );
  }

  void _rememberAndRedirect(String role) {
    try {
      html.window.localStorage['preferredSubdomain'] = role;
      final String base = role == 'contractor'
          ? 'https://contractor.contrust-sjdm.com'
          : 'https://contractee.contrust-sjdm.com';
      final String path = role == 'contractor' ? '/' : '/login';
      html.window.location.replace('$base$path');
    } catch (e) {
      ConTrustSnackBar.error(context, 'Navigation error: $e');
    }
  }

  void _forwardOAuthIfPresent(String role) {
    final search = html.window.location.search ?? '';
    if (search.contains('code=') || search.contains('access_token=')) {
      final String base = role == 'contractor'
          ? 'https://contractor.contrust-sjdm.com'
          : 'https://contractee.contrust-sjdm.com';
      html.window.location.replace('$base/auth/callback$search');
    }
  }

  void _enforceRedirectGuard() {
    try {
      final String? role = html.window.localStorage['preferredSubdomain'];
      final String normalized = (role ?? '').toLowerCase();
      if (normalized == 'contractor' || normalized == 'contractee') {
        _forwardOAuthIfPresent(normalized);
        // If no OAuth params, keep users on their chosen subdomain
        final String base = normalized == 'contractor'
            ? 'https://contractor.contrust-sjdm.com'
            : 'https://contractee.contrust-sjdm.com';
        final String path = normalized == 'contractor' ? '/' : '/login';
        html.window.location.replace('$base$path');
      }
    } catch (_) {
      // Non-fatal: stay on landing if guard fails
    }
  }

  Widget _buildNavigationBar(BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    final double horizontalPadding = isDesktop ? 60 : (isTablet ? 40 : 16);
    final double logoHeight = isDesktop ? 40 : (isMobile ? 28 : 32);
    final double fontSize = isDesktop ? 32 : (isMobile ? 20 : 26);
    
    return Container(
      height: isMobile ? 64 : 80,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isMobile ? 4 : 6,
                height: logoHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'ConTrust',
                style: TextStyle(
                  fontSize: fontSize,
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

  Widget _buildHeroSection(BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    final double heroHeight = isDesktop ? 600 : (isTablet ? 500 : 400);
    final double horizontalPadding = isDesktop ? 80 : (isTablet ? 40 : 20);
    final double titleFontSize = isDesktop ? 64 : (isTablet ? 48 : 32);
    final double subtitleFontSize = isDesktop ? 20 : (isTablet ? 18 : 14);
    
    return SizedBox(
      height: heroHeight,
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
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: isMobile ? -0.5 : -1,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Delivering Excellence',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: isMobile ? -0.5 : -1,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isMobile ? 20 : 32),
                  const _PulsingDivider(),
                  SizedBox(height: isMobile ? 12 : 15),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: child,
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 0),
                      child: Text(
                        'Your trusted platform for construction contract management',
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
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

  Widget _buildMainContent(BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    final double horizontalPadding = isDesktop ? 80 : (isTablet ? 40 : 20);
    final double verticalPadding = isDesktop ? 100 : (isTablet ? 70 : 50);
    final double titleFontSize = isDesktop ? 60 : (isTablet ? 48 : 32);
    final double subtitleFontSize = isDesktop ? 18 : (isTablet ? 17 : 15);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 0),
                child: Text(
                  'What do you want to build?',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1a1a1a),
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                'Choose your role to get started',
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isDesktop ? 60 : (isTablet ? 50 : 30)),

              isDesktop
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
              if (!_isWeb) ...[
                SizedBox(height: isMobile ? 30 : 40),
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tip: This chooser is intended for web builds.',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: isMobile ? 13 : 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    final double horizontalPadding = isDesktop ? 80 : (isTablet ? 40 : 20);
    final double verticalPadding = isMobile ? 30 : 40;
    final double logoFontSize = isMobile ? 20 : 24;
    final double logoHeight = isMobile ? 20 : 24;
    final double logoWidth = isMobile ? 3 : 4;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
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
                width: logoWidth,
                height: logoHeight,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 10),
              Text(
                'ConTrust',
                style: TextStyle(
                  fontSize: logoFontSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 0),
            child: Text(
              'Building trust in construction, one contract at a time.',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: isMobile ? 16 : 20,
            runSpacing: isMobile ? 12 : 0,
            children: [
              _FooterLink(
                text: 'About',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
              _FooterLink(
                text: 'Services',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ServicesPage()),
                  );
                },
              ),
              _FooterLink(text: 'Contact', onTap: () {}),
              _FooterLink(text: 'Privacy', onTap: () {}),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 24),
          Divider(color: Colors.white.withOpacity(0.1)),
          SizedBox(height: isMobile ? 16 : 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 0),
            child: Text(
              '© 2025 ConTrust. All rights reserved.',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: Colors.white.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
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
        _rememberAndRedirect('contractee');
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
        _rememberAndRedirect('contractor');
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

// Admin button removed per request.

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
