import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'storage.dart';
import 'models.dart';
import 'widgets.dart';
import 'create.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  DateTime? _filterDate; // null = default (today tasks first)

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<List<TaskItem>> _load() async {
    await AppDb.instance.seedTasksIfEmpty();
    // listTasks() already sorts today's scheduled tasks first by default
    return AppDb.instance.listTasks(forDate: _filterDate);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _filterDate ?? _dateOnly(now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null) return;

    setState(() => _filterDate = _dateOnly(picked));
  }

  void _clearFilter() => setState(() => _filterDate = null);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isTodayMode = _filterDate == null;

    final shownDate = isTodayMode ? _dateOnly(now) : _filterDate!;
    final line1 = isTodayMode ? "Today" : DateFormat('EEEE').format(shownDate); // Today OR Wednesday
    final line2 = DateFormat('EEEE, d MMM').format(shownDate); // Wednesday, 31 Dec

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(title: "Tasks"),

          // ✅ 2-line date header + calendar actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x11000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          line1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          line2,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: "Pick date",
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month),
                  ),
                  if (!isTodayMode)
                    IconButton(
                      tooltip: "Back to Today",
                      onPressed: _clearFilter,
                      icon: const Icon(Icons.today),
                    ),
                ],
              ),
            ),
          ),

          Expanded(
            child: FutureBuilder<List<TaskItem>>(
              future: _load(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final list = snap.data!;
                if (list.isEmpty) return const EmptyState(text: "No tasks");

                return RefreshIndicator(
                  onRefresh: () async => setState(() {}),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _taskCard(list[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskCard(TaskItem t) {
    final sched = DateFormat('M/d/y').format(t.scheduledAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 6),
              Text(t.customerName, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 4),
              Text(t.phone, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              Text("Scheduled $sched", style: const TextStyle(color: Colors.grey)),
            ]),
          ),
          TextButton(
            onPressed: () => _openTaskMenu(t),
            child: const Text("Open"),
          ),
        ],
      ),
    );
  }

  void _openTaskMenu(TaskItem task) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Expanded(child: Text(task.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18))),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.visibility_outlined),
            title: const Text("View Task", style: TextStyle(fontWeight: FontWeight.w800)),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(task.title),
                  content: Text(
                    "${task.customerName}\n${task.phone}\n${task.email}\n${task.address}"
                    "\n\nScheduled: ${DateFormat('EEE, MMM d, y').format(task.scheduledAt)}",
                  ),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text("Delete Task", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.red)),
            onTap: () async {
              await AppDb.instance.deleteTask(task.id);
              if (mounted) setState(() {});
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.play_arrow_outlined),
            title: const Text("Activate Task", style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: const Text("Will open Create page with prefilled customer"),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => CreateWorkItemPage(prefillTask: task)),
              );
            },
          ),
        ]),
      ),
    );
  }
}
