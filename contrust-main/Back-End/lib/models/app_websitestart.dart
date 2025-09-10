import 'package:contractee/pages/cee_welcome.dart';
import 'package:contractor/Screen/cor_startup.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WebsiteStartPage extends StatelessWidget {
  const WebsiteStartPage({super.key});

  bool get _isWeb => kIsWeb;

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width >= 900;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.amber[50],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Welcome to ConTrust',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you want to continue',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 1,
                      child: _RoleCard(
                        color: Colors.blue,
                        icon: Icons.person_outline,
                        title: 'Contractee',
                        description:
                            'Browse contractors, manage contracts and monitor your projects.',
                        buttonText: 'Continue as Contractee',
                        onPressed: () {
                          print('Contractee button pressed');
                          try {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const WelcomePage()),
                            );
                            print('Navigation successful');
                          } catch (e) {
                            print('Navigation error: $e');
                          }
                        },
                      ),
                    ),
                    SizedBox(width: isWide ? 24 : 0, height: isWide ? 0 : 24),
                    Expanded(
                      flex: 1,
                      child: _RoleCard(
                        color: Colors.teal,
                        icon: Icons.engineering_outlined,
                        title: 'Contractor',
                        description:
                            'Sign in to manage bids, contracts, clients, and ongoing projects.',
                        buttonText: 'Continue as Contractor',
                        onPressed: () {
                          print('Contractor button pressed');
                          try {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ToLoginScreen()),
                            );
                            print('Navigation successful');
                          } catch (e) {
                            print('Navigation error: $e');
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
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
    );
  }
}

class _RoleCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                print('GestureDetector tapped: $buttonText');
                onPressed();
              },
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                  ),
                  onPressed: () {
                    print('Button pressed: $buttonText');
                    onPressed();
                  },
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

