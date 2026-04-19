import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/storage/secure_storage.dart';

class AIVisionDiagnosisScreen extends StatefulWidget {
  const AIVisionDiagnosisScreen({Key? key}) : super(key: key);

  @override
  _AIVisionDiagnosisScreenState createState() =>
      _AIVisionDiagnosisScreenState();
}

class _AIVisionDiagnosisScreenState extends State<AIVisionDiagnosisScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0; // 0: Initial, 1: Scanning, 2: Result
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;
  String _scanningText = 'Đang phân tích hình ảnh...';

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // AI Response Data
  String? aiIssueTitle;
  int? aiServiceId;
  String? aiServiceName;
  int? aiMinPrice;
  int? aiMaxPrice;
  int? aiConfidenceScore;
  String? aiNotes;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
        vsync: this, duration: const Duration(seconds: 2));

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _scanController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _scanController.forward();
        }
      });
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _step = 1;
        });
        _uploadAndAnalyze();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải ảnh. Vui lòng thử lại.')),
      );
    }
  }

  Future<void> _uploadAndAnalyze() async {
    _scanController.forward();

    // Visual updates
    Timer(const Duration(seconds: 2), () {
      if (mounted && _step == 1) {
        setState(() => _scanningText = 'Đang nhận diện dịch vụ...');
      }
    });

    try {
      final token = await SecureStorage.getAccessToken();
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';

      String fileName = _selectedImage!.path.split('/').last;
      FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          _selectedImage!.path,
          filename: fileName,
        ),
      });

      final response = await dio.post(
        '${AppConstants.apiBaseUrl}/ai/analyze-issue',
        data: formData,
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data']; // The backend wraps it in { success: true, data: { ... } }
        if (mounted) {
          setState(() {
            _scanController.stop();
            aiIssueTitle = data['issueTitle'];
            aiServiceId = data['recommendedServiceId'];
            aiServiceName = data['recommendedServiceName'];
            aiMinPrice = data['minPrice'];
            aiMaxPrice = data['maxPrice'];
            aiConfidenceScore = data['confidenceScore'];
            aiNotes = data['aiNotes'];
            _step = 2; // Move to Result phase
          });
        }
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } on DioException catch (dioError) {
      _handleAnalysError('Lỗi kết nối AI: ${dioError.message}');
    } catch (e) {
      _handleAnalysError('Lưu lượng hệ thống quá tải hoặc có lỗi xảy ra.');
    }
  }

  void _handleAnalysError(String msg) {
    if (mounted) {
      _scanController.stop();
      setState(() => _step = 0);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
      ));
    }
  }

  String _formatPrice(int amount) {
    String str = amount.toString();
    String result = '';
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      result = str[i] + result;
      count++;
      if (count == 3 && i > 0) {
        result = '.$result';
        count = 0;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'AI Chẩn Đoán',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Image Preview Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _selectedImage != null
                            ? Image.file(_selectedImage!, fit: BoxFit.cover)
                            : Container(
                                color: AppColors.shelf,
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 120,
                                  color: AppColors.borderMedium,
                                ),
                              ),

                        if (_step == 1)
                          AnimatedBuilder(
                            animation: _scanAnimation,
                            builder: (context, child) {
                              return Positioned(
                                top: _scanAnimation.value *
                                    (MediaQuery.of(context).size.height * 0.5),
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.8),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        if (_step == 1)
                          Container(
                            color: AppColors.primaryDark.withOpacity(0.3),
                            child: CustomPaint(painter: GridPainter()),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastOutSlowIn,
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: _buildBottomContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomContent() {
    switch (_step) {
      case 0:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.primary, size: 32),
            const SizedBox(height: 16),
            const Text(
              'Xác định vấn đề trong vài giây',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chụp ảnh thiết bị hỏng, AI của chúng tôi sẽ phân tích và tìm đúng thợ.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Thư viện'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      side: const BorderSide(color: AppColors.borderMedium),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    label: const Text(
                      'Chụp Ảnh',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      case 1:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              _scanningText,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quá trình AI xử lý có thể mất vài giây...',
              style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
          ],
        );
      case 2:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: AppColors.primary, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Độ tin cậy: ${aiConfidenceScore ?? 0}%',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Kết Quả Chẩn Đoán',
              style: TextStyle(fontSize: 14, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              aiIssueTitle ?? 'Chưa rõ nguyên nhân',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            if (aiNotes != null) ...[
              const SizedBox(height: 8),
              Text(
                aiNotes!,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.handyman, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          aiServiceName ?? 'Dịch vụ mặc định',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ước tính: ${_formatPrice(aiMinPrice ?? 0)}đ - ${_formatPrice(aiMaxPrice ?? 0)}đ',
                          style: const TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _step = 0;
                        _selectedImage = null;
                      }),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: const BorderSide(color: AppColors.borderMedium),
                      ),
                      child: const Text('Thử Lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        // Pass AI details to CreateBookingScreen
                        // The user said: "điền form đăng tin tìm thợ với đầy đủ có mục có sẵn như trong đặt lịch"
                        // `CreateBookingScreen` takes: serviceId, genericServiceName, and we'll pass notes.
                        
                        context.push('/booking/create', extra: {
                          'serviceId': aiServiceId ?? 1,
                          'genericServiceName': aiServiceName,
                          'aiNotes': "Chẩn đoán AI:\n- Hiện tượng: ${aiIssueTitle}\n- Phân tích: ${aiNotes}\n\n*Chú ý: Vui lòng xem ảnh tôi đăng tải.",
                          'aiMinPrice': aiMinPrice,
                          'aiMaxPrice': aiMaxPrice,
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        'Dùng Dịch Vụ Này',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.1)
      ..strokeWidth = 1.0;
    const double spacing = 30.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
