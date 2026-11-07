import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/markaz_theme.dart';

class PrayerScheduleSheet extends StatefulWidget {
  const PrayerScheduleSheet(
      {super.key,
      required this.latitude,
      required this.longitude,
      required this.location,
      this.now});
  final double latitude, longitude;
  final String location;
  final DateTime Function()? now;

  @override
  State<PrayerScheduleSheet> createState() => _PrayerScheduleSheetState();
}

class _PrayerScheduleSheetState extends State<PrayerScheduleSheet> {
  DateTime get now => widget.now?.call() ?? DateTime.now();
  late DateTime selected;
  Timer? ticker;
  bool followToday = true;
  @override
  void initState() {
    super.initState();
    selected = DateUtils.dateOnly(now);
    ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted)
        setState(() {
          if (followToday) selected = DateUtils.dateOnly(now);
        });
    });
  }

  @override
  void dispose() {
    ticker?.cancel();
    super.dispose();
  }

  PrayerTimes times(DateTime date) => PrayerTimes(
      Coordinates(widget.latitude, widget.longitude),
      DateComponents(date.year, date.month, date.day),
      CalculationMethod.singapore.getParameters()..madhab = Madhab.shafi);

  List<(String, DateTime, IconData)> prayers(PrayerTimes p) => [
        ('Subuh', p.fajr, Icons.wb_twilight_rounded),
        ('Zuhur', p.dhuhr, Icons.light_mode_rounded),
        ('Ashar', p.asr, Icons.wb_sunny_outlined),
        ('Maghrib', p.maghrib, Icons.wb_twilight_rounded),
        ('Isya', p.isha, Icons.nights_stay_rounded),
      ];

  void changeDate(DateTime value) => setState(() {
        selected = DateUtils.dateOnly(value);
        followToday = DateUtils.isSameDay(selected, now);
      });

  Future<void> pickDate() async {
    final value = await showDatePicker(
        context: context,
        initialDate: selected,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 2, 12, 31),
        helpText: 'Pilih tanggal jadwal salat');
    if (value != null && mounted) changeDate(value);
  }

  @override
  Widget build(BuildContext context) {
    final current = now;
    final isToday = DateUtils.isSameDay(current, selected);
    final p = times(selected);
    final entries = prayers(p);
    final upcoming = isToday
        ? entries.where((e) => e.$2.isAfter(current)).firstOrNull
        : null;
    final next = upcoming ??
        (isToday
            ? prayers(times(
                    DateTime(current.year, current.month, current.day + 1)))
                .first
            : null);
    final minutes = next == null ? 0 : next.$2.difference(current).inMinutes;
    final countdown = minutes < 1
        ? 'Kurang dari 1 menit lagi'
        : minutes < 60
            ? '$minutes menit lagi'
            : '${minutes ~/ 60} jam ${minutes % 60} menit lagi';
    return SafeArea(
        top: false,
        child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Row(children: [
                const _PrayerBadge(icon: Icons.schedule_rounded),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('Jadwal Salat',
                        style: Theme.of(context).textTheme.headlineSmall)),
                IconButton(
                    tooltip: 'Tutup jadwal',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded)),
              ]),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.location_on_outlined,
                    size: 18, color: MarkazColors.muted),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(widget.location,
                        style: Theme.of(context).textTheme.bodySmall)),
              ]),
              const SizedBox(height: 20),
              if (next != null)
                Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: MarkazColors.tint,
                        borderRadius: BorderRadius.circular(16),
                        border: const Border(
                            left: BorderSide(
                                color: MarkazColors.gold, width: 4))),
                    child: LayoutBuilder(builder: (c, box) {
                      final copy = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SALAT BERIKUTNYA',
                                style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 1,
                                    color: MarkazColors.muted)),
                            const SizedBox(height: 6),
                            Text(
                                '${next.$1}${upcoming == null ? ' · besok' : ''}',
                                style: Theme.of(c).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text(countdown,
                                style: Theme.of(c).textTheme.bodySmall),
                          ]);
                      final clock = Text(DateFormat('HH:mm').format(next.$2),
                          style: Theme.of(c).textTheme.headlineLarge);
                      return box.maxWidth /
                                  MediaQuery.textScalerOf(c).scale(1) <
                              240
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  copy,
                                  const SizedBox(height: 8),
                                  clock
                                ])
                          : Row(children: [
                              Expanded(child: copy),
                              const SizedBox(width: 12),
                              clock
                            ]);
                    })),
              const SizedBox(height: 16),
              DecoratedBox(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: MarkazColors.line)),
                  child: Row(children: [
                    IconButton(
                        tooltip: 'Hari sebelumnya',
                        onPressed: selected.isAfter(DateTime(current.year - 1))
                            ? () => changeDate(DateTime(selected.year,
                                selected.month, selected.day - 1))
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded)),
                    Expanded(
                        child: TextButton(
                            onPressed: pickDate,
                            child: Column(children: [
                              Text(DateFormat('EEEE', 'id_ID').format(selected),
                                  style: const TextStyle(
                                      fontSize: 12, color: MarkazColors.muted)),
                              const SizedBox(height: 2),
                              Text(
                                  DateFormat('d MMM yyyy', 'id_ID')
                                      .format(selected),
                                  textAlign: TextAlign.center),
                            ]))),
                    IconButton(
                        tooltip: 'Hari berikutnya',
                        onPressed: selected
                                .isBefore(DateTime(current.year + 2, 12, 31))
                            ? () => changeDate(DateTime(selected.year,
                                selected.month, selected.day + 1))
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded)),
                  ])),
              Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                      onPressed: isToday ? null : () => changeDate(current),
                      icon: const Icon(Icons.today_outlined, size: 18),
                      label:
                          Text(isToday ? 'Hari ini' : 'Kembali ke hari ini'))),
              for (final entry in entries)
                _timeRow(context, entry.$1, entry.$2, entry.$3,
                    active: upcoming?.$1 == entry.$1),
              const SizedBox(height: 8),
              ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: const Text('Waktu pendukung',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Imsak, terbit & dhuha',
                      style: TextStyle(fontSize: 12)),
                  children: [
                    _timeRow(
                        context,
                        'Imsak',
                        p.fajr.subtract(const Duration(minutes: 10)),
                        Icons.brightness_2_outlined),
                    _timeRow(
                        context, 'Terbit', p.sunrise, Icons.wb_sunny_outlined),
                    _timeRow(
                        context,
                        'Dhuha',
                        p.sunrise.add(const Duration(minutes: 20)),
                        Icons.light_mode_outlined),
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                            'Imsak: 10 menit sebelum Subuh. Dhuha: perkiraan 20 menit setelah terbit.',
                            style: TextStyle(
                                fontSize: 12, color: MarkazColors.muted))),
                  ]),
              const SizedBox(height: 12),
              const Text('Waktu mengikuti zona waktu perangkat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: MarkazColors.muted)),
            ]));
  }

  Widget _timeRow(
          BuildContext context, String label, DateTime time, IconData icon,
          {bool active = false}) =>
      Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
              color: active ? MarkazColors.gold : MarkazColors.ivory,
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(icon, size: 22),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                  if (active)
                    const Text('Berikutnya', style: TextStyle(fontSize: 11)),
                ])),
            const SizedBox(width: 8),
            Text(DateFormat('HH:mm').format(time),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ]));
}

class _PrayerBadge extends StatelessWidget {
  const _PrayerBadge({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
          color: MarkazColors.gold, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: MarkazColors.ink));
}
