// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:backend/utils/be_snackbar.dart';
import 'package:websitepoint/web_redirect.dart';
import 'package:websitepoint/widgets/footer.dart';

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
                _buildNavigationBar(context, isDesktop, false, false),         
                _buildHeroSection(context, isDesktop, screenWidth),               
                _buildMainContent(context, isDesktop, screenWidth),
                const Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'ConTrust',
            style: TextStyle(
              fontSize: isDesktop ? 32 : 24,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1a1a1a),
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/about'),
                child: const Text(
                  'About',
                  style: TextStyle(color: Color(0xFF1a1a1a), fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/services'),
                child: const Text(
                  'Services',
                  style: TextStyle(color: Color(0xFF1a1a1a), fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/contact'),
                child: const Text(
                  'Contact',
                  style: TextStyle(color: Color(0xFF1a1a1a), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDesktop, double screenWidth) {
    return SizedBox(
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
                  const SizedBox(height: 24),
                  Text(
                    'Your trusted platform for construction contract management',
                    style: TextStyle(
                      fontSize: isDesktop ? 20 : 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
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
              fontSize: isDesktop ? 48 : 32,
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

  Widget _buildContracteeCard(BuildContext context) {
    return _RoleCard(
      color: Colors.amber,
      icon: Icons.person_outline,
      title: 'Contractee',
      description:
          'Browse contractors, view contracts, and monitor your projects seamlessly.',
      buttonText: 'Get Started',
      onPressed: () {
        try {
          if (kIsWeb) {
            // Redirect to contractee website - prevents going back
            redirectToUrl('https://contractee.contrust-sjdm.com');
          } else {
            Navigator.of(context).pushReplacementNamed('/contractee');
          }
        } catch (e) {
          ConTrustSnackBar.error(context, 'Error navigating to Contractee: $e');
        }
      },
    );
  }

  Widget _buildContractorCard(BuildContext context) {
    return _RoleCard(
      color: Colors.amber,
      icon: Icons.engineering_outlined,
      title: 'Contractor',
      description:
          'Sign in to bid for projects, manage contracts, and track your ongoing work.',
      buttonText: 'Get Started',
      onPressed: () {
        try {
          if (kIsWeb) {
            // Redirect to contractor website - prevents going back
            redirectToUrl('https://www.contractor.contrust-sjdm.com');
          } else {
            Navigator.of(context).pushReplacementNamed('/contractor');
          }
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
