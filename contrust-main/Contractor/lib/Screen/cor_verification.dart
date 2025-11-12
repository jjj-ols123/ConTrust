// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    hide WebResourceError;

import 'package:backend/build/html_stub.dart' if (dart.library.html) 'dart:html'
    as html;
import 'package:backend/build/ui_web_stub.dart'
    if (dart.library.html) 'dart:ui_web' as ui_web;

class VerificationPage extends StatefulWidget {
  const VerificationPage({super.key});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
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
            _errorMessage =
                'WebView is not supported on desktop platforms. This feature is only available on mobile devices (Android/iOS).';
          });
        }
        return;
      }

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
        final androidController =
            controller.platform as AndroidWebViewController;
        androidController.setMediaPlaybackRequiresUserGesture(false);
      }

      if (defaultTargetPlatform == TargetPlatform.iOS &&
          controller.platform is WebKitWebViewController) {
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
                  _errorMessage =
                      'Unable to connect to the service. The verification service may be offline or the URL may be incorrect.';
                } else if (error.errorCode == -8) {
                  _errorMessage =
                      'Connection timeout. The service is taking too long to respond.';
                } else if (error.errorCode == -6) {
                  _errorMessage =
                      'Unable to find the service. Please verify the URL is correct.';
                } else {
                  _errorMessage = 'Failed to load: ${error.description}';
                }
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Allow all navigation to keep the user within the verification service
            return NavigationDecision.navigate;
          },
          onUrlChange: (UrlChange change) {
            debugPrint('url change to ${change.url}');
          },
        ),
      );

      _controller = controller;

      // Load the verification service
      await _loadVerificationService();
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

  Future<void> _loadVerificationService() async {
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

      const verificationUrl = 'https://contrust-verification-production-4fa7.up.railway.app/';

      // Load the verification service
      await _controller!.loadRequest(Uri.parse(verificationUrl));

      // Set a timeout - if still loading after 15 seconds, show error
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && _isLoading) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage =
                'The service took too long to load. The verification service might be temporarily unavailable.';
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading verification service: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage =
              'Failed to connect to the verification service. ${e.toString()}';
        });
      }
    }
  }

  Future<void> _injectCustomCSS() async {
    if (_controller == null) return;

    try {
      final String css = '''
        <style>
          /* Hide header and footer if any */
          header, 
          .header,
          footer,
          .footer {
            display: none !important;
          }
          
          /* Hide any navigation elements */
          .navbar,
          .navigation,
          .breadcrumb,
          .url-bar,
          .address-bar {
            display: none !important;
          }
          
          /* Make the content take full height */
          body, .container, main, #root {
            padding: 0 !important;
            margin: 0 !important;
            min-height: 100vh !important;
          }
          
          /* Ensure the main content is visible */
          .row, .container, main, #component-0 {
            min-height: 100vh !important;
            height: 100% !important;
            padding-top: 0 !important;
          }
          
          /* Hide branding that might show URLs */
          .logo, .brand, .title {
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

          var viewport = document.querySelector('meta[name="viewport"]');
          if (!viewport) {
            viewport = document.createElement('meta');
            viewport.name = 'viewport';
            document.head.appendChild(viewport);
          }
          viewport.setAttribute('content', 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no');
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
      setState(() {});
    } else {
      _loadVerificationService();
    }
  }

  Widget _buildWebIframe() {
    const verificationUrl = 'https://contrust-verification-production-4fa7.up.railway.app/';
    const viewType = 'webview-iframe';

    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    final iframe = html.IFrameElement()
      ..src = verificationUrl
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true;

    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) => iframe,
    );

    // ignore: undefined_prefixed_name
    return HtmlElementView(viewType: viewType);
  }

  Widget _buildInAppWebViewAndroid() {
    const verificationUrl = 'https://contrust-verification-production-4fa7.up.railway.app/';
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(verificationUrl)),
      initialSettings: InAppWebViewSettings(
        mediaPlaybackRequiresUserGesture: false,
        javaScriptEnabled: true,
        verticalScrollBarEnabled: true,
        displayZoomControls: false,
        supportZoom: false,
        builtInZoomControls: false,
        useWideViewPort: true,
        transparentBackground: false,
      ),
      onPermissionRequest: (controller, request) async {
        return PermissionResponse(
          resources: request.resources,
          action: PermissionResponseAction.GRANT,
        );
      },
      onLoadStart: (controller, url) {
        if (mounted) {
          setState(() {
            _isLoading = true;
            _hasError = false;
          });
        }
      },
      onLoadStop: (controller, url) async {
        // Ensure page remains scrollable even after dynamic content loads
        try {
          await controller.evaluateJavascript(source: r'''
            (function(){
              try {
                var style = document.createElement('style');
                style.innerHTML = `
                  html, body, #root, .container { 
                    overflow: auto !important; 
                    height: auto !important; 
                    max-height: none !important; 
                  }
                  * { overscroll-behavior: contain; }
                `;
                document.head && document.head.appendChild(style);
                // Fix cases where container sets overflow hidden after rendering
                document.querySelectorAll('*').forEach(function(el){
                  var cs = getComputedStyle(el);
                  if (cs.overflow === 'hidden' && (cs.height === '100vh' || cs.height === '100%')) {
                    el.style.overflow = 'auto';
                  }
                });
              } catch(e){}
            })();
          ''');
        } catch (_) {}

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
      onLoadError: (controller, url, code, message) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Failed to load: $message ($code)';
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.amber,
        centerTitle: true,
        elevation: 4,
        automaticallyImplyLeading: false,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            Container(
              height: 32,
              width: 32,
              margin: const EdgeInsets.only(left: 8),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.business, color: Colors.black, size: 24);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.only(left: 8),
              child: const Text(
                'ConTrust',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  shadows: [
                    Shadow(
                      color: Colors.white,
                      offset: Offset(0, 1),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        title: const Text(
          'Account Verification',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _hasError
                  ? _buildErrorWidget()
                  : kIsWeb
                      ? _buildWebIframe()
                      : (defaultTargetPlatform == TargetPlatform.android
                          ? _buildInAppWebViewAndroid()
                          : (_controller == null
                              ? _buildErrorWidget()
                              : _isLoading
                                  ? _buildLoadingWidget()
                                  : WebViewWidget(controller: _controller!))),
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
              'Loading Verification Service...',
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
                'Unable to load Verification Service',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ??
                    'The service may be temporarily unavailable. Please try again in a few moments.',
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
