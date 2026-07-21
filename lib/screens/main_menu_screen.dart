import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_screen.dart';
import 'ImageScanning.dart';
import 'inventory_screen.dart';
import 'ai_recipe_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final supabase = Supabase.instance.client;

  String userName = "User";

  // 🚀 ตัวแปรเก็บสถิติต่างๆ ของตู้เย็น
  int totalItemsCount = 0;
  int nearExpiryCount = 0;
  int expiredCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadData();
  }

  // 🚀 ฟังก์ชันโหลดทั้งชื่อ User และสถิติจากตู้เย็นพร้อมกัน
  Future<void> loadData() async {
    await loadUser();
    await _fetchFridgeStats();
  }

  Future<void> loadUser() async {
    final session = supabase.auth.currentSession;
    if (session == null) return;

    final response = await supabase.auth.getUser();
    final user = response.user;

    if (user != null) {
      final firstName = user.userMetadata?['first_name'] ?? "";
      final lastName = user.userMetadata?['last_name'] ?? "";

      if (mounted) {
        setState(() {
          userName = "$firstName $lastName";
        });
      }
    }
  }

  // --- 🚀 ฟังก์ชันดึงสถิติจริงจาก Supabase (inventory) ---
  Future<void> _fetchFridgeStats() async {
    final session = supabase.auth.currentSession;
    if (session == null) return;

    try {
      final response = await supabase
          .from('fridge_items')
          .select()
          .eq('user_id', session.user.id);

      List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
        response,
      );

      int total = items.length;
      int nearExpiry = 0;
      int expired = 0;

      DateTime now = DateTime.now();
      // ตัดเวลาออกให้เหลือแต่วัน เพื่อการเปรียบเทียบที่แม่นยำ
      DateTime today = DateTime(now.year, now.month, now.day);

      for (var item in items) {
        if (item['expiry_date'] != null) {
          DateTime expDate = DateTime.parse(item['expiry_date'].toString());
          DateTime expDayOnly = DateTime(
            expDate.year,
            expDate.month,
            expDate.day,
          );

          int diffDays = expDayOnly.difference(today).inDays;

          if (diffDays < 0) {
            expired++; // หมดอายุแล้ว
          } else if (diffDays <= 3) {
            nearExpiry++; // ใกล้หมดอายุ (ภายใน 3 วัน)
          }
        }
      }

      if (mounted) {
        setState(() {
          totalItemsCount = total;
          nearExpiryCount = nearExpiry;
          expiredCount = expired;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffD8EEFF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, size) {
            final screenHeight = size.maxHeight;
            final screenWidth = size.maxWidth;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.07,
                vertical: screenHeight * 0.03,
              ),
              child: Column(
                children: [
                  // ================= HEADER =================
                  SizedBox(
                    height: screenHeight * 0.12,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: screenWidth * 0.07,
                          backgroundColor: const Color(0xff5189C9),
                          child: Icon(
                            Icons.person,
                            size: screenWidth * 0.09,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.03),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "SmartFridge",
                                style: TextStyle(
                                  fontSize: screenWidth * 0.065,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "ตู้เย็นอัจฉริยะของคุณ $userName",
                                style: TextStyle(fontSize: screenWidth * 0.035),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.settings, size: screenWidth * 0.08),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                            loadData(); // โหลดข้อมูลใหม่หลังกลับจาก Profile
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.025),

                  // ================= SUMMARY (ดึงจาก Inventory จริง) =================
                  Container(
                    height: screenHeight * 0.09,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: _isLoadingStats
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            children: [
                              stat("$totalItemsCount", "รายการ", Colors.green),
                              divider(),
                              stat(
                                "$nearExpiryCount",
                                "ใกล้หมดอายุ",
                                Colors.orange,
                              ),
                              divider(),
                              stat("$expiredCount", "หมดแล้ว", Colors.red),
                            ],
                          ),
                  ),

                  SizedBox(height: screenHeight * 0.06),

                  // ================= MENU =================
                  Expanded(
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 6,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: screenWidth * 0.04,
                        mainAxisSpacing: screenHeight * 0.025,
                        childAspectRatio: 1.15,
                      ),
                      itemBuilder: (context, index) {
                        final menus = [
                          [
                            Icons.camera_alt,
                            "ถ่ายภาพวัตถุดิบ",
                            "เพิ่มของในตู้เย็น",
                          ],
                          [
                            Icons.calendar_month,
                            "แพลนอาหาร",
                            "สร้างเมนูรายสัปดาห์",
                          ],
                          [
                            Icons.notifications,
                            "วันหมดอายุ",
                            "แจ้งเตือนหมดอายุ",
                          ],
                          [
                            Icons.kitchen,
                            "เช็คตู้เย็น",
                            "ดูวัตถุดิบได้จากทุกที่",
                          ],
                          [
                            Icons.document_scanner,
                            "สแกนสูตรอาหาร",
                            "บันทึกสูตรเข้าคลัง",
                          ],
                          [
                            Icons.restaurant,
                            "สร้างเมนูอาหาร",
                            "จากของที่มีอยู่",
                          ],
                        ];

                        return menuCard(
                          menus[index][0] as IconData,
                          menus[index][1] as String,
                          menus[index][2] as String,
                          () async {
                            if (index == 0) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ImageScanning(),
                                ),
                              );
                              loadData(); // รีเฟรชสถิติเมื่อกลับมาจากหน้าสแกน
                            }

                            if (index == 3) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const InventoryScreen(),
                                ),
                              );
                              loadData(); // รีเฟรชสถิติเมื่อกลับมาจากหน้าคลัง
                            }

                            if (index == 5) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AiRecipeScreen(),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget stat(String number, String title, Color color) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            number,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 3),
          Text(title, style: const TextStyle(color: Colors.blue, fontSize: 13)),
        ],
      ),
    );
  }

  Widget divider() {
    return Container(height: 45, width: 1, color: Colors.amber);
  }

  Widget menuCard(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback tap,
  ) {
    return InkWell(
      onTap: tap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xff4F8FE8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 55,
              height: 55,
              decoration: const BoxDecoration(
                color: Color(0xfffff38a),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xff5189C9), size: 32),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
