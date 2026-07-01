import 'dart:convert'; // สำหรับแปลง JSON
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; // แพ็กเกจ Gemini API

class AIMealPlanningScreen extends StatefulWidget {
  const AIMealPlanningScreen({super.key});

  @override
  State<AIMealPlanningScreen> createState() => _AIMealPlanningScreenState();
}

class _AIMealPlanningScreenState extends State<AIMealPlanningScreen> {
  // --- สถานะการทำงาน ---
  bool _isPlanGenerated = false;
  bool _isLoading = false; // สถานะกำลังรอ AI เจนข้อมูล

  // --- ตัวแปรเก็บข้อมูลหน้าตั้งค่า ---
  String _selectedGoal = 'รักษาน้ำหนัก';
  int _mealsPerDay = 3;
  final TextEditingController _caloriesController = TextEditingController(
    text: '1800',
  );
  final TextEditingController _proteinController = TextEditingController(
    text: '80',
  );
  String _restriction = 'ไม่มี';

  // --- ตัวแปรเก็บข้อมูลแผนอาหารที่ได้มาจาก Gemini ---
  Map<String, dynamic>? _weeklyPlanData;

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    super.dispose();
  }

  // 🚀 ฟังก์ชันส่งข้อมูลให้ GEMINI เจนแผนอาหารประจำสัปดาห์
  Future<void> _generatePlanWithGemini() async {
    // ⚠️ ใส่ API Key ของคุณน้าตรงนี้ครับ
    const geminiApiKey = "AIzaSyBYr4rJ5mXiGaLpfZwlpQlp5bK4vebBuPU";

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. ตั้งค่า Model ของ Gemini (ใช้ตัว Flash เพื่อความเร็วและความแม่นยำในงาน JSON)
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: geminiApiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ), // บังคับให้ตอบกลับมาเป็น JSON เสมอ
      );

      // 2. สร้างคำสั่ง Prompt แบบชัดเจน
      final prompt =
          '''
      คุณคือผู้เชี่ยวชาญด้านโภชนาการ ช่วยวางแผนเมนูอาหารประจำสัปดาห์ (จันทร์ ถึง อาทิตย์) โดยคำนวณสารอาหารและเมนูให้เหมาะสมตามเงื่อนไขต่อไปนี้:
      - เป้าหมาย: $_selectedGoal
      - พลังงานเป้าหมายต่อวัน: ${_caloriesController.text} แคลอรี่
      - โปรตีนเป้าหมายต่อวัน: ${_proteinController.text} กรัม
      - จำนวนมื้ออาหารต่อวัน: $_mealsPerDay มื้อ
      - ข้อจำกัดทางอาหาร: $_restriction
      *(ไม่ต้องสนใจวัตถุดิบในคลังหรือในตู้เย็น ให้คิดเมนูสุขภาพดีที่ทำง่ายทั่วไปได้เลย)*

      กรุณาตอบกลับเป็นรูปแบบ JSON ภาษาไทยเท่านั้น ห้ามมีข้อความอธิบายอื่นใดนอกเหนือจาก JSON โครงสร้างข้อมูลต้องเป็นแบบนี้เป๊ะๆ:
      {
        "summary": {
          "avg_calories": "ระบุตัวเลขแคลอรี่รวมเฉลี่ยต่อวัน เช่น ~1,500",
          "avg_protein": "ระบุตัวเลขโปรตีนเฉลี่ยต่อมื้อ เช่น ~26g"
        },
        "days": {
          "จันทร์": {
            "calories": "พลังงานรวมของวัน",
            "protein": "โปรตีนรวมของวัน เช่น 81g",
            "meals": [
              {"time": "มื้อเช้า", "name": "ชื่อเมนูภาษาไทย", "detail": "ระบุแคลอรี่และโปรตีนของมื้อนี้ เช่น 320 แคล • 18g โปรตีน"},
              {"time": "มื้อกลางวัน", "name": "ชื่อเมนูภาษาไทย", "detail": "ระบุแคลอรี่และโปรตีนของมื้อนี้"},
              {"time": "มื้อเย็น", "name": "ชื่อเมนูภาษาไทย", "detail": "ระบุแคลอรี่และโปรตีนของมื้อนี้"}
            ]
          },
          "อังคาร": { ... โครงสร้างเหมือนวันจันทร์ ไปจนถึงวันอาทิตย์ ... }
        }
      }
      ''';

      // 3. ส่งคำสั่งไปที่ข้อความสำเร็จของ Gemini
      final response = await model.generateContent([Content.text(prompt)]);
      final responseText = response.text;

      if (responseText != null) {
        // 4. แปลงข้อความที่ได้จาก AI ให้กลายเป็นข้อมูล Object ในแอป
        final Map<String, dynamic> decodedData = jsonDecode(responseText);

        setState(() {
          _weeklyPlanData = decodedData;
          _isPlanGenerated = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาดในการดึงข้อมูลจาก AI: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4EBF7),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(130.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8A2BE2), Color(0xFFD53FFF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Meal Planning",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "วางแผนอาหารประจำสัปดาห์อัจฉริยะ",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // ถ้าระบบกำลังโหลดข้อมูล ให้โชว์วงกลมหมุนๆ รอ
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF8A2BE2)),
                  const SizedBox(height: 15),
                  Text(
                    "Gemini AI กำลังออกแบบแผนอาหารให้คุณ...",
                    style: TextStyle(
                      color: Colors.purple.shade700,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : _isPlanGenerated
          ? _buildPlanResultView()
          : _buildConfigView(),
    );
  }

  // ==========================================
  // 1. หน้าจอตั้งค่าเป้าหมาย (หน้าแรก)
  // ==========================================
  Widget _buildConfigView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.track_changes,
                      color: Color(0xFF8A2BE2),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      "เป้าหมายของคุณ",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildGoalCard(
                      "ลดน้ำหนัก",
                      Icons.trending_down,
                      _selectedGoal == "ลดน้ำหนัก",
                    ),
                    _buildGoalCard(
                      "รักษาน้ำหนัก",
                      Icons.show_chart,
                      _selectedGoal == "รักษาน้ำหนัก",
                    ),
                    _buildGoalCard(
                      "เพิ่มกล้ามเนื้อ",
                      Icons.trending_up,
                      _selectedGoal == "เพิ่มกล้ามเนื้อ",
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.restaurant, color: Color(0xFF8A2BE2), size: 20),
                    SizedBox(width: 10),
                    Text(
                      "จำนวนมื้ออาหาร",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "มื้อต่อวัน",
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    Row(
                      children: [
                        _buildCircleBtn(Icons.remove, () {
                          if (_mealsPerDay > 1) setState(() => _mealsPerDay--);
                        }),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            "$_mealsPerDay",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8A2BE2),
                            ),
                          ),
                        ),
                        _buildCircleBtn(Icons.add, () {
                          if (_mealsPerDay < 5) setState(() => _mealsPerDay++);
                        }),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "การตั้งค่าเพิ่มเติม",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 15),
                _buildTextField("แคลอรี่เป้าหมายต่อวัน", _caloriesController),
                const SizedBox(height: 15),
                _buildTextField("โปรตีนต่อวัน (กรัม)", _proteinController),
                const SizedBox(height: 15),
                const Text(
                  "ข้อจำกัดทางอาหาร",
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _restriction,
                      isExpanded: true,
                      items: ['ไม่มี', 'มังสวิรัติ', 'คีโต', 'แพ้อาหารทะเล']
                          .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          })
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _restriction = newValue!;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed:
                  _generatePlanWithGemini, // เปลี่ยนมาเรียกฟังก์ชันคุยกับ Gemini
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: const Text(
                "สร้างแผนอาหารประจำสัปดาห์ด้วย AI",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD53FFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ==========================================
  // 2. หน้าจอแสดงผลลัพธ์ข้อมูลแบบไดนามิกจาก Gemini
  // ==========================================
  Widget _buildPlanResultView() {
    if (_weeklyPlanData == null) return const SizedBox();

    final daysData = _weeklyPlanData!['days'] as Map<String, dynamic>;
    final summaryData = _weeklyPlanData!['summary'] as Map<String, dynamic>;

    // รายชื่อวันเพื่อเอาไปใช้ดึงข้อมูลตามลำดับ
    final dayKeys = [
      "จันทร์",
      "อังคาร",
      "พุธ",
      "พฤหัสบดี",
      "ศุกร์",
      "เสาร์",
      "อาทิตย์",
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "แผนอาหารประจำสัปดาห์",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _isPlanGenerated = false),
                child: const Text(
                  "แก้ไขการตั้งค่า",
                  style: TextStyle(
                    color: Color(0xFF8A2BE2),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // วนลูปสร้างการ์ดรายวันตามข้อมูลจริงที่ได้มาจาก Gemini
          ...dayKeys.map((day) {
            if (!daysData.containsKey(day)) return const SizedBox();

            final dayInfo = daysData[day] as Map<String, dynamic>;
            final List<dynamic> mealsList = dayInfo['meals'] ?? [];

            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: _buildDayCard(
                dayName: day,
                totalCalories:
                    dayInfo['calories']?.toString().replaceAll(' แคล', '') ??
                    '-',
                totalProtein: dayInfo['protein']?.toString() ?? '-',
                meals: mealsList.map((meal) {
                  // กำหนดสีตามชื่อประเภทมื้ออาหาร
                  Color indicatorColor = Colors.blue;
                  Color bgColor = Colors.blue.shade50;

                  if (meal['time'] == "มื้อเช้า") {
                    indicatorColor = const Color(0xFFD4A017);
                    bgColor = const Color(0xFFFFFDE7);
                  } else if (meal['time'] == "มื้อกลางวัน") {
                    indicatorColor = const Color(0xFFE91E63);
                    bgColor = const Color(0xFFFCE4EC);
                  } else if (meal['time'] == "มื้อเย็น") {
                    indicatorColor = const Color(0xFF8A2BE2);
                    bgColor = const Color(0xFFF4EBF7);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildMealItem(
                      meal['time'] ?? 'มื้ออาหาร',
                      meal['name'] ?? 'เมนูแนะนำจาก AI',
                      meal['detail'] ?? '',
                      indicatorColor,
                      bgColor,
                    ),
                  );
                }).toList(),
              ),
            );
          }),

          // 🌟 การ์ดสรุปสัปดาห์นี้ ผูกตัวเลขจาก AI อัตโนมัติ
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EBF7),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFE0B0FF), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "สรุปสัปดาห์นี้",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              summaryData['avg_calories'] ?? '-',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB400FF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "แคลต่อวันเฉลี่ย",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              summaryData['avg_protein'] ?? '-',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB400FF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "โปรตีนต่อมื้อเฉลี่ย",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("💡", style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text(
                            "คำแนะนำ",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "แผนนี้ผ่านการคำนวณและเกลี่ยสารอาหารโดย AI เพื่อให้ได้พลังงานและคุณค่าทางอาหารครบถ้วนใกล้เคียงกับเป้าหมายสุขภาพรายสัปดาห์ของคุณน้าครับ",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==========================================
  // Widget Helpers (เครื่องมือจัดแจง UI)
  // ==========================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
      ],
    );
  }

  Widget _buildDayCard({
    required String dayName,
    required String totalCalories,
    required String totalProtein,
    required List<Widget> meals,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$totalCalories แคล",
                    style: const TextStyle(
                      color: Color(0xFF8A2BE2),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "โปรตีน $totalProtein",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...meals,
        ],
      ),
    );
  }

  Widget _buildMealItem(
    String mealTime,
    String mealName,
    String detail,
    Color indicatorColor,
    Color bgColor,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: indicatorColor, width: 4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mealTime,
            style: TextStyle(
              color: indicatorColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            mealName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedGoal = title),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9E47FF) : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected
              ? []
              : const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 30,
              color: isSelected ? Colors.white : Colors.black54,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: const Color(0xFFF4EBF7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF8A2BE2), size: 20),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF8A2BE2)),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
