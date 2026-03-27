import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

const kBgDark    = Color(0xFF0A0A0A);
const kBgCard    = Color(0xFF181818);
const kBgCard2   = Color(0xFF202020);
const kGold      = Color(0xFFD4AF37);
const kGoldLight = Color(0xFFEDD56A);
const kGoldDark  = Color(0xFF9E7E1A);
const kGoldDim   = Color(0xFF3A2E0A);
const kTextPri   = Colors.white;
const kTextSec   = Color(0xFFAAAAAA);
const kTeal      = Color(0xFF4A90E2); // Slightly pleasing color, or use Color(0xFF56B4A3) for teal
const kEventColor = Color(0xFF56B4A3); // Matches the sample image green/teal chips


class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  bool _isLoading = false;
  List<dynamic> _agendas = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAgenda(_focusedDay.month, _focusedDay.year);
  }

  Future<void> _fetchAgenda(int month, int year) async {
    setState(() => _isLoading = true);
    final response = await ApiService.getAgenda(month: month, year: year);
    if (response != null && response['success'] == true) {
      setState(() {
        _agendas = response['data'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _agendas.where((agenda) {
      if (agenda['instanceDate'] == null) return false;
      
      final startDt = DateTime.parse(agenda['instanceDate']).toLocal();
      final endDtStr = agenda['instanceWaktuSelesai'] ?? agenda['instanceDate'];
      final endDt = DateTime.parse(endDtStr).toLocal();
      
      final startDate = DateTime(startDt.year, startDt.month, startDt.day);
      final endDate = DateTime(endDt.year, endDt.month, endDt.day);
      final targetDate = DateTime(day.year, day.month, day.day);

      return (targetDate.isAtSameMomentAs(startDate) || targetDate.isAfter(startDate)) && 
             (targetDate.isAtSameMomentAs(endDate) || targetDate.isBefore(endDate));
    }).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _fetchAgenda(focusedDay.month, focusedDay.year);
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: const Text('Kalender Agenda', style: TextStyle(color: kGoldLight, fontWeight: FontWeight.bold)),
        backgroundColor: kBgCard,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kGold),
      ),
      body: Column(
        children: [
          Container(
            color: kBgCard,
            padding: const EdgeInsets.only(bottom: 8),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              rowHeight: 80, // Tambah tinggi baris agar muat chips Google Calendar style
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() => _calendarFormat = format);
                }
              },
              onPageChanged: _onPageChanged,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  if (events.isEmpty) return const SizedBox();
                  return Positioned(
                    bottom: 2,
                    left: 2,
                    right: 2,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: events.take(2).map((event) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                          decoration: BoxDecoration(
                            color: kEventColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            (event as Map)['judul'] ?? 'Agenda',
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: kTextSec),
                weekendStyle: TextStyle(color: Colors.redAccent),
              ),
              headerStyle: HeaderStyle(
                titleTextStyle: const TextStyle(color: kGold, fontSize: 18),
                formatButtonTextStyle: const TextStyle(color: kBgDark, fontWeight: FontWeight.bold),
                formatButtonDecoration: BoxDecoration(
                  color: kGoldLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                leftChevronIcon: const Icon(Icons.chevron_left, color: kGold),
                rightChevronIcon: const Icon(Icons.chevron_right, color: kGold),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(color: kTextPri),
                weekendTextStyle: const TextStyle(color: Colors.redAccent),
                outsideTextStyle: const TextStyle(color: kTextSec),
                selectedDecoration: const BoxDecoration(
                  color: kGold,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(color: kBgDark, fontWeight: FontWeight.bold),
                todayDecoration: BoxDecoration(
                  color: kBgCard2,
                  shape: BoxShape.circle,
                  border: Border.all(color: kGold, width: 1),
                ),
                todayTextStyle: const TextStyle(color: kGoldLight, fontWeight: FontWeight.bold),
                // Nonaktifkan default marker decoration
                markerDecoration: const BoxDecoration(color: Colors.transparent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: kGold))
                : selectedEvents.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada agenda pada tanggal ini',
                          style: TextStyle(color: kTextSec.withOpacity(0.5)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: selectedEvents.length,
                        itemBuilder: (context, index) {
                          final event = selectedEvents[index];
                          final startTime = event['instanceDate'] != null 
                              ? DateFormat('HH:mm').format(DateTime.parse(event['instanceDate']).toLocal())
                              : '';
                          final endTime = event['instanceWaktuSelesai'] != null 
                              ? DateFormat('HH:mm').format(DateTime.parse(event['instanceWaktuSelesai']).toLocal())
                              : '';
                              
                          return Card(
                            color: kBgCard2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: kGold.withOpacity(0.2)),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: kGold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.event_note, color: kGold),
                              ),
                              title: Text(
                                event['judul'] ?? 'Agenda',
                                style: const TextStyle(color: kTextPri, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    event['deskripsi'] ?? 'Tanpa deskripsi',
                                    style: const TextStyle(color: kTextSec, fontSize: 13),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 14, color: kGoldLight),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$startTime - $endTime WIB',
                                        style: const TextStyle(color: kGoldLight, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
