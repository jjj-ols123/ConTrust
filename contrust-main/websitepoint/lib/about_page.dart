// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
              _buildMissionSection(context, isDesktop, isTablet, isMobile),
              _buildProjectInfoSection(context, isDesktop, isTablet, isMobile),
              _buildTeamSection(context, isDesktop, isTablet, isMobile),
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
              IconButton(
                icon: Icon(Icons.close, size: isMobile ? 24 : 28),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back to Home',
                padding: EdgeInsets.all(isMobile ? 8 : 12),
              ),
            ],
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
                  'About ConTrust',
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
                    'Building Trust in Construction, One Contract at a Time',
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

  Widget _buildMissionSection(BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    final double horizontalPadding = isDesktop ? 80 : (isTablet ? 40 : 20);
    final double verticalPadding = isDesktop ? 80 : (isTablet ? 60 : 40);
    final double titleFontSize = isDesktop ? 48 : (isTablet ? 38 : 28);
    final double bodyFontSize = isDesktop ? 18 : (isTablet ? 17 : 15);
    
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
              Text(
                'Our Mission',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1a1a1a),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 24 : 40),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 0),
                child: Text(
                  'ConTrust is designed to revolutionize construction contract management by providing a transparent, efficient, and trustworthy platform that bridges contractors and contractees. We empower both parties with real-time progress updates, comprehensive contract management tools, and intuitive visualization editors.',
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    color: Colors.black87,
                    height: 1.8,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: isDesktop ? 60 : (isTablet ? 50 : 30)),
              isDesktop
                  ? Row(
                      children: [
                        Expanded(child: _buildValueCard(
                          Icons.visibility_outlined,
                          'Transparency',
                          'Real-time updates and clear communication throughout the project lifecycle.',
                          isDesktop, isTablet, isMobile,
                        )),
                        const SizedBox(width: 30),
                        Expanded(child: _buildValueCard(
                          Icons.security_outlined,
                          'Trust',
                          'Secure contract management with verified documentation and milestone tracking.',
                          isDesktop, isTablet, isMobile,
                        )),
                        const SizedBox(width: 30),
                        Expanded(child: _buildValueCard(
                          Icons.speed_outlined,
                          'Efficiency',
                          'Streamlined processes that save time and reduce administrative overhead.',
                          isDesktop, isTablet, isMobile,
                        )),
                      ],
                    )
                  : Column(
                      children: [
                        _buildValueCard(
                          Icons.visibility_outlined,
                          'Transparency',
                          'Real-time updates and clear communication throughout the project lifecycle.',
                          isDesktop, isTablet, isMobile,
                        ),
                        const SizedBox(height: 20),
                        _buildValueCard(
                          Icons.security_outlined,
                          'Trust',
                          'Secure contract management with verified documentation and milestone tracking.',
                          isDesktop, isTablet, isMobile,
                        ),
                        const SizedBox(height: 20),
                        _buildValueCard(
                          Icons.speed_outlined,
                          'Efficiency',
                          'Streamlined processes that save time and reduce administrative overhead.',
                          isDesktop, isTablet, isMobile,
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueCard(IconData icon, String title, String description, bool isDesktop, bool isTablet, bool isMobile) {
    final double cardPadding = isDesktop ? 32 : (isTablet ? 28 : 20);
    final double iconSize = isDesktop ? 48 : (isTablet ? 44 : 36);
    final double titleFontSize = isDesktop ? 24 : (isTablet ? 22 : 18);
    final double descFontSize = isDesktop ? 16 : (isTablet ? 15 : 13);
    
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
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
          SizedBox(height: isMobile ? 16 : 20),
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1a1a1a),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            description,
            style: TextStyle(
              fontSize: descFontSize,
              color: Colors.black54,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectInfoSection(BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    final double horizontalPadding = isDesktop ? 80 : (isTablet ? 40 : 20);
    final double verticalPadding = isDesktop ? 80 : (isTablet ? 60 : 40);
    final double titleFontSize = isDesktop ? 48 : (isTablet ? 38 : 28);
    final double bodyFontSize = isDesktop ? 18 : (isTablet ? 17 : 15);
    
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
                'Why ConTrust?',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1a1a1a),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 24 : 40),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 0),
                child: Text(
                  'The construction industry in San Jose Del Monte, Bulacan, and beyond faces challenges in managing contracts, tracking progress, and maintaining trust between contractors and clients. ConTrust was born from the need to address these pain points.',
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    color: Colors.black87,
                    height: 1.8,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: isDesktop ? 60 : (isTablet ? 50 : 30)),
              _buildFeaturesList(isDesktop, isTablet, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList(bool isDesktop, bool isTablet, bool isMobile) {
    final features = [
      {
        'icon': Icons.assignment_outlined,
        'title': 'Comprehensive Contract Management',
        'description': 'Create, manage, and track construction contracts with ease.',
      },
      {
        'icon': Icons.update_outlined,
        'title': 'Real-Time Progress Updates',
        'description': 'Stay informed with live updates on project milestones and status.',
      },
      {
        'icon': Icons.edit_outlined,
        'title': 'Visual Contract Editor',
        'description': 'Intuitive tools to create and customize contract terms visually.',
      },
      {
        'icon': Icons.people_outline,
        'title': 'Contractor-Contractee Bridge',
        'description': 'Seamless communication and collaboration between all parties.',
      },
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: EdgeInsets.only(bottom: isMobile ? 16 : 24),
          child: _buildFeatureItem(
            feature['icon'] as IconData,
            feature['title'] as String,
            feature['description'] as String,
            isDesktop, isTablet, isMobile,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description, bool isDesktop, bool isTablet, bool isMobile) {
    final double padding = isDesktop ? 24 : (isTablet ? 20 : 16);
    final double iconSize = isDesktop ? 32 : (isTablet ? 30 : 24);
    final double iconPadding = isDesktop ? 12 : (isMobile ? 10 : 12);
    final double titleFontSize = isDesktop ? 20 : (isTablet ? 18 : 16);
    final double descFontSize = isDesktop ? 16 : (isTablet ? 15 : 14);
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(iconPadding),
            decoration: BoxDecoration(
              color: const Color(0xFFFFA726).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFFA726),
              size: iconSize,
            ),
          ),
          SizedBox(width: isMobile ? 12 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1a1a1a),
                  ),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: descFontSize,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection(BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    final double horizontalPadding = isDesktop ? 80 : (isTablet ? 40 : 20);
    final double verticalPadding = isDesktop ? 80 : (isTablet ? 60 : 40);
    final double titleFontSize = isDesktop ? 48 : (isTablet ? 38 : 28);
    final double bodyFontSize = isDesktop ? 18 : (isTablet ? 17 : 15);
    
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
              Text(
                'Meet the Team',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1a1a1a),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 16 : 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 0),
                child: Text(
                  'ConTrust is developed by a dedicated team of proponents committed to transforming the construction industry in San Jose Del Monte, Bulacan.',
                  style: TextStyle(
                    fontSize: bodyFontSize,
                    color: Colors.black54,
                    height: 1.8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: isDesktop ? 60 : (isTablet ? 50 : 30)),
              _buildLocationInfo(isDesktop, isTablet, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo(bool isDesktop, bool isTablet, bool isMobile) {
    final double padding = isDesktop ? 40 : (isTablet ? 32 : 20);
    final double iconSize = isDesktop ? 56 : (isTablet ? 52 : 40);
    final double titleFontSize = isDesktop ? 28 : (isTablet ? 24 : 20);
    final double descFontSize = isDesktop ? 16 : (isTablet ? 15 : 14);
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFA726).withOpacity(0.1),
            const Color(0xFFFFA726).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFA726).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_on_outlined,
            color: const Color(0xFFFFA726),
            size: iconSize,
          ),
          SizedBox(height: isMobile ? 12 : 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 0),
            child: Text(
              'San Jose Del Monte, Bulacan',
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1a1a1a),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 0),
            child: Text(
              'Proudly serving the construction community with innovative solutions for contract management and project transparency.',
              style: TextStyle(
                fontSize: descFontSize,
                color: Colors.black87,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
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

