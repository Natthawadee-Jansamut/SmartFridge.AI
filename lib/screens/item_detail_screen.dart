import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ItemDetailScreen extends StatefulWidget {
  final String itemId; // รับไอดีจากหน้าคลัง

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  Map<String, dynamic>? _item;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItemDetails();
  }

  // --- ดึงข้อมูลจาก Supabase ---
  Future<void> _fetchItemDetails() async {
    try {
      final response = await Supabase.instance.client
          .from('fridge_items')
          .select()
          .eq('item_id', widget.itemId)
          .single();

      if (mounted) {
        setState(() {
          _item = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("ดึงข้อมูลไม่สำเร็จ: $e"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // --- 🚀 ฟังก์ชันอัปเดตข้อมูลขึ้น Supabase ---
  Future<void> _updateField(String field, dynamic value) async {
    // แสดง Loading ตอนกำลังเซฟ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await Supabase.instance.client
          .from('fridge_items')
          .update({field: value})
          .eq('item_id', widget.itemId);

      if (mounted) Navigator.pop(context); // ปิด Loading
      _fetchItemDetails(); // โหลดข้อมูลใหม่มาโชว์

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('อัปเดตข้อมูลสำเร็จ!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
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

  // --- 🚀 Popup สำหรับพิมพ์แก้ไขข้อความหรือตัวเลข ---
  Future<void> _showEditDialog(
    String title,
    String field,
    String currentValue, {
    bool isNumber = false,
  }) async {
    TextEditingController controller = TextEditingController(
      text: currentValue,
    );

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'แก้ไข$title',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: 'กรอก$titleใหม่',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              dynamic newValue = isNumber
                  ? int.tryParse(controller.text)
                  : controller.text;
              if (newValue != null && newValue.toString().isNotEmpty) {
                _updateField(field, newValue);
              }
            },
            child: const Text('บันทึก', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- 🚀 Popup สำหรับเลือกปฏิทินวันหมดอายุ ---
  Future<void> _selectExpiryDate() async {
    DateTime initialDate = DateTime.now();
    if (_item!['expiry_date'] != null) {
      initialDate = DateTime.parse(_item!['expiry_date'].toString());
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ), // ย้อนหลังได้ 1 ปี
      lastDate: DateTime.now().add(
        const Duration(days: 3650),
      ), // ไปข้างหน้าได้ 10 ปี
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _updateField('expiry_date', picked.toIso8601String());
    }
  }

  // ฟังก์ชันแปลงวันที่
  String _formatThaiDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'ไม่ระบุ';
    try {
      DateTime dt = DateTime.parse(isoString);
      List<String> fullMonths = [
        'มกราคม',
        'กุมภาพันธ์',
        'มีนาคม',
        'เมษายน',
        'พฤษภาคม',
        'มิถุนายน',
        'กรกฎาคม',
        'สิงหาคม',
        'กันยายน',
        'ตุลาคม',
        'พฤศจิกายน',
        'ธันวาคม',
      ];
      return '${dt.day} ${fullMonths[dt.month - 1]} ${dt.year + 543}';
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFDDF0FF),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final item = _item!;

    return Scaffold(
      backgroundColor: const Color(0xFFDDF0FF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // --- Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: Row(
                children: [
                  Container(
                    width: 55,
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8D6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.undo,
                        color: Colors.black,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8D6),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "รายละเอียด",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // --- เนื้อหา ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 35.0),
                child: Column(
                  children: [
                    // 🚀 เชื่อมปุ่มแก้ไขชื่อ
                    _buildDetailRow(
                      icon: Icons.restaurant,
                      text: item['name'] ?? 'ไม่ระบุชื่อ',
                      isTitle: true,
                      hasEdit: true, // เปิดให้แก้ไขชื่อได้ด้วย
                      onEdit: () => _showEditDialog(
                        'ชื่อวัตถุดิบ',
                        'name',
                        item['name'] ?? '',
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 🚀 เชื่อมปุ่มปฏิทิน
                    _buildDetailRow(
                      icon: Icons.calendar_month,
                      text:
                          "หมดอายุ ${_formatThaiDate(item['expiry_date']?.toString())}",
                      onEdit: _selectExpiryDate,
                    ),
                    const SizedBox(height: 10),

                    // 🚀 เชื่อมปุ่มแก้ไขหมวดหมู่
                    _buildDetailRow(
                      icon: Icons.format_list_bulleted,
                      text: "หมวดหมู่ : ${item['category'] ?? 'ไม่ระบุ'}",
                      onEdit: () => _showEditDialog(
                        'หมวดหมู่',
                        'category',
                        item['category'] ?? '',
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 🚀 เชื่อมปุ่มแก้ไขจำนวน
                    _buildDetailRow(
                      icon: Icons.add_circle,
                      text:
                          "จำนวน : ${item['quantity'] ?? 0} ${item['unit'] ?? ''}",
                      onEdit: () => _showEditDialog(
                        'จำนวน',
                        'quantity',
                        item['quantity']?.toString() ?? '0',
                        isNumber: true,
                      ),
                    ),
                    const SizedBox(height: 30),

                    if (item['created_at'] != null)
                      Text(
                        "สร้างเมื่อ ${_formatThaiDate(item['created_at'].toString())}",
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _buildCustomBottomNav(),
          ],
        ),
      ),
    );
  }

  // 🚀 เพิ่มพารามิเตอร์ onEdit เพื่อรับคำสั่งตอนกดปุ่มดินสอ
  Widget _buildDetailRow({
    required IconData icon,
    required String text,
    bool isTitle = false,
    bool hasEdit = true,
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(icon, size: isTitle ? 32 : 28, color: Colors.black),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        text,
                        style: TextStyle(
                          fontSize: isTitle ? 28 : 16,
                          fontWeight: isTitle
                              ? FontWeight.w900
                              : FontWeight.normal,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (hasEdit)
                      GestureDetector(
                        onTap: onEdit, // 🚀 เรียกใช้งานฟังก์ชันเมื่อกดปุ่มดินสอ
                        child: const Icon(
                          Icons.edit,
                          size: 24,
                          color: Colors.black,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 15),
                const Divider(color: Colors.black26, thickness: 1, height: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      height: 75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            Icons.kitchen,
            "หน้าหลัก",
            false,
            onTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          _buildNavItem(Icons.qr_code_scanner, "สแกน", false, onTap: () {}),
          _buildNavItem(
            Icons.list,
            "คลัง",
            true,
            onTap: () => Navigator.pop(context),
          ),
          _buildNavItem(Icons.soup_kitchen, "เมนูอาหาร", false, onTap: () {}),
          _buildNavItem(
            Icons.notifications_none,
            "แจ้งเตือน",
            false,
            onTap: () {},
          ),
          _buildNavItem(Icons.calendar_month, "แพลน", false, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 60,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFF8D6) : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
