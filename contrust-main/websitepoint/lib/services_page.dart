// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 900;
    final bool isTablet = screenWidth >= 600 && screenWidth < 900;
    final bool isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildNavigationBar(context, isDesktop, isTablet, isMobile),
              _buildHeroSection(context, isDesktop, isTablet, isMobile),
              _buildServicesOverview(context, isDesktop, isTablet, isMobile),
              _buildCoreServices(context, isDesktop, isTablet, isMobile),
              _buildCTA(context, isDesktop, isTablet, isMobile),
              _buildFooter(context, isDesktop, isTablet, isMobile),
            ],
          ),
        ),
      ),
    );
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
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
                Flexible(
                  child: Text(
                    'ConTrust',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1a1a1a),
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: isMobile ? 24 : 28),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back to Home',
            padding: EdgeInsets.all(isMobile ? 8 : 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    final double horizontalPadding = isDesktop ? 80 : (isTablet ? 40 : 20);
    final double verticalPadding = isDesktop ? 100 : (isTablet ? 70 : 50);
    final double titleFontSize = isDesktop ? 64 : (isTablet ? 48 : 32);
    final double subtitleFontSize = isDesktop ? 24 : (isTablet ? 20 : 16);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFA726).withOpacity(0.1),
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
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
                  'Our Services',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1a1a1a),
                    letterSpacing: isMobile ? -0.5 : -1,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isMobile ? 16 : 24),
                Container(
                  height: isMobile ? 3 : 4,
                  width: isMobile ? 60 : 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA726),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: isMobile ? 16 : 24),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 0),
                  child: Text(
                    'Comprehensive Solutions for Construction Contract Management',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: Colors.black54,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesOverview(BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    final double horizontalPadding = isDesktop ? 80 : (isTablet ? 40 : 20);
    final double verticalPadding = isDesktop ? 80 : (isTablet ? 60 : 40);
    final double bodyFontSize = isDesktop ? 18 : (isTablet ? 17 : 15);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 0),
            child: Text(
              'ConTrust provides a complete suite of tools designed to streamline construction project management, enhance transparency between contractors and contractees, and ensure successful project delivery from start to finish.',
              style: TextStyle(
                fontSize: bodyFontSize,
                color: Colors.black87,
                height: 1.8,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoreServices(BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    final double horizontalPadding = isDesktop ? 80 : (isTablet ? 40 : 20);
    final double verticalPadding = isDesktop ? 80 : (isTablet ? 60 : 40);
    final double titleFontSize = isDesktop ? 48 : (isTablet ? 38 : 28);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      color: const Color(0xFFFAFAFA),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Text(
                'Core Services',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1a1a1a),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isDesktop ? 60 : (isTablet ? 50 : 30)),
              _buildServiceCard(
                Icons.trending_up,
                'Real-Time Progress Updates',
                'Stay connected with your projects through live updates and milestone tracking. Monitor construction progress, receive instant notifications, and track every phase of your project in real-time.',
                [
                  'Live project status updates',
                  'Milestone completion tracking',
                  'Instant push notifications',
                  'Photo and video progress documentation',
                  'Timeline visualization',
                ],
                isDesktop, isTablet, isMobile,
              ),
              SizedBox(height: isMobile ? 20 : 30),
              _buildServiceCard(
                Icons.description_outlined,
                'Efficient Contract Management',
                'Simplify your contract lifecycle with our comprehensive management system. Create, store, and manage all your construction contracts in one secure, organized platform.',
                [
                  'Digital contract creation and storage',
                  'E-signature integration',
                  'Contract template library',
                  'Automated reminders and deadlines',
                  'Document version control',
                ],
                isDesktop, isTablet, isMobile,
              ),
              SizedBox(height: isMobile ? 20 : 30),
              _buildServiceCard(
                Icons.edit_outlined,
                'Visualization Editor',
                'Design and customize your contracts with our intuitive visual editor. Create professional contracts without legal jargon, making terms clear and understandable for all parties.',
                [
                  'Drag-and-drop contract builder',
                  'Visual term customization',
                  'Pre-built contract templates',
                  'Interactive clause library',
                  'Real-time preview and editing',
                ],
                isDesktop, isTablet, isMobile,
              ),
              SizedBox(height: isMobile ? 20 : 30),
              _buildServiceCard(
                Icons.handshake_outlined,
                'Contractor-Contractee Bridge',
                'Foster seamless communication and collaboration between contractors and clients. Our platform creates a transparent environment where both parties stay informed and connected.',
                [
                  'Secure messaging system',
                  'Project dashboard for all stakeholders',
                  'Collaborative document sharing',
                  'Dispute resolution tools',
                  'Transparent payment tracking',
                ],
                isDesktop, isTablet, isMobile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(IconData icon, String title, String description, List<String> features, bool isDesktop, bool isTablet, bool isMobile) {
    final double padding = isDesktop ? 32 : (isTablet ? 28 : 20);
    final double iconSize = isDesktop ? 56 : (isTablet ? 52 : 44);
    final double titleFontSize = isDesktop ? 28 : (isTablet ? 24 : 20);
    final double descFontSize = isDesktop ? 16 : (isTablet ? 15 : 14);
    final double featureFontSize = isDesktop ? 15 : (isTablet ? 14 : 13);
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 14 : 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFFFA726),
                  size: iconSize,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 20),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1a1a1a),
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Text(
            description,
            style: TextStyle(
              fontSize: descFontSize,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 20),
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Key Features:',
                  style: TextStyle(
                    fontSize: descFontSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1a1a1a),
                  ),
                ),
                SizedBox(height: isMobile ? 10 : 12),
                ...features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: isMobile ? 6 : 8,
                        height: isMobile ? 6 : 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFA726),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: featureFontSize,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTA(BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    final double horizontalPadding = isDesktop ? 80 : (isTablet ? 40 : 20);
    final double verticalPadding = isDesktop ? 80 : (isTablet ? 60 : 40);
    final double titleFontSize = isDesktop ? 42 : (isTablet ? 34 : 26);
    final double bodyFontSize = isDesktop ? 18 : (isTablet ? 17 : 15);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFA726).withOpacity(0.15),
            const Color(0xFFFFA726).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Icon(
                Icons.rocket_launch_outlined,
                color: const Color(0xFFFFA726),
                size: isDesktop ? 64 : (isTablet ? 56 : 48),
              ),
              SizedBox(height: isMobile ? 20 : 24),
              Text(
                'Ready to Transform Your Construction Projects?',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1a1a1a),
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 16 : 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 0),
                child: Text(
                  'Join ConTrust today and experience the future of construction contract management in San Jose Del Monte, Bulacan.',
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: isMobile ? 28 : 32),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA726),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 48 : (isMobile ? 32 : 40),
                    vertical: isDesktop ? 20 : (isMobile ? 14 : 16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : (isMobile ? 15 : 16),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
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
}


