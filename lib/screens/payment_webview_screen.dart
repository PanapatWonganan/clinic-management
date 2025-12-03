import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../services/api_service.dart';
import '../widgets/custom_app_bar.dart';
import 'payment_success_screen.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final int paymentId;
  final int orderId;
  final String orderNumber;
  final double totalAmount;

  const PaymentWebViewScreen({
    super.key,
    required this.paymentUrl,
    required this.paymentId,
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isCheckingStatus = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      // For web, don't auto-open (browsers block popups)
      // User will click button to open
      // Start polling payment status
      _startStatusPolling();
    } else {
      // For mobile, initialize WebView
      _initializeWebView();
    }
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });

            // Check if we're on success/cancel URL
            _checkUrlForPaymentResult(url);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
            setState(() {
              _isLoading = false;
              _errorMessage = 'เกิดข้อผิดพลาดในการโหลดหน้าชำระเงิน';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            debugPrint('Navigation request: ${request.url}');
            _checkUrlForPaymentResult(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  Future<void> _openPaymentUrlInNewTab() async {
    // For web platform, automatically open payment URL in new tab
    try {
      final Uri uri = Uri.parse(widget.paymentUrl);

      // Launch URL in new tab
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        debugPrint('Failed to launch payment URL');
        // Show fallback dialog with URL if auto-launch fails
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showManualUrlDialog();
          });
        }
      } else {
        debugPrint('Payment URL opened successfully');
      }
    } catch (e) {
      debugPrint('Error launching payment URL: $e');
      // Show fallback dialog with URL if error occurs
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showManualUrlDialog();
        });
      }
    }
  }

  void _showManualUrlDialog() {
    // Fallback dialog if auto-launch fails
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('เปิดหน้าชำระเงิน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ไม่สามารถเปิดหน้าชำระเงินอัตโนมัติได้\nกรุณาคัดลอก URL ด้านล่างและเปิดในแท็บใหม่:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                widget.paymentUrl,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'หลังจากชำระเงินเสร็จ ระบบจะตรวจสอบสถานะอัตโนมัติ',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to checkout
            },
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainPurple,
            ),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _checkUrlForPaymentResult(String url) {
    // Check if URL indicates payment success or cancellation
    if (url.contains('/payment/success') || url.contains('success')) {
      _handlePaymentSuccess();
    } else if (url.contains('/payment/cancel') || url.contains('cancel')) {
      _handlePaymentCancelled();
    }
  }

  Future<void> _handlePaymentSuccess() async {
    if (_isCheckingStatus) return;

    setState(() {
      _isCheckingStatus = true;
    });

    // Wait a bit for callback to process
    await Future.delayed(const Duration(seconds: 2));

    // Check payment status
    await _checkPaymentStatus(expectSuccess: true);
  }

  Future<void> _handlePaymentCancelled() async {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยกเลิกการชำระเงิน'),
        content: const Text('คุณได้ยกเลิกการชำระเงิน กรุณาลองใหม่อีกครั้ง'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to checkout
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkPaymentStatus({bool expectSuccess = false}) async {
    try {
      final response = await ApiService.get('/payment/status/${widget.paymentId}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          final paymentStatus = data['data']['status'];

          if (paymentStatus == 'success') {
            _navigateToSuccess();
          } else if (expectSuccess) {
            // If we expected success but status is not success, show pending
            _showStatusPending();
          } else {
            setState(() {
              _isCheckingStatus = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking payment status: $e');
      if (expectSuccess) {
        _showStatusCheckError();
      }
    }
  }

  void _navigateToSuccess() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessScreen(
          orderNumber: widget.orderNumber,
          totalAmount: widget.totalAmount,
        ),
      ),
    );
  }

  void _showStatusPending() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('กำลังดำเนินการ'),
        content: const Text(
          'การชำระเงินอยู่ระหว่างดำเนินการ\nกรุณารอสักครู่แล้วตรวจสอบสถานะอีกครั้ง',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('กลับ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkPaymentStatus(expectSuccess: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainPurple,
            ),
            child: const Text('ตรวจสอบอีกครั้ง'),
          ),
        ],
      ),
    );
  }

  void _showStatusCheckError() {
    if (!mounted) return;

    setState(() {
      _isCheckingStatus = false;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ไม่สามารถตรวจสอบสถานะ'),
        content: const Text(
          'ไม่สามารถเชื่อมต่อเพื่อตรวจสอบสถานะการชำระเงิน\nกรุณาลองใหม่อีกครั้ง',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('กลับ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkPaymentStatus(expectSuccess: true);
            },
            child: const Text('ลองอีกครั้ง'),
          ),
        ],
      ),
    );
  }

  void _startStatusPolling() {
    // Poll status every 3 seconds for web platform
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isCheckingStatus) {
        _checkPaymentStatus();
        _startStatusPolling();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // For web, show a status checking screen
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(showBackButton: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.mainPurple.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.payment,
                    size: 50,
                    color: AppColors.mainPurple,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'พร้อมชำระเงิน',
                  style: AppTextStyles.body16Medium.copyWith(
                    color: AppColors.purpleText,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'กดปุ่มด้านล่างเพื่อเปิดหน้าชำระเงิน\nระบบจะตรวจสอบสถานะอัตโนมัติ',
                  style: AppTextStyles.body14Medium.copyWith(
                    color: AppColors.purpleText.withValues(alpha: 0.7),
                    fontWeight: FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Open payment button - PRIMARY ACTION
                ElevatedButton.icon(
                  onPressed: () => _openPaymentUrlInNewTab(),
                  icon: const Icon(Icons.credit_card, size: 28),
                  label: const Text('เปิดหน้าชำระเงิน', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mainPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment URL display with copy button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'ถ้าไม่เปิดอัตโนมัติ คัดลอก URL ด้านล่าง:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        widget.paymentUrl,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mainPurple,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.paymentUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('คัดลอก URL แล้ว'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('คัดลอก URL'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.mainPurple,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Status indicator
                if (_isCheckingStatus)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'กำลังตรวจสอบสถานะ...',
                        style: AppTextStyles.body14Medium.copyWith(
                          color: AppColors.purpleText,
                        ),
                      ),
                    ],
                  ),

                if (_isCheckingStatus)
                  const SizedBox(height: 24),

                // Manual check button
                TextButton.icon(
                  onPressed: () => _checkPaymentStatus(expectSuccess: true),
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('ตรวจสอบสถานะ'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mainPurple,
                  ),
                ),
                const SizedBox(height: 16),

                // Cancel button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'ยกเลิกและกลับ',
                    style: AppTextStyles.body14Medium.copyWith(
                      color: AppColors.purpleText.withValues(alpha: 0.6),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'กดปุ่ม "เปิดหน้าชำระเงิน" แล้วชำระเงินในแท็บใหม่\nเมื่อชำระเสร็จกลับมาที่หน้านี้เพื่อตรวจสอบสถานะ',
                          style: AppTextStyles.body12Regular.copyWith(
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // For mobile, show WebView
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.purpleText),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('ยกเลิกการชำระเงิน?'),
                content: const Text('คุณต้องการยกเลิกการชำระเงินใช่หรือไม่?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ไม่'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back
                    },
                    child: const Text('ใช่'),
                  ),
                ],
              ),
            );
          },
        ),
        title: Text(
          'ชำระเงิน',
          style: AppTextStyles.heading16Medium.copyWith(
            color: AppColors.purpleText,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isCheckingStatus)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.purpleText),
              onPressed: () => _checkPaymentStatus(expectSuccess: true),
              tooltip: 'ตรวจสอบสถานะ',
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: AppTextStyles.body14Medium.copyWith(
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _isLoading = true;
                        });
                        _controller.loadRequest(Uri.parse(widget.paymentUrl));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mainPurple,
                      ),
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),

          if (_isLoading || _isCheckingStatus)
            Container(
              color: Colors.white.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _isCheckingStatus
                          ? 'กำลังตรวจสอบสถานะ...'
                          : 'กำลังโหลด...',
                      style: AppTextStyles.body14Medium.copyWith(
                        color: AppColors.purpleText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
