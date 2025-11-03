// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      final WebViewController controller = WebViewController();

      if (controller.platform is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(true);
        (controller.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      }

      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(const Color(0x00000000));
      
      controller.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            debugPrint('WebView is loading (progress: $progress%)');
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            // Inject CSS to hide Hugging Face header and URL elements
            _injectCustomCSS();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
            ''');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation to keep the user within the Hugging Face space
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            debugPrint('url change to ${change.url}');
          },
        ),
      );

      _controller = controller;
      
      // Load the Hugging Face space
      await _loadHuggingFaceSpace();
      
    } catch (e) {
      debugPrint('WebView initialization failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _loadHuggingFaceSpace() async {
    try {
      await _controller.loadRequest(
        Uri.parse('https://ryg112-contrustaimodel.hf.space/'),
      );
    } catch (e) {
      debugPrint('Error loading Hugging Face space: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _injectCustomCSS() async {
    try {
      final String css = '''
        <style>
          /* Hide Hugging Face header and footer */
          header, 
          .header,
          .gradio-header,
          [data-testid="header"],
          footer,
          .footer,
          .gradio-footer,
          [data-testid="footer"] {
            display: none !important;
          }
          
          /* Hide any URL bars or navigation elements */
          .navbar,
          .navigation,
          .breadcrumb,
          .url-bar,
          .address-bar {
            display: none !important;
          }
          
          /* Make the content take full height */
          body, .gradio-container, #root, [data-testid="container"] {
            padding: 0 !important;
            margin: 0 !important;
            min-height: 100vh !important;
          }
          
          /* Ensure the main content is visible */
          .gradio-row, .container, main, #component-0 {
            min-height: 100vh !important;
            height: 100% !important;
            padding-top: 0 !important;
          }
          
          /* Hide any Hugging Face branding that might show URLs */
          .hf-logo, .space-header, .space-title {
            display: none !important;
          }
          
          /* Hide scrollbars if they reveal URLs */
          ::-webkit-scrollbar {
            display: none !important;
          }
        </style>
      ''';
      
      await _controller.runJavaScript('''
        if (document && document.head) {
          var style = document.createElement('style');
          style.innerHTML = `$css`;
          document.head.appendChild(style);
        }
      ''');
    } catch (e) {
      debugPrint('Error injecting CSS: $e');
    }
  }

  void _refreshPage() {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
    _loadHuggingFaceSpace();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar - No URL shown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.smart_toy,
                    size: 24,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AI Assistant',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _refreshPage,
                    icon: Icon(
                      Icons.refresh,
                      color: Colors.amber.shade700,
                    ),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),
            Expanded(
              child: _hasError
                  ? _buildErrorWidget()
                  : Stack(
                      children: [
                        WebViewWidget(controller: _controller),
                        if (_isLoading) _buildLoadingWidget(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade700),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading AI Assistant...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Unable to load AI Assistant',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your internet connection and try again.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshPage,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}