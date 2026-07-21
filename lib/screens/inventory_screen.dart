import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'item_detail_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String? _selectedCategory;
  List<Map<String, dynamic>> _inventoryItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInventoryData();
  }

  Future<void> _fetchInventoryData() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('fridge_items')
          .select()
          .order(
            'item_id',
            ascending: false,
          ); // เรียงตาม item_id ที่มีในฐานข้อมูล

      setState(() {
        _inventoryItems = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("เกิดข้อผิดพลาดในการดึงข้อมูล: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(String id) async {
    try {
      await Supabase.instance.client
          .from('fridge_items')
          .delete()
          .eq('item_id', id); // อ้างอิงตาม item_id
      _fetchInventoryData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("ลบข้อมูลไม่สำเร็จ: $e")));
    }
  }

  String _getCategoryIcon(String category) {
    if (category.contains('ผลไม้')) return '🍎';
    if (category.contains('ผัก')) return '🥕';
    if (category.contains('เนื้อ') ||
        category.contains('หมู') ||
        category.contains('ไก่'))
      return '🥩';
    if (category.contains('แป้ง') || category.contains('ข้าว')) return '🍞';
    if (category.contains('เครื่องดื่ม') ||
        category.contains('น้ำ') ||
        category.contains('นม'))
      return '🥛';
    if (category.contains('ขนม')) return '🍬';
    return '📦';
  }

  String _getSubtitle(Map<String, dynamic> item) {
    if (item['expiry_date'] != null) {
      DateTime expDate = DateTime.parse(item['expiry_date'].toString());
      int diffDays = expDate.difference(DateTime.now()).inDays;
      if (diffDays < 0) return 'หมดอายุแล้ว';
      if (diffDays == 0) return 'หมดอายุวันนี้';
      return 'หมดอายุในอีก $diffDays วัน';
    }
    return 'จำนวน : ${item['quantity'] ?? 1} ${item['unit'] ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    bool isCategoryView = _selectedCategory == null;
    final Set<String> uniqueCategories = _inventoryItems
        .map((item) => (item['category'] ?? 'อื่นๆ').toString())
        .toSet();
    final List<Map<String, dynamic>> displayedItems = isCategoryView
        ? _inventoryItems
        : _inventoryItems
              .where(
                (item) => (item['category'] ?? 'อื่นๆ') == _selectedCategory,
              )
              .toList();

    int totalItems = isCategoryView
        ? _inventoryItems.length
        : displayedItems.length;
    int nearExpiryCount = 0;
    int outOfStockCount = 0;

    for (var item in (isCategoryView ? _inventoryItems : displayedItems)) {
      if (item['expiry_date'] != null) {
        int diff = DateTime.parse(
          item['expiry_date'].toString(),
        ).difference(DateTime.now()).inDays;
        if (diff >= 0 && diff <= 3) nearExpiryCount++;
      }
      if (item['quantity'] == 0 || item['quantity'] == '0') outOfStockCount++;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchInventoryData,
          color: Colors.blue,
          child: Column(
            children: [
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    if (!isCategoryView) ...[
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7D0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.undo, color: Colors.black87),
                          onPressed: () =>
                              setState(() => _selectedCategory = null),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isCategoryView
                                ? Colors.blue
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: isCategoryView
                                ? "วัตถุดิบทั้งหมด"
                                : _selectedCategory,
                            hintStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            prefixIcon: const Icon(
                              Icons.list,
                              color: Colors.black,
                            ),
                            suffixIcon: const Icon(
                              Icons.search,
                              color: Colors.black,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                          ),
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
                      child: const Icon(Icons.filter_list, color: Colors.black),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn("$totalItems", "รายการ"),
                        const VerticalDivider(
                          color: Colors.grey,
                          thickness: 0.5,
                        ),
                        _buildStatColumn("$nearExpiryCount", "ใกล้หมดอายุ"),
                        const VerticalDivider(
                          color: Colors.grey,
                          thickness: 0.5,
                        ),
                        _buildStatColumn("$outOfStockCount", "หมดแล้ว"),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // ในหน้า inventory_screen.dart ส่วนของ build method
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.blue),
                      )
                    : _inventoryItems
                          .isEmpty // 🚀 เช็กตรงนี้ครับ ถ้า list ว่าง
                    ? const Center(
                        child: Text(
                          "ยังไม่มีวัตถุดิบในตู้เย็น", // ข้อความนี้จะขึ้นเมื่อไม่มีของ
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                      )
                    : ListView(
                        // 🚀 ถ้ามีของค่อยแสดง ListView
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          if (isCategoryView)
                            ...uniqueCategories.map(
                              (cat) => _buildCategoryCard(
                                cat,
                                _getCategoryIcon(cat),
                              ),
                            )
                          else
                            ...displayedItems.map(
                              (item) => _buildItemCard(context, item),
                            ),
                          const SizedBox(height: 10),
                          _buildAddButton(
                            isCategoryView
                                ? "+ เพิ่มหมวดหมู่"
                                : "+ เพิ่มวัตถุดิบ",
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
              ),
              _buildCustomBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildCategoryCard(String name, String icon) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = name),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7D0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 35)),
            const SizedBox(width: 20),
            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Map<String, dynamic> item) {
    String id = item['item_id'].toString();
    String name = item['name'] ?? 'ไม่ระบุชื่อ';
    String subtitle = _getSubtitle(item);
    String icon = _getCategoryIcon(item['category'] ?? '');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailScreen(itemData: item),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7D0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: subtitle.contains('หมดอายุ')
                          ? Colors.red.shade700
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 15),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("ยืนยันการลบ"),
                        content: Text("คุณต้องการลบ $name ใช่หรือไม่?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("ยกเลิก"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteItem(id);
                            },
                            child: const Text(
                              "ลบ",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.delete,
                    color: Colors.black87,
                    size: 28,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            Icons.kitchen,
            "หน้าหลัก",
            false,
            onTap: () => Navigator.pop(context),
          ),
          _buildNavItem(Icons.qr_code_scanner, "สแกน", false, onTap: () {}),
          _buildNavItem(Icons.list, "คลัง", true, onTap: () {}),
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
          color: isActive ? const Color(0xFFFFF7D0) : Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
