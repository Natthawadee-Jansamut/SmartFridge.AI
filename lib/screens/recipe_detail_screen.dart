import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final List<Map<String, dynamic>>
  inventory; // รับข้อมูลคลังเพื่อเอามาเทียบหักลบ

  const RecipeDetailScreen({
    super.key,
    required this.recipe,
    required this.inventory,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  bool _isCooking = false;

  // ฟังก์ชันหักวัตถุดิบออกจาก Supabase
  Future<void> _startCooking() async {
    // แจ้งเตือนยืนยัน
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("เริ่มทำอาหาร?"),
            content: const Text(
              "ระบบจะทำการหักวัตถุดิบที่ใช้ในเมนูนี้ออกจากคลังของคุณอัตโนมัติ",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("ยกเลิก"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.purple),
                child: const Text("ตกลง, หักวัตถุดิบเลย"),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isCooking = true);

    try {
      final supabase = Supabase.instance.client;
      List<dynamic> detailedIngredients =
          widget.recipe['detailed_ingredients'] ?? [];

      // วนลูปเช็ควัตถุดิบที่ AI บอกว่าต้องใช้
      for (var needed in detailedIngredients) {
        String neededName = needed['name'] ?? '';
        int neededQty = (needed['use_quantity'] is int)
            ? needed['use_quantity']
            : int.tryParse(needed['use_quantity'].toString()) ?? 0;

        // หาวัตถุดิบในตู้เย็นที่ชื่อตรงกัน
        var matchedItem = widget.inventory
            .where((inv) => inv['name'] == neededName)
            .firstOrNull;

        if (matchedItem != null && neededQty > 0) {
          int currentQty = matchedItem['quantity'] ?? 0;
          int newQty = currentQty - neededQty;
          if (newQty < 0) newQty = 0; // ป้องกันเลขติดลบ

          // อัปเดตยอดใน Database
          await supabase
              .from('fridge_items')
              .update({'quantity': newQty})
              .eq('item_id', matchedItem['item_id']);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ทำอาหารเสร็จสิ้น! หักวัตถุดิบเรียบร้อยแล้ว 🍲"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // ส่งค่า true กลับไปให้หน้าเดิมรีเฟรชตู้เย็น
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาด: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    List<dynamic> instructions = recipe['instructions'] ?? [];
    List<dynamic> detailedIngredients = recipe['detailed_ingredients'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8EEF5), // ม่วงชมพูอ่อน
      appBar: AppBar(
        backgroundColor: const Color(0xFFE040FB),
        foregroundColor: Colors.white,
        title: const Text(
          "วิธีทำอาหาร",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. หัวข้อเมนู
                  Text(
                    recipe['recipe_name'] ?? 'ไม่มีชื่อเมนู',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 18, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                        recipe['time'] ?? '-',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(width: 15),
                      const Icon(
                        Icons.room_service,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        recipe['servings'] ?? '-',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 2. วัตถุดิบที่ใช้
                  const Text(
                    "วัตถุดิบที่ต้องใช้",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: detailedIngredients.map((ing) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    ing['name'] ?? '',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                              Text(
                                "${ing['use_quantity'] ?? ''} ${ing['unit'] ?? ''}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 3. ขั้นตอนการทำ
                  const Text(
                    "วิธีทำ",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: instructions.map((step) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Text(
                            step.toString(),
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. ปุ่มเริ่มทำอาหาร
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isCooking ? null : _startCooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isCooking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.soup_kitchen,
                            size: 24,
                            color: Colors.white,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "Cooking (หักวัตถุดิบ)",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
