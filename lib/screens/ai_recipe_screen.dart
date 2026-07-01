import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'recipe_detail_screen.dart'; // ✅ นำเข้าหน้าใหม่

class AiRecipeScreen extends StatefulWidget {
  const AiRecipeScreen({super.key});

  @override
  State<AiRecipeScreen> createState() => _AiRecipeScreenState();
}

class _AiRecipeScreenState extends State<AiRecipeScreen> {
  bool _isLoadingData = true;
  bool _isGenerating = false;

  List<Map<String, dynamic>> _inventory = [];
  List<Map<String, dynamic>> _expiringSoon = [];
  List<dynamic> _generatedRecipes = []; // เก็บเมนูที่ AI สร้างให้

  // ตัวแปรสำหรับ Filter
  String _selectedCategory = 'ทั้งหมด';
  final List<String> _categories = ['ทั้งหมด', 'อาหารไทย', 'คลีน', 'คีโต'];

  String _selectedTime = 'ไม่จำกัด';
  final List<String> _times = [
    'ไม่จำกัด',
    '< 15 นาที',
    '< 30 นาที',
    '< 1 ชั่วโมง',
  ];

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  // 1. ดึงข้อมูลวัตถุดิบจาก Supabase
  Future<void> _fetchInventory() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('fridge_items').select();
      final data = List<Map<String, dynamic>>.from(response);

      List<Map<String, dynamic>> expiring = [];
      final now = DateTime.now();

      for (var item in data) {
        if (item['expiry_date'] != null) {
          final expiry = DateTime.parse(item['expiry_date']);
          final diff = expiry.difference(now).inDays;
          item['days_remaining'] = diff; // เก็บค่าไว้ใช้แสดงผล
          if (diff <= 3) {
            expiring.add(item);
          }
        } else {
          item['days_remaining'] = 999;
        }
      }

      // เรียงลำดับตามวันหมดอายุ
      expiring.sort(
        (a, b) =>
            (a['days_remaining'] as int).compareTo(b['days_remaining'] as int),
      );

      setState(() {
        _inventory = data;
        _expiringSoon = expiring;
        _isLoadingData = false;
      });
    } catch (e) {
      print("Error fetching inventory: $e");
      setState(() => _isLoadingData = false);
    }
  }

  // 2. ส่งข้อมูลให้ Gemini คิดเมนู
  Future<void> _generateRecipes() async {
    if (_inventory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่มีวัตถุดิบในตู้เย็น กรุณาเพิ่มวัตถุดิบก่อน'),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedRecipes = []; // เคลียร์ของเก่า
    });

    try {
      // ⚠️ ใส่ API Key ของคุณที่นี่
      final String apiKey = 'AIzaSyBYr4rJ5mXiGaLpfZwlpQlp5bK4vebBuPU';
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

      // เตรียมรายชื่อวัตถุดิบเป็น Text
      String allItems = _inventory
          .map((e) => "${e['name']} (${e['quantity']} ${e['unit']})")
          .join(", ");
      String expiringItems = _expiringSoon.map((e) => e['name']).join(", ");

      final prompt = TextPart("""
        คุณคือเชฟอัจฉริยะ ช่วยคิดเมนูอาหาร 3 เมนู ที่สามารถทำได้จากวัตถุดิบเหล่านี้เป็นหลัก
        วัตถุดิบที่มี: $allItems
        วัตถุดิบที่ใกล้หมดอายุ (พยายามบังคับใช้ในเมนู): ${expiringItems.isEmpty ? 'ไม่มี' : expiringItems}
        
        เงื่อนไขเพิ่มเติม:
        - ประเภทอาหาร: ${_selectedCategory == 'ทั้งหมด' ? 'อะไรก็ได้' : _selectedCategory}
        - เวลาทำไม่เกิน: ${_selectedTime == 'ไม่จำกัด' ? 'เท่าไหร่ก็ได้' : _selectedTime}

        ตอบกลับมาเป็น JSON Array เท่านั้น ตามรูปแบบนี้เป๊ะๆ:
        [
          {
            "recipe_name": "ชื่อเมนู",
            "time": "เวลาทำ (เช่น 15 นาที)",
            "servings": "จำนวนที่ได้ (เช่น 2 ที่)",
            "ingredients_used": ["วัตถุดิบหลัก1", "วัตถุดิบหลัก2"],
            "detailed_ingredients": [
              {"name": "ชื่อวัตถุดิบให้ตรงกับที่มีเป๊ะๆ", "use_quantity": จำนวนเลข(ใส่แค่เลข), "unit": "หน่วย"}
            ],
            "instructions": [
              "1. ขั้นตอนแรก...",
              "2. ขั้นตอนต่อไป..."
            ]
          }
        ]
        ห้ามใส่ Markdown ```json
      """);

      final response = await model
          .generateContent([
            Content.multi([prompt]),
          ])
          .timeout(const Duration(seconds: 60));

      if (response.text != null) {
        String cleanJson = response.text!
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        dynamic decoded = jsonDecode(cleanJson);

        setState(() {
          if (decoded is List) {
            _generatedRecipes = decoded;
          } else if (decoded is Map) {
            _generatedRecipes = [decoded];
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('สร้างเมนูไม่สำเร็จ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EEF5), // สีพื้นหลังชมพูอ่อน
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : CustomScrollView(
              slivers: [
                // 1. Header Gradient (เหมือนในรูป)
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 20,
                      right: 20,
                      bottom: 30,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFE040FB),
                          Color(0xFFAB47BC),
                        ], // ม่วงชมพู
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "AI Recipe Generator",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "สร้างเมนูจากวัตถุดิบที่มี โดยจัดลำดับจากของที่ใกล้หมดอายุก่อน",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),

                // 2. กล่องแจ้งเตือนของใกล้หมดอายุ
                if (_expiringSoon.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0), // สีเหลืองอ่อน
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "วัตถุดิบที่ใกล้หมดอายุ",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ..._expiringSoon.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 6.0,
                                  left: 34,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "${item['name']} (${item['quantity']} ${item['unit']})",
                                      style: const TextStyle(
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      "เหลือ ${item['days_remaining']} วัน",
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 3. ตัวกรอง (Filter)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ประเภทอาหาร",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories
                                .map(
                                  (e) => _buildFilterChip(
                                    e,
                                    _selectedCategory,
                                    (v) =>
                                        setState(() => _selectedCategory = v),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "เวลาในการทำ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _times
                                .map(
                                  (e) => _buildFilterChip(
                                    e,
                                    _selectedTime,
                                    (v) => setState(() => _selectedTime = v),
                                    isPurple: true,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ปุ่มสร้างเมนู
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isGenerating ? null : _generateRecipes,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purpleAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 2,
                            ),
                            child: _isGenerating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.auto_awesome,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "สร้างเมนูอาหาร",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          "เมนูแนะนำ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),

                // 4. รายการเมนูที่ AI สร้าง
                if (_generatedRecipes.isEmpty && !_isGenerating)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Center(
                        child: Text(
                          "กดปุ่มเพื่อสร้างเมนูจากของในตู้เย็นเลย!",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  ),

                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final recipe = _generatedRecipes[index];
                    return _buildRecipeCard(recipe);
                  }, childCount: _generatedRecipes.length),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
    );
  }

  // Widget สำหรับปุ่ม Filter
  Widget _buildFilterChip(
    String label,
    String selectedValue,
    Function(String) onSelected, {
    bool isPurple = false,
  }) {
    final isSelected = selectedValue == label;
    final activeColor = isPurple
        ? Colors.deepPurpleAccent
        : Colors.purpleAccent;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black87),
        ),
        selected: isSelected,
        selectedColor: activeColor,
        backgroundColor: Colors.white,
        showCheckmark: false,
        onSelected: (bool selected) => onSelected(label),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isSelected ? activeColor : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  // Widget การ์ดเมนูอาหาร
  Widget _buildRecipeCard(Map<String, dynamic> recipe) {
    List<dynamic> tags = recipe['ingredients_used'] ?? [];

    return GestureDetector(
      onTap: () async {
        // ✅ กดเพื่อไปหน้า RecipeDetailScreen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                RecipeDetailScreen(recipe: recipe, inventory: _inventory),
          ),
        );

        // ✅ ถ้ากดหักวัตถุดิบกลับมา ให้รีเฟรชหน้า AI ใหม่ (เพื่อดึงยอดคงเหลือใหม่)
        if (result == true) {
          _fetchInventory();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: Color(0xFFF3E5F5), // ม่วงอ่อน
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
              child: const Icon(
                Icons.restaurant,
                color: Colors.purpleAccent,
                size: 40,
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            recipe['recipe_name'] ?? 'ไม่มีชื่อเมนู',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "แนะนำ",
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe['time'] ?? '-',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.people_outline,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe['servings'] ?? '-',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Tags วัตถุดิบ
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tag.toString(),
                                style: const TextStyle(
                                  color: Colors.purple,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
