import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase
import '../widgets/custom_header.dart';
import 'inventory_screen.dart'; // Import หน้า Inventory

class ResultScreen extends StatefulWidget {
  // รับข้อมูลเป็น List เพื่อรองรับวัตถุดิบหลายชิ้นพร้อมกัน
  final List<dynamic> foundItems;

  const ResultScreen({super.key, required this.foundItems});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E6), // สีพื้นหลังครีม
      body: Column(
        children: [
          // --- ส่วนหัว (Header) ---
          CustomHeader(
            title: "Result",
            subtitle: "พบวัตถุดิบ ${widget.foundItems.length} รายการ",
            showBack: true,
          ),

          // --- รายการวัตถุดิบ (List) ---
          Expanded(
            child: widget.foundItems.isEmpty
                ? const Center(child: Text("ไม่พบวัตถุดิบ"))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    itemCount: widget.foundItems.length,
                    itemBuilder: (context, index) {
                      // ส่งข้อมูลทีละชิ้นไปสร้างการ์ด
                      // และส่ง Callback function เพื่อรับค่าที่แก้ไขกลับมาอัปเดต List หลัก
                      return IngredientCardItem(
                        initialData:
                            widget.foundItems[index] as Map<String, dynamic>,
                        onUpdate: (key, value) {
                          // อัปเดตข้อมูลใน List หลักทันทีที่มีการแก้ไขในการ์ดลูก
                          widget.foundItems[index][key] = value;
                        },
                      );
                    },
                  ),
          ),

          // --- ปุ่มกดด้านล่าง (Footer) ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("สแกนใหม่"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveToSupabase, // เรียกฟังก์ชันบันทึก
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check, size: 20),
                        SizedBox(width: 5),
                        Text("บันทึกทั้งหมด"),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- ฟังก์ชันบันทึกลง Database ---
  // --- ฟังก์ชันบันทึกลง Database ---
  Future<void> _saveToSupabase() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      for (var item in widget.foundItems) {
        String name = item['name'];

        // 1. ค้นหาว่ามีวัตถุดิบชื่อนี้ที่เพิ่งเพิ่มวันนี้ (หรือถ้าอยากรวมทุกอันก็ไม่ต้องเช็กวัน)
        final existingItem = await supabase
            .from('fridge_items')
            .select('item_id, quantity')
            .eq('user_id', user.id)
            .eq('name', name)
            .maybeSingle();

        if (existingItem != null) {
          // 2. ถ้ามีอยู่แล้ว -> ให้อัปเดตจำนวนเพิ่มเข้าไป
          int newQuantity =
              (existingItem['quantity'] ?? 0) + (item['quantity'] as int);

          await supabase
              .from('fridge_items')
              .update({'quantity': newQuantity})
              .eq('item_id', existingItem['item_id']);
        } else {
          // 3. ถ้าไม่มี -> ค่อยทำการ insert ใหม่
          int days = int.tryParse(item['expiry_days'].toString()) ?? 7;
          DateTime expiryDate = DateTime.now().add(Duration(days: days));

          await supabase.from('fridge_items').insert({
            'user_id': user.id,
            'name': name,
            'category': item['category'],
            'quantity': item['quantity'],
            'max_quantity': item['quantity'],
            'unit': item['unit'],
            'expiry_date': expiryDate.toIso8601String(),
          });
        }
      }

      // ปิด Loading
      if (mounted) Navigator.pop(context);

      // ไปหน้า Inventory
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกข้อมูลเรียบร้อย!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const InventoryScreen()),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // ปิด Loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ==================================================================
// Widget ย่อย: การ์ดสำหรับแสดงผลวัตถุดิบ 1 ชิ้น
// ==================================================================
class IngredientCardItem extends StatefulWidget {
  final Map<String, dynamic> initialData;
  // Callback เพื่อส่งค่ากลับไป Parent เมื่อมีการแก้ไข
  final Function(String key, dynamic value) onUpdate;

  const IngredientCardItem({
    super.key,
    required this.initialData,
    required this.onUpdate,
  });

  @override
  State<IngredientCardItem> createState() => _IngredientCardItemState();
}

class _IngredientCardItemState extends State<IngredientCardItem> {
  late TextEditingController nameController;
  late TextEditingController expiryController;
  late int quantity;
  late String unit;
  late String category;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;

    // กำหนดค่าเริ่มต้น
    nameController = TextEditingController(text: data['name'] ?? '');

    int days = 7;
    if (data['expiry_days'] != null) {
      days = int.tryParse(data['expiry_days'].toString()) ?? 7;
    }
    expiryController = TextEditingController(text: days.toString());

    quantity = (data['quantity'] is int) ? data['quantity'] : 1;
    unit = data['unit'] ?? 'ชิ้น';
    category = data['category'] ?? 'อื่นๆ';

    // เพิ่ม Listener ให้ TextController เพื่อส่งค่ากลับเมื่อพิมพ์เสร็จ
    nameController.addListener(() {
      widget.onUpdate('name', nameController.text);
    });

    expiryController.addListener(() {
      int? val = int.tryParse(expiryController.text);
      if (val != null) widget.onUpdate('expiry_days', val);
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    expiryController.dispose();
    super.dispose();
  }

  // ฟังก์ชันเลือก Emoji
  String _getEmoji(String cat) {
    if (cat.contains('ผัก')) return '🥬';
    if (cat.contains('ผลไม้')) return '🍎';
    if (cat.contains('เนื้อ') || cat.contains('ไก่') || cat.contains('หมู'))
      return '🥩';
    if (cat.contains('นม') || cat.contains('น้ำ')) return '🥛';
    if (cat.contains('ขนม')) return '🍪';
    return '🍽️';
  }

  @override
  Widget build(BuildContext context) {
    int daysToAdd = int.tryParse(expiryController.text) ?? 7;
    final expiryDate = DateTime.now().add(Duration(days: daysToAdd));
    final expiryDateString =
        "${expiryDate.day}/${expiryDate.month}/${expiryDate.year + 543}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. ส่วนหัว: หมวดหมู่และ Emoji
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
              Text(_getEmoji(category), style: const TextStyle(fontSize: 30)),
            ],
          ),

          const SizedBox(height: 12),

          // 2. ชื่อวัตถุดิบ
          const Text(
            "ชื่อวัตถุดิบ",
            style: TextStyle(color: Colors.black87, fontSize: 13),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 3. ปริมาณและหน่วย
          Row(
            children: [
              // ปุ่มลบ
              _buildCounterButton("-", () {
                if (quantity > 1) {
                  setState(() => quantity--);
                  widget.onUpdate('quantity', quantity); // ส่งค่ากลับ
                }
              }),
              // ตัวเลข
              Container(
                width: 50,
                alignment: Alignment.center,
                child: Text(
                  "$quantity",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.orange,
                  ),
                ),
              ),
              // ปุ่มบวก
              _buildCounterButton("+", () {
                setState(() => quantity++);
                widget.onUpdate('quantity', quantity); // ส่งค่ากลับ
              }),

              const SizedBox(width: 15),

              // Dropdown หน่วย
              Expanded(
                child: DropdownButtonFormField<String>(
                  value:
                      [
                        "ชิ้น",
                        "กรัม",
                        "กก.",
                        "แพ็ค",
                        "ขวด",
                        "ลูก",
                        "ฟอง",
                      ].contains(unit)
                      ? unit
                      : "ชิ้น",
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: ["ชิ้น", "กรัม", "กก.", "แพ็ค", "ขวด", "ลูก", "ฟอง"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => unit = val!);
                    widget.onUpdate('unit', val); // ส่งค่ากลับ
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 4. วันหมดอายุ
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9C4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "อีกกี่วันหมดอายุ:",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      SizedBox(
                        height: 30,
                        child: TextFormField(
                          controller: expiryController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (val) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "วันที่หมดอายุ",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      expiryDateString,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper สร้างปุ่ม + -
  Widget _buildCounterButton(String icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 35,
        height: 35,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Text(
          icon,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.deepOrange,
          ),
        ),
      ),
    );
  }
}
