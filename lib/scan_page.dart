import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chatbot_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  bool _isAnalyzing = false;
  String? _result;
  bool? _isHealthy;
  String _plantName = '';
  String _diseaseName = '';

  Future<void> _openCamera() async {
    try {
      // On web, this triggers the camera via HTML input capture="camera"
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _result = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _result = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageBytes == null) return;
    setState(() => _isAnalyzing = true);

    try {
      final uri = Uri.parse('http://localhost:5000/predict-disease');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(http.MultipartFile.fromBytes('image', _imageBytes!, filename: 'plant.jpg'));
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body);

      if (!mounted) return;
      if (response.statusCode == 200) {
        final plant      = data['plant'] ?? 'Unknown';
        final disease    = data['disease'] ?? 'Unknown';
        final confidence = data['confidence'] ?? 0.0;
        final isHealthy  = data['is_healthy'] ?? false;
        setState(() {
          _isAnalyzing = false;
          _plantName   = plant;
          _diseaseName = disease;
          _result = isHealthy
              ? '✅ Plant: $plant\n\nStatus: Healthy 🌿\n\nConfidence: $confidence%'
              : '⚠️ Plant: $plant\n\nDisease: $disease\n\nConfidence: $confidence%';
          _isHealthy = isHealthy;
        });
      } else {
        setState(() {
          _isAnalyzing = false;
          _result = data['message'] ?? 'Analysis failed.';
          _isHealthy = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _result = 'Cannot connect to server. Make sure Flask is running.';
          _isHealthy = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 8)],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A2E1A), size: 20),
                    ),
                  ),
                  const Expanded(
                    child: Text('Plant Scanner',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
                  ),
                  const SizedBox(width: 50),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Image Preview
                    Container(
                      width: double.infinity,
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _imageBytes != null ? const Color(0xFF4A7C4A) : const Color(0xFFE5E7EB),
                          width: _imageBytes != null ? 2 : 1,
                        ),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)],
                      ),
                      child: _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(color: Color(0xFFE8F5E8), shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt_outlined, size: 40, color: Color(0xFF4A7C4A)),
                                ),
                                const SizedBox(height: 16),
                                const Text('Take or upload a photo',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A2E1A))),
                                const SizedBox(height: 8),
                                Text('of your plant to detect diseases',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                              ],
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Note for web users
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3CD),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFD700)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF856404), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'On web: "Camera" opens your device camera, "Gallery" opens file picker.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF856404)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Camera & Gallery Buttons
                    Row(
                      children: [
                        Expanded(child: _buildOptionButton(
                          icon: Icons.camera_alt,
                          label: 'Camera',
                          color: const Color(0xFF2D5233),
                          onTap: _openCamera,
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _buildOptionButton(
                          icon: Icons.photo_library_outlined,
                          label: 'Gallery',
                          color: const Color(0xFF4A7C4A),
                          onTap: _openGallery,
                        )),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Analyze Button
                    if (_imageBytes != null)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isAnalyzing ? null : _analyzeImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D5233),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF2D5233).withOpacity(0.6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            elevation: 4,
                          ),
                          child: _isAnalyzing
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(width: 20, height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                                    SizedBox(width: 12),
                                    Text('Analyzing...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  ],
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.biotech, size: 22),
                                    SizedBox(width: 8),
                                    Text('Analyze Plant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                        ),
                      ),

                    // Result Card
                    if (_result != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _isHealthy == true
                              ? const Color(0xFFE8F5E8)
                              : _isHealthy == false
                                  ? const Color(0xFFFFF3CD)
                                  : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isHealthy == true
                                ? const Color(0xFF4A7C4A)
                                : _isHealthy == false
                                    ? const Color(0xFFFFD700)
                                    : Colors.red,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isHealthy == true ? Icons.check_circle : Icons.warning_amber_rounded,
                                  color: _isHealthy == true ? const Color(0xFF4A7C4A) : const Color(0xFF856404),
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                const Text('Analysis Result',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SelectableText(
                              _result!,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.5),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: _result!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 2)),
                                    );
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.copy, size: 16, color: Color(0xFF4A7C4A)),
                                      SizedBox(width: 4),
                                      Text('Copy', style: TextStyle(fontSize: 13, color: Color(0xFF4A7C4A))),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                if (_isHealthy == false)
                                  GestureDetector(
                                    onTap: () {
                                      final question = 'My $_plantName plant has $_diseaseName disease. What medicines from HomeHarvest store can treat it? Also suggest general treatments.';
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => ChatbotPage(initialMessage: question),
                                      ));
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2D5233),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.chat, size: 14, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text('Ask for Treatment', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Tips
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tips for best results',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A2E1A))),
                          const SizedBox(height: 8),
                          _buildTip(Icons.wb_sunny_outlined, 'Take photo in good lighting'),
                          _buildTip(Icons.center_focus_strong, 'Focus on the affected area'),
                          _buildTip(Icons.crop_free, 'Keep the plant centered in frame'),
                          _buildTip(Icons.close_fullscreen, 'Get close to show disease clearly'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4A7C4A)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}


