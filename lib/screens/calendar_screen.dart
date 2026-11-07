import '../widgets/markaz_components.dart';
import '../theme/markaz_theme.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

const kBgDark = MarkazColors.surface;
const kBgCard = MarkazColors.surface;
const kBgCard2 = MarkazColors.ivory;
const kGold = MarkazColors.gold;
const kGoldLight = MarkazColors.ink;
const kGoldDark = MarkazColors.warning;
const kGoldDim = MarkazColors.tint;
const kTextPri = MarkazColors.ink;
const kTextSec = MarkazColors.muted;
const kTeal = MarkazColors
    .ink; // Slightly pleasing color, or use MarkazColors.gold for teal
const kEventColor =
    MarkazColors.gold; // Matches the sample image green/teal chips

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
  bool _failed = false;
  int _request = 0;
  List<dynamic> _agendas = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchAgenda(_focusedDay.month, _focusedDay.year);
  }

  Future<void> _fetchAgenda(int month, int year) async {
    final request = ++_request;
    setState(() {
      _isLoading = true;
      _failed = false;
    });
    final response = await ApiService.getAgenda(month: month, year: year);
    if (!mounted || request != _request) return;
    if (response != null && response['success'] == true) {
      setState(() {
        _agendas = response['data'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
        _failed = true;
        _agendas = [];
      });
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

      return (targetDate.isAtSameMomentAs(startDate) ||
              targetDate.isAfter(startDate)) &&
          (targetDate.isAtSameMomentAs(endDate) ||
              targetDate.isBefore(endDate));
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
    final selectedEvents =
        _selectedDay != null ? _getEventsForDay(_selectedDay!) : [];

    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: const Text('Kalender Agenda',
            style: TextStyle(color: kGoldLight, fontWeight: FontWeight.bold)),
        backgroundColor: kBgCard,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: MarkazColors.ink),
      ),
      body: ListView(
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
              rowHeight: MediaQuery.textScalerOf(context).scale(48),
              daysOfWeekHeight: MediaQuery.textScalerOf(context).scale(24),
              locale: 'id_ID',
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() => _calendarFormat = format);
                }
              },
              onPageChanged: _onPageChanged,
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: kTextSec),
                weekendStyle: TextStyle(color: MarkazColors.danger),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle:
                    const TextStyle(color: MarkazColors.ink, fontSize: 18),
                formatButtonTextStyle: const TextStyle(
                    color: MarkazColors.ink, fontWeight: FontWeight.bold),
                formatButtonDecoration: BoxDecoration(
                  color: MarkazColors.gold,
                  borderRadius: BorderRadius.circular(12),
                ),
                leftChevronIcon:
                    const Icon(Icons.chevron_left, color: MarkazColors.ink),
                rightChevronIcon:
                    const Icon(Icons.chevron_right, color: MarkazColors.ink),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(color: kTextPri),
                weekendTextStyle: const TextStyle(color: MarkazColors.danger),
                outsideTextStyle: const TextStyle(color: kTextSec),
                selectedDecoration: const BoxDecoration(
                  color: kGold,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                    color: MarkazColors.ink, fontWeight: FontWeight.bold),
                todayDecoration: BoxDecoration(
                  color: kBgCard2,
                  shape: BoxShape.circle,
                  border: Border.all(color: MarkazColors.ink, width: 1),
                ),
                todayTextStyle: const TextStyle(
                    color: kGoldLight, fontWeight: FontWeight.bold),
                // Nonaktifkan default marker decoration
                markersMaxCount: 1,
                markerDecoration: const BoxDecoration(
                    color: MarkazColors.ink, shape: BoxShape.circle),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _failed
                    ? MarkazState(
                        title: 'Agenda belum dapat dimuat',
                        message: 'Periksa koneksi lalu coba lagi.',
                        pose: MascotPose.help,
                        onAction: () =>
                            _fetchAgenda(_focusedDay.month, _focusedDay.year))
                    : selectedEvents.isEmpty
                        ? const MarkazState(
                            title: 'Belum ada agenda',
                            message:
                                'Tidak ada kegiatan tercatat pada tanggal ini.')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: selectedEvents.length,
                            itemBuilder: (context, index) {
                              final event = selectedEvents[index];
                              final startTime = event['instanceDate'] != null
                                  ? DateFormat('HH:mm').format(
                                      DateTime.parse(event['instanceDate'])
                                          .toLocal())
                                  : '';
                              final endTime = event['instanceWaktuSelesai'] !=
                                      null
                                  ? DateFormat('HH:mm').format(DateTime.parse(
                                          event['instanceWaktuSelesai'])
                                      .toLocal())
                                  : '';

                              return Card(
                                color: kBgCard2,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: kGold.withValues(alpha: 0.2)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: kGold.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.event_note,
                                        color: MarkazColors.ink),
                                  ),
                                  title: Text(
                                    event['judul'] ?? 'Agenda',
                                    style: const TextStyle(
                                        color: kTextPri,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        event['deskripsi'] ?? 'Tanpa deskripsi',
                                        style: const TextStyle(
                                            color: kTextSec, fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time,
                                              size: 14, color: kGoldLight),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$startTime - $endTime WIB',
                                            style: const TextStyle(
                                                color: kGoldLight,
                                                fontSize: 12),
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
