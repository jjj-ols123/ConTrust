// ignore_for_file: deprecated_member_use

import 'package:backend/utils/be_pagetransition.dart';
import 'package:backend/utils/be_validation.dart';
import 'package:contractee/pages/cee_registration.dart';
import 'package:flutter/material.dart';
import 'package:backend/services/contractee services/cee_signin.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isAgreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade100,
              Colors.white,
              Colors.grey.shade100,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: 400,
              padding: const EdgeInsets.all(28),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: _buildLoginForm(context),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildLoginForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.amber.shade400),
            const SizedBox(height: 12),
            Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Login to your account',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 30),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email_outlined),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextFormField(
          controller: _passwordController,
          keyboardType: TextInputType.visiblePassword,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 25),
        ElevatedButton(
          onPressed: () async {
            if (!_isAgreed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'You must agree to the Privacy Policy and Terms of Service.',
                  ),
                ),
              );
              return;
            }

            final signInContractee = SignInContractee();
            signInContractee.signInContractee(
              context,
              _emailController.text,
              _passwordController.text,
              () => validateFieldsLogin(
                context,
                _emailController.text,
                _passwordController.text,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade400,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: const Text(
            'Login',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                'Or Continue With',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
          ],
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () {
            SignInGoogleContractee().signInGoogle(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/googleicon.png', height: 28),
                const SizedBox(width: 12),
                const Text(
                  "Continue with Google",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 25),
        Row(
          children: [
            Checkbox(
              value: _isAgreed,
              onChanged: (val) {
                setState(() {
                  _isAgreed = val ?? false;
                });
              },
            ),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.start,
                children: [
                  const Text(
                    "I agree to the ",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  InkWell(
                    onTap: () => _showPolicyTabs(context),
                    child: Text(
                      "Privacy Policy and Terms of Service",
                      style: TextStyle(
                        color: Colors.teal.shade600,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        InkWell(
          onTap: () {
            transitionBuilder(context, RegistrationPage());
          },
          child: Text.rich(
            TextSpan(
              text: "Don't have an account? ",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              children: [
                TextSpan(
                  text: "Sign up",
                  style: TextStyle(
                    color: Colors.teal.shade600,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  void _showPolicyTabs(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: AlertDialog(
          title: const Text("Policies"),
          content: SizedBox(
            height: 400,
            width: 350,
            child: Column(
              children: [
                const TabBar(
                  labelColor: Colors.teal,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: "Privacy Policy"),
                    Tab(text: "Terms of Service"),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBarView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: const Text(
                            "ConTrust – Terms and Conditions for Contractees (Clients)\n\n"
                            "1. Acceptance of Terms\n\n"
                            "By registering and using the ConTrust platform as a Contractee (Client), you agree to comply with and be bound by these Terms and Conditions. These terms constitute a legal agreement between you (“Contractee”) and ConTrust, governing your access and use of all platform services, features, and tools.\n\n"
                            
                            "2. User Eligibility and Verification\n\n"
                            "Contractees must be 18 years old and above and legally capable of entering into contracts.\n\n"
                            "Upon registration, users are required to submit valid identification for account verification.\n\n"
                            "ConTrust reserves the right to verify, suspend, or terminate any user account found to have submitted false, misleading, or fraudulent information.\n\n"
                            
                            "3. Use of the Platform\n\n"
                            "Contractees may use ConTrust for:\n\n"
                            "• Searching, comparing, and hiring verified contractor firms.\n"
                            "• Viewing contractor portfolios, previous projects, and ratings.\n"
                            "• Managing contracts, tracking real-time project progress, and communicating with contractors through the chat system.\n"
                            "• Posting property projects for bidding by contractors.\n\n"
                            "Users must not use the platform for illegal, abusive, or deceptive activities.\n\n"
                            
                            "4. Responsibilities of Contractees\n\n"
                            "Contractees agree to:\n\n"
                            "• Provide accurate project details when requesting services or posting projects for bidding.\n"
                            "• Respect agreed-upon contract terms, including payment schedules and project timelines.\n"
                            "• Maintain professional communication with contractors and ConTrust administrators.\n"
                            "• Avoid posting false reviews or engaging in defamatory actions against contractors.\n\n"
                            "Failure to comply may result in account restriction or permanent suspension.\n\n"
                            
                            "5. Contracts and Transactions\n\n"
                            "All contracts created through ConTrust are binding agreements between the contractee and the contractor once both parties have approved and signed them digitally.\n\n"
                            "ConTrust acts only as a digital intermediary and is not a party to the contract.\n\n"
                            "Payment terms, scope of work, and responsibilities of both parties must be clearly stated in the contract before approval.\n\n"
                            "Contractees must ensure timely payments as indicated in the agreement.\n\n"
                            
                            "6. Bidding and Project Posting\n\n"
                            "Contractees may post project requests with relevant details such as budget, timeline, and project scope.\n\n"
                            "Contractors may submit bids and proposals for these projects.\n\n"
                            "The contractee may freely select among the proposals but must not misuse the bidding system for non-serious or fraudulent postings.\n\n"
                            
                            "7. Real-Time Progress Updates\n\n"
                            "Contractees can monitor their project’s development through progress reports, photos, and cost breakdowns uploaded by contractors.\n\n"
                            "ConTrust is not liable for inaccuracies or delays in updates provided by contractors.\n\n"
                            
                            "8. Data Privacy and Security\n\n"
                            "ConTrust collects and processes personal data in accordance with its Privacy Policy and the Data Privacy Act of 2012 (Republic Act No. 10173).\n\n"
                            "Contractees’ information, including ID verification and project details, will be stored securely via Firebase Cloud Database.\n\n"
                            "Contractees must not share sensitive account data (such as passwords or contract documents) with unauthorized parties.\n\n"
                            
                            "9. Dispute Resolution\n\n"
                            "Disputes between contractors and contractees must first be resolved through direct communication within the platform’s chat feature.\n\n"
                            "If unresolved, ConTrust may assist in document verification and communication mediation, but it is not liable for the final outcome of any dispute.\n\n"
                            "Legal disputes shall be settled under Philippine law.\n\n"
                            
                            "10. Limitation of Liability\n\n"
                            "ConTrust shall not be liable for:\n\n"
                            "• Any project delays, cost overruns, or contract breaches by either party.\n"
                            "• Misunderstandings or miscommunications between contractors and contractees.\n"
                            "• System downtime, data loss, or external hacking beyond ConTrust’s control.\n\n"
                            "The platform serves solely as a digital facilitator for connections and contract management.\n\n"
                            
                            "11. Account Suspension and Termination\n\n"
                            "ConTrust reserves the right to:\n\n"
                            "• Suspend or terminate accounts engaged in misconduct, fraud, or repeated policy violations.\n"
                            "• Remove project listings or reviews that violate these terms or applicable laws.\n\n"
                            
                            "12. Updates to Terms\n\n"
                            "ConTrust may update these Terms and Conditions at any time. Continued use of the platform after updates constitutes acceptance of the revised terms.\n\n"
                            
                            "13. Governing Law\n\n"
                            "These Terms and Conditions are governed by the laws of the Republic of the Philippines, specifically under the jurisdiction of San Jose del Monte, Bulacan.\n",
                            style: TextStyle(
                              fontSize: 14.0,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: const Text(
                            "ConTrust – Privacy Policy for Contractees (Clients)\n\n"
                            "1. Information We Collect\n\n"
                            "We collect personal and project-related data including name, contact details, uploaded IDs, project posts, chat messages, and payment information.\n\n"

                            "2. Purpose of Data Collection\n\n"
                            "We use this data to verify identity, manage projects, enable communication with contractors, and ensure secure contract transactions.\n\n"

                            "3. Data Storage and Protection\n\n"
                            "All data is securely stored in Firebase Cloud Database using encryption and access control to prevent unauthorized use.\n\n"

                            "4. Data Sharing and Use\n\n"
                            "ConTrust does not sell or trade user data. Information is shared only with verified contractors or when legally required.\n\n"

                            "5. User Rights\n\n"
                            "Contractees may access, modify, or delete their personal information and request account removal at any time.\n\n"

                            "6. Cookies and Analytics\n\n"
                            "ConTrust uses cookies for improving platform functionality but does not collect sensitive data through them.\n\n"

                            "7. Data Retention\n\n"
                            "Your data is stored as long as needed for project management or as required by law. Once deleted, identifiers are permanently removed.\n\n"

                            "8. Privacy Policy Updates\n\n"
                            "This policy may be updated from time to time. Updates will be posted on the ConTrust platform.\n\n"

                            "9. Contact Information\n\n"
                            "For any data concerns, contact us at support@contrust.ph or visit San Jose del Monte, Bulacan.\n",
                            style: TextStyle(
                              fontSize: 14.0, 
                              height: 1.6, 
                              color: Colors.black87
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Close"),
            ),
          ],
        ),
      ),
    );
  }
}
