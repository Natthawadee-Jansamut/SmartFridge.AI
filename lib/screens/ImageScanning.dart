import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../widgets/custom_header.dart';
import 'result_screen.dart';

class ImageScanning extends StatefulWidget {
  const ImageScanning({super.key});

  @override
  State<ImageScanning> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<ImageScanning> {
  final ImagePicker _picker = ImagePicker();

  // ⚠️ อย่าลืมใส่ API Key ของคุณ
  final String _apiKey = 'AIzaSyBYr4rJ5mXiGaLpfZwlpQlp5bK4vebBuPU';

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
    if (!mounted) return;
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );

      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
      final imageBytes = await image.readAsBytes();

      // ✅ แก้ Prompt: สั่งให้ตอบเป็น JSON Array [...] เสมอ
      final prompt = TextPart("""
        วิเคราะห์วัตถุดิบทั้งหมดในรูปภาพ (อาจมีหลายชิ้น)
        ตอบกลับมาเป็น JSON Array (List) เท่านั้น เช่น [{"name":...}, {"name":...}]
        โดยแต่ละวัตถุดิบมี key ดังนี้:
        - category: (หมวดหมู่ เช่น ผัก, เนื้อสัตว์, ผลไม้, นม, เครื่องปรุง)
        - name: (ชื่อวัตถุดิบภาษาไทย)
        - quantity: (จำนวนเต็ม integer เริ่มต้นที่ 1)
        - unit: (หน่วยนับภาษาไทย เช่น กรัม, ชิ้น, แพ็ค, ขวด)
        - expiry_days: (จำนวนวัน integer ที่ควรเก็บรักษา)
        
        ห้ามมี Markdown ```json
      """);

      final response = await model
          .generateContent([
            Content.multi([prompt, DataPart('image/jpeg', imageBytes)]),
          ])
          .timeout(const Duration(seconds: 30));

      if (mounted && Navigator.canPop(context)) Navigator.pop(context);

      if (response.text != null) {
        String cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        // ✅ แก้การแกะ JSON: รองรับ List<dynamic>
        dynamic decoded = jsonDecode(cleanJson);
        List<dynamic> itemsList = [];

        if (decoded is List) {
          itemsList = decoded; // ถ้าเป็น List อยู่แล้วก็ใช้เลย
        } else if (decoded is Map) {
          itemsList = [decoded]; // ถ้ามาตัวเดียว ให้จับใส่ List
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              // ส่ง List ไปหน้าถัดไป
              builder: (context) => ResultScreen(foundItems: itemsList),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E6), // สีพื้นหลังครีม
      body: Column(
        children: [
          // ส่วนหัว (Header)
          const CustomHeader(
            title: "Image Scanning",
            subtitle: "ถ่ายรูปสแกนวัตถุดิบเข้าตู้เย็น",
            showBack: true,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // --- ปุ่มที่ 1: ถ่ายรูป (Camera) ---
                  _buildMenuButton(
                    icon: Icons.camera_alt,
                    title: "ถ่ายรูปวัตถุดิบ",
                    subtitle: "เปิดกล้องเพื่อสแกน",
                    color: Colors.orange,
                    onTap: () => _pickAndAnalyzeImage(ImageSource.camera),
                  ),

                  const SizedBox(height: 15),

                  // --- ปุ่มที่ 2: เลือกจากแกลเลอรี่ (Gallery) ---
                  _buildMenuButton(
                    icon: Icons.upload_file,
                    title: "เลือกจากแกลเลอรี่",
                    subtitle: "อัพโหลดรูปภาพที่มีอยู่",
                    color: Colors.deepOrange,
                    isGradient: true,
                    onTap: () => _pickAndAnalyzeImage(ImageSource.gallery),
                  ),

                  const SizedBox(height: 20),

                  // --- ส่วนเคล็ดลับ (Static UI) ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "เคล็ดลับการสแกน",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildTipItem("ถ่ายรูปในที่ที่มีแสงสว่างเพียงพอ"),
                        _buildTipItem("จัดวัตถุดิบให้อยู่ตรงกลางเฟรม"),
                        _buildTipItem("หลีกเลี่ยงเงาหรือแสงสะท้อนบนวัตถุ"),
                        _buildTipItem("ถ่ายทีละชิ้นเพื่อความแม่นยำสูงสุด"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- ส่วนวัตถุดิบล่าสุด (Static UI) ---
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "วัตถุดิบที่เพิ่มล่าสุด",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildRecentItem("🥬", "ผักกาดขาว", "5 นาทีที่แล้ว"),
                        _buildRecentItem("🍗", "อกไก่", "1 ชั่วโมงที่แล้ว"),
                        _buildRecentItem("🥛", "นมสด", "2 ชั่วโมงที่แล้ว"),
                      ],
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

  // Widget สร้างปุ่มกด (Refactored ให้โค้ดสะอาดขึ้น)
  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    bool isGradient = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent),
      ),
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isGradient ? null : color,
                gradient: isGradient
                    ? LinearGradient(colors: [Colors.orange, color])
                    : null,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // Widget ย่อยสำหรับรายการเคล็ดลับ
  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.black87)),
        ],
      ),
    );
  }

  // Widget ย่อยสำหรับรายการล่าสุด
  Widget _buildRecentItem(String iconEmoji, String title, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(iconEmoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              Text(
                time,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
