import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_header.dart'; // ใช้ Header เดิม

class ItemDetailScreen extends StatefulWidget {
  // รับข้อมูลวัตถุดิบชิ้นนั้นๆ มาจากหน้า Inventory
  final Map<String, dynamic> item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  String _unit = 'ชิ้น';
  DateTime? _selectedDate;
  bool _isLoading = false;

  final List<String> _unitList = [
    "ชิ้น",
    "กรัม",
    "กก.",
    "แพ็ค",
    "ขวด",
    "ลูก",
    "ฟอง",
    "กล่อง",
  ];

  @override
  void initState() {
    super.initState();
    // กำหนดค่าเริ่มต้นจากข้อมูลที่รับมา
    _nameController = TextEditingController(text: widget.item['name']);
    _quantityController = TextEditingController(
      text: widget.item['quantity'].toString(),
    );
    _unit = widget.item['unit'] ?? 'ชิ้น';
    if (!_unitList.contains(_unit)) _unit = _unitList[0];

    if (widget.item['expiry_date'] != null) {
      _selectedDate = DateTime.parse(widget.item['expiry_date']);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // ฟังก์ชันเลือกวันที่
  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.purple, // สีหัวปฏิทิน
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ฟังก์ชันบันทึกการแก้ไข
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client
          .from('fridge_items')
          .update({
            'name': _nameController.text,
            'quantity': int.parse(_quantityController.text),
            'unit': _unit,
            'expiry_date': _selectedDate?.toIso8601String(),
          })
          .eq('id', widget.item['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกข้อมูลเรียบร้อย'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ฟังก์ชันลบวัตถุดิบ
  Future<void> _deleteItem() async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("ยืนยันการลบ"),
            content: const Text("คุณแน่ใจหรือไม่ที่จะลบวัตถุดิบนี้?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("ยกเลิก"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text("ลบ"),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('fridge_items')
          .delete()
          .eq('id', widget.item['id']);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ลบไม่สำเร็จ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate = _selectedDate == null
        ? "ไม่ระบุวันหมดอายุ"
        : DateFormat('dd/MM/yyyy').format(_selectedDate!);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3E5F5), Color(0xFFFFF9C4)],
          ),
        ),
        child: Column(
          children: [
            // Header พร้อมปุ่มลบ
            Stack(
              children: [
                const CustomHeader(
                  title: "รายละเอียด",
                  subtitle: "แก้ไขข้อมูลวัตถุดิบ",
                  showBack: true,
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 15,
                  right: 20,
                  child: IconButton(
                    onPressed: _isLoading ? null : _deleteItem,
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.white.withOpacity(0.9),
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // 1. ชื่อวัตถุดิบ
                            _buildInputField(
                              label: "ชื่อวัตถุดิบ",
                              icon: Icons.restaurant_menu,
                              child: TextFormField(
                                controller: _nameController,
                                decoration: _inputDecoration(
                                  "เช่น นมสด, ไข่ไก่",
                                ),
                                validator: (v) =>
                                    v!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                              ),
                            ),
                            const Divider(height: 30),

                            // 2. ปริมาณ (แบบมีปุ่ม - +) และหน่วย
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: _buildInputField(
                                    label: "ปริมาณ",
                                    icon: Icons.format_list_numbered_rounded,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // ปุ่มลบ
                                          _buildCounterButton(Icons.remove, () {
                                            int current =
                                                int.tryParse(
                                                  _quantityController.text,
                                                ) ??
                                                0;
                                            if (current > 1) {
                                              setState(() {
                                                _quantityController.text =
                                                    (current - 1).toString();
                                              });
                                            }
                                          }),

                                          // ช่องกรอกตัวเลข
                                          SizedBox(
                                            width: 50,
                                            child: TextFormField(
                                              controller: _quantityController,
                                              keyboardType:
                                                  TextInputType.number,
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                isDense: true,
                                                contentPadding: EdgeInsets.zero,
                                              ),
                                              validator: (v) =>
                                                  v!.isEmpty ? 'ระบุ' : null,
                                            ),
                                          ),

                                          // ปุ่มบวก
                                          _buildCounterButton(Icons.add, () {
                                            int current =
                                                int.tryParse(
                                                  _quantityController.text,
                                                ) ??
                                                0;
                                            setState(() {
                                              _quantityController.text =
                                                  (current + 1).toString();
                                            });
                                          }),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  flex: 3,
                                  child: _buildInputField(
                                    label: "หน่วย",
                                    icon: Icons.scale_rounded,
                                    child: DropdownButtonFormField<String>(
                                      value: _unit,
                                      isExpanded: true,
                                      decoration: _inputDecoration(""),
                                      items: _unitList
                                          .map(
                                            (e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _unit = v!),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 30),

                            // 3. วันหมดอายุ
                            _buildInputField(
                              label: "วันหมดอายุ",
                              icon: Icons.calendar_today_rounded,
                              child: InkWell(
                                onTap: () => _pickDate(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 15,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          color: _selectedDate == null
                                              ? Colors.grey
                                              : Colors.black87,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.edit_calendar,
                                        color: Colors.purpleAccent,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ปุ่มบันทึก
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveChanges,
                          style:
                              ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ).copyWith(
                                backgroundColor: MaterialStateProperty.all(
                                  Colors.transparent,
                                ),
                              ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.purple, Colors.deepOrange],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.deepOrange.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "บันทึกการแก้ไข",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget สร้างปุ่ม + -
  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.05),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: Colors.purple),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.purple.shade300),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.purpleAccent, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }
}
