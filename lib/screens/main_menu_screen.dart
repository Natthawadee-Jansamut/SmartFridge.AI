import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ImageScanning.dart'; // Import หน้าสแกน
import 'inventory_screen.dart'; // Import หน้าคลังวัตถุดิบ
import 'ai_recipe_screen.dart';
import 'ai_meal_planning_screen.dart'; // เช็กชื่อไฟล์ให้ตรงกับที่คุณน้าเซฟไว้นะครับ

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  // ตัวแปรสำหรับโชว์ตัวเลขสรุป (ดึงจริงจาก DB ได้ในอนาคต)
  int totalItems = 0;
  int expiringSoon = 0;

  @override
  void initState() {
    super.initState();
    _fetchSummary(); // ดึงข้อมูลสรุปตอนเปิดหน้า
  }

  // ฟังก์ชันดึงข้อมูลสรุปจาก Supabase (ถ้ามี)
  Future<void> _fetchSummary() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('fridge_items').select();
      final data = response as List<dynamic>;

      setState(() {
        totalItems = data.length;
        // นับของที่เหลือวันหมดอายุน้อยกว่า 3 วัน
        expiringSoon = data.where((item) {
          final expiry = DateTime.parse(item['expiry_date']);
          final diff = expiry.difference(DateTime.now()).inDays;
          return diff <= 3;
        }).length;
      });
    } catch (e) {
      print("Error fetching summary: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // พื้นหลัง Gradient ม่วง-ครีม ตามแบบ
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF3E5F5), // ม่วงอ่อนมาก
              Color(0xFFFFF9C4), // เหลืองครีม
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 20),

              // --- 1. Header Logo & Title ---
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.purpleAccent,
                            Colors.deepOrangeAccent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "Smart Fridge",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const Text(
                      "ตู้เย็นอัจฉริยะของคุณ",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- 2. Menu Buttons List ---

              /// ปุ่ม AI Recipe Generator
              _buildMenuCard(
                icon: Icons.auto_awesome,
                iconColor: Colors.pinkAccent,
                title: "AI Recipe Generator",
                subtitle: "สร้างเมนูจากวัตถุดิบที่มี",
                onTap: () {
                  // ✅ เปลี่ยนเป็นเปิดหน้าใหม่
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AiRecipeScreen(),
                    ),
                  );
                },
              ),

              // ปุ่ม Smart Recipe Capture (Demo)
              _buildMenuCard(
                icon: Icons.document_scanner,
                iconColor: Colors.deepPurpleAccent,
                title: "Smart Recipe Capture",
                subtitle: "สแกนสูตรอาหารอัตโนมัติ",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("ฟีเจอร์นี้กำลังพัฒนา...")),
                  );
                },
              ),

              // ✅ ปุ่ม Remote Inventory (ไปหน้า InventoryScreen)
              _buildMenuCard(
                icon: Icons.kitchen,
                iconColor: Colors.orange,
                title: "Remote Inventory",
                subtitle: "เช็คของในตู้เย็นจากที่ไหนก็ได้",
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InventoryScreen(),
                    ),
                  );
                  _fetchSummary(); // โหลดข้อมูลใหม่เมื่อกลับมา
                },
              ),

              // ปุ่ม Expiration Alert (Demo)
              _buildMenuCard(
                icon: Icons.notifications_active,
                iconColor: Colors.pink,
                title: "Expiration Alert",
                subtitle: "เตือนวันหมดอายุล่วงหน้า",
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("ฟีเจอร์นี้กำลังพัฒนา...")),
                  );
                },
              ),

              // ปุ่ม AI Meal Planning (Demo)
              _buildMenuCard(
                icon: Icons.calendar_month,
                iconColor: Colors.purpleAccent,
                title: "AI Meal Planning",
                subtitle: "วางแผนอาหารประจำสัปดาห์",
                onTap: () {
                  // ลบ SnackBar ออก แล้วใส่คำสั่งเปลี่ยนหน้าจอแทน
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIMealPlanningScreen(),
                    ),
                  );
                },
              ),

              // ✅ ปุ่ม Image Scanning (ไปหน้า ImageScanning)
              _buildMenuCard(
                icon: Icons.camera_alt_rounded,
                iconColor: Colors.amber,
                title: "Image Scanning",
                subtitle: "ถ่ายรูปสแกนวัตถุดิบ",
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ImageScanning(),
                    ),
                  );
                  _fetchSummary(); // โหลดข้อมูลใหม่เมื่อกลับมา
                },
              ),

              const SizedBox(height: 30),

              // --- 3. Footer Stats ---
              Row(
                children: [
                  _buildStatCard(
                    "24",
                    "วัตถุดิบทั้งหมด",
                    const Color(0xFFFFEBEE),
                    Colors.pink,
                  ), // ใช้เลขสมมติไปก่อน หรือใช้ totalItems
                  const SizedBox(width: 15),
                  _buildStatCard(
                    "$expiringSoon",
                    "ใกล้หมดอายุ",
                    const Color(0xFFF3E5F5),
                    Colors.purple,
                  ),
                  const SizedBox(width: 15),
                  _buildStatCard(
                    "12",
                    "สูตรอาหาร",
                    const Color(0xFFFFF9C4),
                    Colors.orange[800]!,
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Widget สร้างการ์ดเมนู
  Widget _buildMenuCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget สร้างการ์ดสถิติด้านล่าง
  Widget _buildStatCard(
    String count,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(fontSize: 12, color: textColor)),
          ],
        ),
      ),
    );
  }
}
