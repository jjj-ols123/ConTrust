// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contractor/Screen/cor_startup.dart';
import 'package:contractee/pages/cee_login.dart';

class MobileStartPage extends StatefulWidget {
  const MobileStartPage({super.key});

  @override
  State<MobileStartPage> createState() => _MobileStartPageState();
}

class _MobileStartPageState extends State<MobileStartPage> {
  String? _selectedRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedRole();
  }

  Future<void> _loadSavedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRole = prefs.getString('preferredRole');
      if (mounted) {
        setState(() {
          _selectedRole = savedRole;
          _isLoading = false;
        });

      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferredRole', role);
      setState(() {
        _selectedRole = role;
      });
    } catch (e) {
      //
    }
  }

  void _navigateToRole(String role) async {
    await _selectRole(role);
    
    if (!mounted) return;
    
    if (role == 'contractor') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const ToLoginScreen(),
        ),
      );
    } else if (role == 'contractee') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFA726)),
        ),
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final isDesktop = screenSize.width >= 900;
    final isTablet = screenSize.width >= 600 && screenSize.width < 900;
    final isMobile = screenSize.width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image(
                image: const AssetImage('assets/bgloginscreen.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(isSmallScreen),
                  SizedBox(height: isMobile ? 40 : 60),
                  _buildHeroSection(isDesktop, isTablet, isMobile),
                  SizedBox(height: isMobile ? 40 : 60),
                  _buildRoleSelection(isDesktop, isTablet, isMobile),
                  SizedBox(height: isMobile ? 30 : 40),
                  if (_selectedRole != null) _buildSwitchRoleButton(isMobile),
                  SizedBox(height: isMobile ? 20 : 30),
                  _buildFooter(isDesktop, isTablet, isMobile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: isSmallScreen ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: isSmallScreen ? 4 : 6,
            height: isSmallScreen ? 28 : 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFA726),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Text(
            'ConTrust',
            style: TextStyle(
              fontSize: isSmallScreen ? 24 : 28,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1a1a1a),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(bool isDesktop, bool isTablet, bool isMobile) {
    final double titleFontSize = isDesktop ? 48 : (isTablet ? 36 : 28);
    final double subtitleFontSize = isDesktop ? 18 : (isTablet ? 16 : 14);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
      child: Column(
        children: [
          Text(
            'Welcome to ConTrust',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            'Choose your role to get started',
            style: TextStyle(
              fontSize: subtitleFontSize,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelection(bool isDesktop, bool isTablet, bool isMobile) {
    final double horizontalPadding = isDesktop ? 80 : (isTablet ? 40 : 20);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: _buildRoleCard('contractee', isDesktop, isTablet, isMobile)),
                const SizedBox(width: 40),
                Expanded(child: _buildRoleCard('contractor', isDesktop, isTablet, isMobile)),
              ],
            )
          : Column(
              children: [
                _buildRoleCard('contractee', isDesktop, isTablet, isMobile),
                SizedBox(height: isMobile ? 20 : 30),
                _buildRoleCard('contractor', isDesktop, isTablet, isMobile),
              ],
            ),
    );
  }

  Widget _buildRoleCard(String role, bool isDesktop, bool isTablet, bool isMobile) {
    final isSelected = _selectedRole == role;
    final isContractee = role == 'contractee';
    
    return GestureDetector(
      onTap: () => _navigateToRole(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          border: Border.all(
            color: isSelected ? const Color(0xFFFFA726) : Colors.grey.shade300,
            width: isSelected ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFFFA726).withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isSelected ? 20 : 10,
              offset: Offset(0, isSelected ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA726).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isContractee ? Icons.person_outline : Icons.engineering_outlined,
                color: const Color(0xFFFFA726),
                size: isMobile ? 48 : 56,
              ),
            ),
            SizedBox(height: isMobile ? 20 : 24),
            Text(
              isContractee ? 'Contractee' : 'Contractor',
              style: TextStyle(
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1a1a1a),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              isContractee
                  ? 'Browse contractors, view contracts, and monitor your projects.'
                  : 'Bid for projects, manage contracts, and track your work.',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 20 : 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFA726),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Get Started',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            if (isSelected) ...[
              SizedBox(height: isMobile ? 12 : 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: const Color(0xFFFFA726),
                    size: isMobile ? 20 : 24,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Selected',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: const Color(0xFFFFA726),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRoleButton(bool isMobile) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 40),
      child: TextButton(
        onPressed: () {
          setState(() {
            _selectedRole = null;
          });
          SharedPreferences.getInstance().then((prefs) {
            prefs.remove('preferredRole');
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz,
              color: Colors.white.withOpacity(0.8),
              size: isMobile ? 20 : 24,
            ),
            SizedBox(width: 8),
            Text(
              'Switch to ${_selectedRole == 'contractor' ? 'Contractee' : 'Contractor'}',
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDesktop, bool isTablet, bool isMobile) {
    final double horizontalPadding = isDesktop ? 80 : (isTablet ? 40 : 20);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isMobile ? 20 : 30,
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
                width: isMobile ? 3 : 4,
                height: isMobile ? 20 : 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: isMobile ? 8 : 10),
              Text(
                'ConTrust',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
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
        ],
      ),
    );
  }
}

