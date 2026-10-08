import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'add_agent_screen.dart';

class AgentsManagementScreen extends StatefulWidget {
  const AgentsManagementScreen({super.key});

  @override
  State<AgentsManagementScreen> createState() => _AgentsManagementScreenState();
}

class _AgentsManagementScreenState extends State<AgentsManagementScreen> {
  List<Map<String, dynamic>> _agents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgents();
  }

  Future<void> _loadAgents() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllAgents();
    setState(() { _agents = data; _isLoading = false; });
  }

  Future<void> _deleteAgent(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تایید حذف'),
          content: const Text('آیا از حذف این مشاور مطمئن هستید؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('انصراف')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('حذف')),
          ],
        ),
      ),
    );
    if (confirm == true) {
      final db = await DatabaseHelper.instance.database;
      await db.delete('agents', where: 'id = ?', whereArgs: [id]);
      _loadAgents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ مشاور حذف شد'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت مشاوران'),
        backgroundColor: Colors.purple[700],
        centerTitle: true, // وسط‌چین
        foregroundColor: Colors.white, // سفید
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAgents)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _agents.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('هنوز مشاوری ثبت نشده', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _agents.length,
                  itemBuilder: (context, index) {
                    final agent = _agents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: agent['status'] == 'active' ? Colors.green[100] : Colors.grey[300],
                                    child: Icon(Icons.person, color: agent['status'] == 'active' ? Colors.green[800] : Colors.grey[700]),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(agent['name']?.toString() ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(agent['phone']?.toString() ?? '', style: TextStyle(color: Colors.grey[700])),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: agent['status'] == 'active' ? Colors.green[100] : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      agent['status'] == 'active' ? 'فعال' : 'غیرفعال',
                                      style: TextStyle(
                                        color: agent['status'] == 'active' ? Colors.green[800] : Colors.grey[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.percent, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('کمیسیون: ${agent['commission_rate']}%'),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('حقوق: ${(agent['base_salary']?.toInt() ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} تومان'),
                                ],
                              ),
                              if (agent['national_id'] != null && (agent['national_id'] as String).isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.badge, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text('کد ملی: ${agent['national_id']}'),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => AddAgentScreen(agentId: agent['id'])),
                                        );
                                        if (result == true) _loadAgents();
                                      },
                                      icon: const Icon(Icons.edit),
                                      label: const Text('ویرایش', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _deleteAgent(agent['id']),
                                      icon: const Icon(Icons.delete),
                                      label: const Text('حذف', style: TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddAgentScreen()));
          if (result == true) _loadAgents();
        },
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white, // <-- اصلاح ۲: سفید شدن نوشته دکمه
        icon: const Icon(Icons.add),
        label: const Text('افزودن مشاور'),
      ),
    );
  }
}
