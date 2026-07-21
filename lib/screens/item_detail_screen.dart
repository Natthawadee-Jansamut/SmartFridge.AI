import 'package:flutter/material.dart';

class ItemDetailScreen extends StatefulWidget {
  final Map<String, dynamic> itemData;
  const ItemDetailScreen({super.key, required this.itemData});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
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
    final item = widget.itemData;

    return Scaffold(
      backgroundColor: const Color(0xFFDDF0FF),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 35.0),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.restaurant,
                      text: item['name'] ?? 'ไม่ระบุชื่อ',
                      isTitle: true,
                      hasEdit: false,
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      icon: Icons.calendar_month,
                      text:
                          "หมดอายุ ${_formatThaiDate(item['expiry_date']?.toString())}",
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      icon: Icons.format_list_bulleted,
                      text: "หมวดหมู่ : ${item['category'] ?? 'ไม่ระบุ'}",
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow(
                      icon: Icons.add_circle,
                      text:
                          "จำนวน : ${item['quantity'] ?? 0} ${item['unit'] ?? ''}",
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

  Widget _buildDetailRow({
    required IconData icon,
    required String text,
    bool isTitle = false,
    bool hasEdit = true,
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
                        onTap: () {},
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
