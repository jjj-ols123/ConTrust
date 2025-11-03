// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      // Check if WebView is supported on this platform
      final isDesktop = !kIsWeb && 
        (defaultTargetPlatform == TargetPlatform.windows ||
         defaultTargetPlatform == TargetPlatform.linux ||
         defaultTargetPlatform == TargetPlatform.macOS);
      
      if (isDesktop) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'WebView is not supported on desktop platforms. This feature is only available on mobile devices (Android/iOS).';
          });
        }
        return;
      }

      // For web, we'll use iframe instead of WebView
      if (kIsWeb) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      final WebViewController controller = WebViewController();

      if (controller.platform is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(true);
        (controller.platform as AndroidWebViewController)
            .setMediaPlaybackRequiresUserGesture(false);
      }

      if (defaultTargetPlatform == TargetPlatform.iOS && controller.platform is WebKitWebViewController) {
        final webKitController = controller.platform as WebKitWebViewController;
        await webKitController.setAllowsBackForwardNavigationGestures(true);
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
  failingUrl: ${error.url}
            ''');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                // More specific error message based on error code
                if (error.errorCode == -2) {
                  _errorMessage = 'Unable to connect to the service. The Hugging Face space may be offline or the URL may be incorrect.';
                } else if (error.errorCode == -8) {
                  _errorMessage = 'Connection timeout. The service is taking too long to respond.';
                } else if (error.errorCode == -6) {
                  _errorMessage = 'Unable to find the service. Please verify the URL is correct.';
                } else {
                  _errorMessage = 'Failed to load: ${error.description}';
                }
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
          _errorMessage = 'Failed to initialize WebView: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _loadHuggingFaceSpace() async {
    if (_controller == null) {
      debugPrint('WebView controller is not initialized yet');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'WebView is not ready. Please try refreshing.';
        });
      }
      return;
    }
    
    try {
      // Wait a bit to ensure WebView is fully initialized
      await Future.delayed(const Duration(milliseconds: 300));
      
      const huggingFaceUrl = 'https://Ryg112-ConTrustAiModel.hf.space/';
      
      // Load the Hugging Face space
      await _controller!.loadRequest(Uri.parse(huggingFaceUrl));
      
      // Set a timeout - if still loading after 15 seconds, show error
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'The service took too long to load. The Hugging Face space might be temporarily unavailable.';
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading Hugging Face space: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to connect to the Wall Color Filter service. ${e.toString()}';
        });
      }
    }
  }

  Future<void> _injectCustomCSS() async {
    if (_controller == null) return;
    
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
      
      await _controller!.runJavaScript('''
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
        _errorMessage = null;
      });
    }
    if (kIsWeb) {
      // For web, just reload the iframe by rebuilding
      setState(() {});
    } else {
      _loadHuggingFaceSpace();
    }
  }

  Widget _buildWebIframe() {
    const huggingFaceUrl = 'https://Ryg112-ConTrustAiModel.hf.space/';
    const viewType = 'webview-iframe';
    
    // Register the platform view for web
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    // Create iframe element
    final iframe = html.IFrameElement()
      ..src = huggingFaceUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true;

     // Register platform view (only works on web)
     ui_web.platformViewRegistry.registerViewFactory(
       viewType,
       (int viewId) => iframe,
     );

    // ignore: undefined_prefixed_name
    return HtmlElementView(viewType: viewType);
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
                    Icons.palette,
                    size: 24,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Wall Color Filter',
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
                  : kIsWeb 
                      ? _buildWebIframe()
                      : (_controller == null
                          ? _buildErrorWidget()
                          : Stack(
                              children: [
                                WebViewWidget(controller: _controller!),
                                if (_isLoading) _buildLoadingWidget(),
                              ],
                            )),
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
              'Loading Wall Color Filter...',
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
                'Unable to load Wall Color Filter',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'The service may be temporarily unavailable. Please try again in a few moments.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
                maxLines: 10,
                overflow: TextOverflow.visible,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  // Show debug info
                  debugPrint('WebView Error Details:');
                  debugPrint('Error Message: $_errorMessage');
                  debugPrint('Is Loading: $_isLoading');
                  debugPrint('Has Error: $_hasError');
                },
                child: const Text(
                  'Troubleshooting Tips',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    decoration: TextDecoration.underline,
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