import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_header.dart';
import 'item_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String selectedCategory = 'ทั้งหมด';
  final List<String> categories = [
    'ทั้งหมด',
    'ผัก',
    'เนื้อสัตว์',
    'นมและไข่',
    'ผลไม้',
    'อื่นๆ',
  ];
  String searchQuery = '';
  late Stream<List<Map<String, dynamic>>> _ingredientsStream;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _ingredientsStream = Supabase.instance.client
          .from('fridge_items')
          .stream(primaryKey: ['id'])
          .order('expiry_date', ascending: true);
    });
  }

  // ✅ ฟังก์ชันแสดงหน้าต่างเพิ่มวัตถุดิบแบบ Manual
  Future<void> _showAddItemDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: "1");
    String unit = 'ชิ้น';
    String category = 'อื่นๆ';
    DateTime? selectedDate = DateTime.now().add(
      const Duration(days: 7),
    ); // ค่าเริ่มต้น 7 วัน
    bool isSaving = false;

    final List<String> unitList = [
      "ชิ้น",
      "กรัม",
      "กก.",
      "แพ็ค",
      "ขวด",
      "ลูก",
      "ฟอง",
      "กล่อง",
    ];
    final List<String> catList = [
      'ผัก',
      'เนื้อสัตว์',
      'นมและไข่',
      'ผลไม้',
      'เครื่องปรุง',
      'อื่นๆ',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            String formattedDate = DateFormat(
              'dd/MM/yyyy',
            ).format(selectedDate!);

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "เพิ่มวัตถุดิบใหม่",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 10),

                      // 1. ชื่อวัตถุดิบ
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "ชื่อวัตถุดิบ (เช่น แครอท, ไก่)",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                      ),
                      const SizedBox(height: 15),

                      // 2. หมวดหมู่
                      DropdownButtonFormField<String>(
                        value: category,
                        decoration: InputDecoration(
                          labelText: "หมวดหมู่",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                        ),
                        items: catList
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setModalState(() => category = val!),
                      ),
                      const SizedBox(height: 15),

                      // 3. ปริมาณและหน่วย
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "จำนวน",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 15,
                                ),
                              ),
                              validator: (v) => v!.isEmpty ? 'ระบุจำนวน' : null,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: unit,
                              decoration: InputDecoration(
                                labelText: "หน่วย",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 15,
                                ),
                              ),
                              items: unitList
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setModalState(() => unit = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // 4. วันหมดอายุ
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate!,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 5),
                            ),
                          );
                          if (picked != null) {
                            setModalState(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "วันหมดอายุ: $formattedDate",
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(
                                Icons.calendar_today,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // 5. ปุ่มบันทึก
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() => isSaving = true);

                                  try {
                                    int qty = int.parse(
                                      quantityController.text,
                                    );
                                    await Supabase.instance.client
                                        .from('fridge_items')
                                        .insert({
                                          'name': nameController.text,
                                          'category': category,
                                          'quantity': qty,
                                          'max_quantity':
                                              qty, // เริ่มต้น max เท่ากับที่เพิ่ม
                                          'unit': unit,
                                          'expiry_date': selectedDate
                                              ?.toIso8601String(),
                                        });

                                    if (context.mounted) {
                                      Navigator.pop(context); // ปิด Dialog
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("เพิ่มวัตถุดิบสำเร็จ!"),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      _refreshData(); // โหลดหน้าจอใหม่
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text("Error: $e"),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } finally {
                                    setModalState(() => isSaving = false);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSaving
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "เพิ่มวัตถุดิบ",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E6),

      // ✅ ปุ่ม Floating Action Button สำหรับเพิ่ม Manual
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "เพิ่มวัตถุดิบ",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Column(
        children: [
          const CustomHeader(
            title: "Remote Inventory",
            subtitle: "เช็คของในตู้เย็นจากที่ไหนก็ได้",
            showBack: true,
          ),

          // Search & Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFFFF9E6),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => searchQuery = value),
                  decoration: InputDecoration(
                    hintText: "ค้นหาวัตถุดิบ...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((category) {
                      final isSelected = selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            category,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Colors.orange,
                          backgroundColor: Colors.white,
                          showCheckmark: false,
                          onSelected: (bool selected) {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? Colors.orange
                                  : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Inventory List & Summary
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _ingredientsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  );
                }

                final allIngredients = snapshot.data!;

                // 📦 --- เริ่มส่วนที่เพิ่มเข้ามา: จัดกลุ่มวัตถุดิบชื่อเดียวกัน ---
                Map<String, Map<String, dynamic>> groupedMap = {};

                for (var item in allIngredients) {
                  String name = (item['name'] ?? 'ไม่ระบุ').toString().trim();

                  if (groupedMap.containsKey(name)) {
                    // ถ้ามีชื่อนี้อยู่แล้ว ให้บวกจำนวน และ max_quantity เข้าด้วยกัน
                    groupedMap[name]!['quantity'] =
                        (groupedMap[name]!['quantity'] ?? 0) +
                        (item['quantity'] ?? 0);
                    groupedMap[name]!['max_quantity'] =
                        (groupedMap[name]!['max_quantity'] ?? 0) +
                        (item['max_quantity'] ?? 0);

                    // เทียบวันหมดอายุ เลือกล็อตที่หมดอายุก่อนมาแสดง
                    if (groupedMap[name]!['expiry_date'] != null &&
                        item['expiry_date'] != null) {
                      try {
                        DateTime currentExp = DateTime.parse(
                          groupedMap[name]!['expiry_date'],
                        );
                        DateTime newExp = DateTime.parse(item['expiry_date']);
                        if (newExp.isBefore(currentExp)) {
                          groupedMap[name]!['expiry_date'] =
                              item['expiry_date']; // อัปเดตเป็นวันที่ใกล้กว่า
                        }
                      } catch (e) {
                        // ข้ามไปถ้า parse วันที่ไม่ได้
                      }
                    } else if (item['expiry_date'] != null) {
                      groupedMap[name]!['expiry_date'] = item['expiry_date'];
                    }
                  } else {
                    // ถ้ายังไม่มีชื่อนี้ ให้ก๊อปปี้ข้อมูลมาสร้างเป็นกลุ่มใหม่
                    groupedMap[name] = Map<String, dynamic>.from(item);
                  }
                }

                // แปลงกลับเป็น List เพื่อเอาไปใช้งานต่อ
                final groupedIngredients = groupedMap.values.toList();
                // 📦 --- จบส่วนจัดกลุ่ม ---

                // 🔍 เปลี่ยนจาก allIngredients เป็น groupedIngredients ในการ Filter
                final filteredIngredients = groupedIngredients.where((item) {
                  final matchesCategory =
                      selectedCategory == 'ทั้งหมด' ||
                      (item['category'] ?? '').toString().contains(
                        selectedCategory,
                      );
                  final matchesSearch = (item['name'] ?? '')
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase());
                  return matchesCategory && matchesSearch;
                }).toList();

                final totalItems = filteredIngredients.length;
                final expiringSoon = filteredIngredients
                    .where((i) => _getDaysRemaining(i['expiry_date']) <= 3)
                    .length;
                final lowStock = filteredIngredients
                    .where((i) => (i['quantity'] ?? 0) == 0)
                    .length;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (filteredIngredients.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 40, bottom: 40),
                        child: Center(
                          child: Text(
                            "ไม่พบวัตถุดิบ",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      )
                    else
                      ...filteredIngredients.map(
                        (item) => _buildInventoryCard(item),
                      ),

                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "สรุปภาพรวม",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryItem(
                                "$totalItems",
                                "รายการทั้งหมด",
                                Colors.orange,
                              ),
                              _buildSummaryItem(
                                "$expiringSoon",
                                "ใกล้หมดอายุ",
                                Colors.deepOrange,
                              ),
                              _buildSummaryItem(
                                "$lowStock",
                                "ของเหลือน้อย",
                                Colors.pinkAccent,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 80,
                    ), // เผื่อพื้นที่ให้ปุ่ม Floating ไม่ทับ
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    final name = item['name'] ?? 'ไม่ระบุ';
    final quantity = item['quantity'] ?? 0;
    final maxQuantity = item['max_quantity'] ?? quantity;
    final unit = item['unit'] ?? 'ชิ้น';
    final expiryDateStr = item['expiry_date'];

    final daysRemaining = _getDaysRemaining(expiryDateStr);
    final isExpiringSoon = daysRemaining <= 3;
    final progress = (quantity / (maxQuantity == 0 ? 1 : maxQuantity)).clamp(
      0.0,
      1.0,
    );

    Color statusColor = Colors.green;
    String statusText = "เพียงพอ";
    if (progress < 0.3) {
      statusColor = Colors.red;
      statusText = "เหลือน้อย";
    } else if (progress < 0.7) {
      statusColor = Colors.orange;
      statusText = "ปานกลาง";
    }

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ItemDetailScreen(item: item)),
        );
        if (result == true) {
          _refreshData();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: [
                          _buildTag(
                            statusText,
                            statusColor.withOpacity(0.2),
                            Colors.black87,
                          ),
                          if (isExpiringSoon && daysRemaining >= 0)
                            _buildTag(
                              "เหลือ $daysRemaining วัน",
                              Colors.red.withOpacity(0.2),
                              Colors.red,
                            ),
                          if (daysRemaining < 0)
                            _buildTag(
                              "หมดอายุแล้ว",
                              Colors.grey.withOpacity(0.2),
                              Colors.grey,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$quantity $unit",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "จาก $maxQuantity $unit",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.toDouble(),
                backgroundColor: Colors.grey[200],
                color: statusColor,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  int _getDaysRemaining(String? dateStr) {
    if (dateStr == null) return 999;
    try {
      final expiry = DateTime.parse(dateStr);
      final now = DateTime.now();
      return expiry.difference(now).inDays;
    } catch (e) {
      return 999;
    }
  }
}
