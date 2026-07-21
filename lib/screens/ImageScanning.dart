import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 🚀 เพิ่ม Supabase เข้ามา
import 'result_screen.dart';

class ImageScanning extends StatefulWidget {
  const ImageScanning({super.key});

  @override
  State<ImageScanning> createState() => _ImageScanningState();
}

class _ImageScanningState extends State<ImageScanning> {
  final ImagePicker _picker = ImagePicker();
  final String _apiKey =
      '....';

  List<Map<String, dynamic>> _recentItems = [];
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    _fetchRecentItems(); // 🚀 โหลดวัตถุดิบล่าสุดตอนเปิดหน้าจอ
  }

  // --- 🚀 ฟังก์ชันดึงวัตถุดิบล่าสุด 3 ชิ้นแรกจาก Supabase ---
  Future<void> _fetchRecentItems() async {
    try {
      final response = await Supabase.instance.client
          .from('fridge_items')
          .select()
          .order('item_id', ascending: false) // เรียงจากชิ้นล่าสุด
          .limit(3); // เอามาแค่ 3 ชิ้น

      if (mounted) {
        setState(() {
          _recentItems = List<Map<String, dynamic>>.from(response);
          _isLoadingRecent = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRecent = false);
      }
    }
  }

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
          child: Center(child: CircularProgressIndicator(color: Colors.blue)),
        ),
      );

      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
      final imageBytes = await image.readAsBytes();

      final prompt = TextPart("""
        วิเคราะห์วัตถุดิบทั้งหมดในรูปภาพ (อาจมีหลายชิ้น)
        ตอบกลับมาเป็น JSON Array (List) เท่านั้น เช่น [{"name":...}, {"name":...}]
        โดยแต่ละวัตถุดิบมี key ดังนี้:
        - category: (หมวดหมู่ เช่น ผัก, เนื้อสัตว์, ผลไม้, นม, เครื่องปรุง, ขนม)
        - name: (ชื่อวัตถุดิบภาษาไทย)
        - quantity: (จำนวนเต็ม integer เริ่มต้นที่ 1)
        - unit: (หน่วยนับภาษาไทย เช่น กรัม, ชิ้น, แพ็ค, ขวด)
        - expiry_days: (จำนวนวัน integer ที่ควรเก็บรักษา)
        
        ห้ามมีข้อความอธิบายอื่น และ ห้ามมี Markdown ```json
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

        dynamic decoded = jsonDecode(cleanJson);
        List<dynamic> itemsList = [];

        if (decoded is List) {
          itemsList = decoded;
        } else if (decoded is Map) {
          itemsList = [decoded];
        }

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultScreen(foundItems: itemsList),
            ),
          ).then((_) {
            // พอกลับมาจากหน้าบันทึก ให้รีเฟรชรายการล่าสุดทันที
            _fetchRecentItems();
          });
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // เลือกไอคอนตามหมวดหมู่
  String _getCategoryEmoji(String category) {
    if (category.contains('ผลไม้')) return '🍎';
    if (category.contains('ผัก')) return '🥬';
    if (category.contains('เนื้อ') ||
        category.contains('หมู') ||
        category.contains('ไก่'))
      return '🥩';
    if (category.contains('นม') || category.contains('น้ำ')) return '🥛';
    if (category.contains('ขนม')) return '🍪';
    return '🍽️';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFE3F2FD,
      ), // 🚀 เปลี่ยนเป็นสีฟ้าอ่อนตาม UI ในรูป
      body: SafeArea(
        child: Column(
          children: [
            // ส่วนหัว (Header แบบในภาพ)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 15.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7D0), // สีเหลืองพาสเทล
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 20),
                          Icon(Icons.qr_code_scanner, color: Colors.black87),
                          SizedBox(width: 15),
                          Text(
                            "ถ่ายภาพวัตถุดิบ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7D0),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(Icons.menu, color: Colors.black87),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    // --- ปุ่มที่ 1: ถ่ายรูป (Camera) ---
                    _buildMenuButton(
                      icon: Icons.camera_alt,
                      title: "ถ่ายรูปวัตถุดิบ",
                      subtitle: "เปิดกล้องเพื่อสแกน",
                      onTap: () => _pickAndAnalyzeImage(ImageSource.camera),
                    ),

                    const SizedBox(height: 15),

                    // --- ปุ่มที่ 2: เลือกจากคลังรูปภาพ (Gallery) ---
                    _buildMenuButton(
                      icon: Icons.image_outlined,
                      title: "เลือกจากคลังรูปภาพ",
                      subtitle: "อัพโหลดรูปภาพที่มีอยู่",
                      onTap: () => _pickAndAnalyzeImage(ImageSource.gallery),
                    ),

                    const SizedBox(height: 20),

                    // --- ส่วนเคล็ดลับการสแกน ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                              color: Colors.black87,
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

                    // --- ส่วนวัตถุดิบที่เพิ่มล่าสุด (ดึงจาก Supabase จริง) ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _isLoadingRecent
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : _recentItems.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 10.0),
                                  child: Text(
                                    "ยังไม่มีประวัติการเพิ่มวัตถุดิบ",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: _recentItems.map((item) {
                                    String emoji = _getCategoryEmoji(
                                      item['category'] ?? '',
                                    );
                                    String name = item['name'] ?? 'ไม่ระบุ';
                                    String qtyInfo =
                                        "จำนวน ${item['quantity'] ?? 1} ${item['unit'] ?? ''}";
                                    return _buildRecentItem(
                                      emoji,
                                      name,
                                      qtyInfo,
                                    );
                                  }).toList(),
                                ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
        width: double.infinity,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.black87, size: 30),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.blueAccent, size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentItem(String iconEmoji, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(iconEmoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
