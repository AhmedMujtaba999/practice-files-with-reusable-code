import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'storage.dart';
import 'models.dart';
import 'widgets.dart';
import 'create.dart';
import 'theme.dart';

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
    final titleLine = isTodayMode ? "Today" : DateFormat('EEEE').format(shownDate);
    final dateLine = DateFormat('EEEE, d MMM').format(shownDate);

    // For the badge
    final dayNumber = DateFormat('d').format(shownDate);
    final monthShort = DateFormat('MMM').format(shownDate).toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          const GradientHeader(title: "Tasks"),

          // ✅ Professional highlighted date header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _dateHeaderCard(
              titleLine: titleLine,
              dateLine: dateLine,
              dayNumber: dayNumber,
              monthShort: monthShort,
              isTodayMode: isTodayMode,
              onPickDate: _pickDate,
              onBackToToday: _clearFilter,
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

  Widget _dateHeaderCard({
    required String titleLine,
    required String dateLine,
    required String dayNumber,
    required String monthShort,
    required bool isTodayMode,
    required VoidCallback onPickDate,
    required VoidCallback onBackToToday,
  }) {
    return Container(
      decoration: BoxDecoration(
        // ✅ Different & professional (not plain white, not full blue)
        color: const Color(0xFFF6F7FF), // soft lavender tint
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E9FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left accent strip
          Container(
            width: 6,
            height: 82,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(width: 12),

          // Date badge (big day number)
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE7E9FF)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  monthShort,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titleLine,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  dateLine,
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

          // Actions (pill buttons)
          _pillButton(
            icon: Icons.calendar_month,
            label: "Calendar",
            onTap: onPickDate,
          ),
          const SizedBox(width: 10),
          if (!isTodayMode)
            _pillButton(
              icon: Icons.today,
              label: "Today",
              onTap: onBackToToday,
            ),

          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _pillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7E9FF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
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
