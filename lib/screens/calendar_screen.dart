import 'package:flutter/material.dart';
import '../data/app_data.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  List<CalendarEvent> get _eventsForSelectedDate {
    return AppData.calendarEvents.where((e) =>
      e.dateTime.year == _selectedDate.year &&
      e.dateTime.month == _selectedDate.month &&
      e.dateTime.day == _selectedDate.day,
    ).toList()..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  bool _hasEvents(DateTime day) {
    return AppData.calendarEvents.any((e) =>
      e.dateTime.year == day.year &&
      e.dateTime.month == day.month &&
      e.dateTime.day == day.day,
    );
  }

  void _previousMonth() => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));
  void _nextMonth() => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  void _addEvent() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    String category = 'personal';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                    const Text('Nuevo Evento', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: titleCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Título del evento',
                        prefixIcon: const Icon(Icons.event),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descCtrl,
                      decoration: InputDecoration(
                        labelText: 'Descripción (opcional)',
                        prefixIcon: const Icon(Icons.notes),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () async {
                              final time = await showTimePicker(context: context, initialTime: selectedTime);
                              if (time != null) setSheetState(() => selectedTime = time);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: category,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'personal', child: Text('Personal')),
                              DropdownMenuItem(value: 'work', child: Text('Trabajo')),
                              DropdownMenuItem(value: 'finance', child: Text('Finanzas')),
                              DropdownMenuItem(value: 'health', child: Text('Salud')),
                              DropdownMenuItem(value: 'other', child: Text('Otro')),
                            ],
                            onChanged: (v) { if (v != null) setSheetState(() => category = v); },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) return;
                        final eventDate = DateTime(
                          _selectedDate.year, _selectedDate.month, _selectedDate.day,
                          selectedTime.hour, selectedTime.minute,
                        );
                        setState(() {
                          AppData.calendarEvents.add(CalendarEvent(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: title,
                            description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                            dateTime: eventDate,
                            category: category,
                          ));
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Guardar Evento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteEvent(CalendarEvent event) {
    setState(() => AppData.calendarEvents.remove(event));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evento eliminado')));
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'work': return Colors.blue;
      case 'finance': return const Color(0xFFF59E0B);
      case 'health': return const Color(0xFF10B981);
      case 'other': return Colors.grey;
      default: return const Color(0xFF0F172A);
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'work': return Icons.work_outline;
      case 'finance': return Icons.attach_money;
      case 'health': return Icons.favorite_outline;
      case 'other': return Icons.label_outline;
      default: return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday; // 1=Mon
    final monthNames = ['', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendario y Eventos'),
        backgroundColor: const Color(0xFFFEF3C7),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Month Navigation ─────────────────────────────
          Container(
            color: const Color(0xFFFEF3C7),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: _previousMonth),
                Text(
                  '${monthNames[_focusedMonth.month]} ${_focusedMonth.year}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
              ],
            ),
          ),

          // ── Day labels ───────────────────────────────────
          Container(
            color: const Color(0xFFFEF3C7),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: ['L', 'M', 'X', 'J', 'V', 'S', 'D']
                  .map((d) => Expanded(
                        child: Center(child: Text(d, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 13))),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 4),

          // ── Calendar Grid ────────────────────────────────
          Container(
            color: const Color(0xFFFEF3C7),
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
              itemCount: daysInMonth + firstWeekday - 1,
              itemBuilder: (context, index) {
                if (index < firstWeekday - 1) return const SizedBox();
                final day = index - firstWeekday + 2;
                final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
                final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                final isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
                final hasEvent = _hasEvents(date);

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF0F172A)
                          : isToday
                              ? const Color(0xFFF59E0B).withOpacity(0.2)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$day',
                          style: TextStyle(
                            fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (hasEvent)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: 5, height: 5,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : const Color(0xFFF59E0B),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Events List ──────────────────────────────────
          Expanded(
            child: _eventsForSelectedDate.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_available, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Sin eventos para el ${_selectedDate.day}/${_selectedDate.month}',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _eventsForSelectedDate.length,
                    itemBuilder: (context, index) {
                      final event = _eventsForSelectedDate[index];
                      final color = _categoryColor(event.category);
                      return Dismissible(
                        key: Key(event.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(14)),
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteEvent(event),
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 1,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: CircleAvatar(
                              backgroundColor: color.withOpacity(0.15),
                              child: Icon(_categoryIcon(event.category), color: color, size: 20),
                            ),
                            title: Text(
                              event.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: (event.isDone && event.category != 'history') ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            subtitle: Text(
                              '${event.dateTime.hour.toString().padLeft(2, '0')}:${event.dateTime.minute.toString().padLeft(2, '0')}${event.description != null ? ' · ${event.description}' : ''}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            trailing: event.category == 'history'
                                ? null
                                : Checkbox(
                                    value: event.isDone,
                                    activeColor: const Color(0xFF10B981),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                    onChanged: (val) {
                                      setState(() => event.isDone = val ?? false);
                                      // LocalDatabase.updateCalendarEvent(event); // Optional: if update method exists
                                    },
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        onPressed: _addEvent,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Evento'),
      ),
    );
  }
}
