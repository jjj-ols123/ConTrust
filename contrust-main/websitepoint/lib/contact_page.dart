// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:websitepoint/widgets/footer.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

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
              _buildHelpCenters(context, isDesktop, isTablet, isMobile),
              SizedBox(height: isMobile ? 16 : 24),
              _buildContactSection(context, isDesktop, isTablet, isMobile),
              const Footer(),
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
                child: const Text('About', style: TextStyle(color: Color(0xFF1a1a1a), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/services'),
                child: const Text('Services', style: TextStyle(color: Color(0xFF1a1a1a), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/contact'),
                child: const Text('Contact', style: TextStyle(color: Color(0xFF1a1a1a), fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close, size: isMobile ? 24 : 28),
                onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
                tooltip: 'Back',
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
    final double cardWidth = isDesktop ? 700 : (isTablet ? 640 : double.infinity);
    final double titleFontSize = isDesktop ? 64 : (isTablet ? 48 : 32);
    final double subtitleFontSize = isDesktop ? 24 : (isTablet ? 20 : 16);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: cardWidth),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 32,
              vertical: isMobile ? 28 : 36,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFA726).withOpacity(0.28),
                  const Color(0xFFFFA726).withOpacity(0.10),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TweenAnimationBuilder<double>(
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
                    'Contact Us',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1a1a1a),
                      letterSpacing: isMobile ? -0.5 : -1,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 10 : 12),
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
          ),
        ),
      ),
    );
  }

  Widget _buildHelpCenters(BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    final double horizontalPadding = isDesktop ? 80 : (isTablet ? 40 : 20);
    final double verticalPadding = isDesktop ? 40 : (isTablet ? 30 : 24);

    Widget card(String title, String desc) => Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF1a1a1a))),
              const SizedBox(height: 8),
              Text(desc, style: const TextStyle(color: Colors.black87)),
            ],
          ),
        );

    return Container(
      color: const Color(0xFFF3EBDC),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: isDesktop
            ? Row(
                children: [
                  Expanded(child: card('Contractor Help Center', 'Self-serve articles and help with the contractor app.')),
                  const SizedBox(width: 24),
                  Expanded(child: card('Worker Help Center', 'Self-serve articles for the app and in the field.')),
                ],
              )
            : Column(
                children: [
                  card('Contractor Help Center', 'Self-serve articles and help with the contractor app.'),
                  const SizedBox(height: 16),
                  card('Worker Help Center', 'Self-serve articles for the app and in the field.'),
                ],
              ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context, bool isDesktop, bool isTablet, bool isMobile) {
    final double horizontalPadding = isDesktop ? 80 : (isTablet ? 40 : 20);
    final double verticalPadding = isDesktop ? 80 : (isTablet ? 60 : 40);
    final double titleFontSize = isDesktop ? 48 : (isTablet ? 40 : 28);
    final double bodyFontSize = isDesktop ? 16 : (isTablet ? 15 : 14);

    InputDecoration deco(String label) => InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF6F1E2),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black38),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black38),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black87, width: 1.5),
          ),
          labelStyle: const TextStyle(color: Colors.black54),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        );

    Widget leftText() => Padding(
          padding: EdgeInsets.only(right: isDesktop ? 40 : 0, bottom: isDesktop ? 0 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Get in touch', style: TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.w900, color: const Color(0xFF1a1a1a))),
              const SizedBox(height: 12),
              Text(
                'Provide your info and some details on how we can help. Our support or sales team will get back to you within 24 hours.',
                style: TextStyle(fontSize: bodyFontSize, color: Colors.black87, height: 1.6),
              ),
            ],
          ),
        );

    Widget form() => Column(
          children: [
            Row(
              children: [
                Expanded(child: TextField(decoration: deco('First Name*'))),
                const SizedBox(width: 16),
                Expanded(child: TextField(decoration: deco('Last Name*'))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(decoration: deco('Phone Number*'))),
                const SizedBox(width: 16),
                Expanded(child: TextField(decoration: deco('Email*'))),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(decoration: deco('Location*'))),
                const SizedBox(width: 16),
                Expanded(child: TextField(decoration: deco('Company'))),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              maxLines: 4,
              decoration: deco("Message*").copyWith(alignLabelWithHint: true),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA726),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 24, vertical: isMobile ? 12 : 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Submit'),
              ),
            ),
          ],
        );

    return Container(
      color: const Color(0xFFD9D3C1),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: leftText()),
                    const SizedBox(width: 40),
                    Expanded(child: form()),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    leftText(),
                    form(),
                  ],
                ),
        ),
      ),
    );
  }
}
