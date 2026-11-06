import 'package:flutter/material.dart';

typedef PrayerInfo = ({
  String clock,
  String location,
  String prayer,
  String time,
  String countdown,
  VoidCallback? schedule
});
final prayerInfo = ValueNotifier<PrayerInfo>((
  clock: '--:--',
  location: 'Mencari lokasi…',
  prayer: 'Memuat',
  time: '',
  countdown: '',
  schedule: null
));

class PrayerPanel extends StatelessWidget {
  const PrayerPanel({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<PrayerInfo>(
      valueListenable: prayerInfo,
      builder: (c, p, _) {
        final theme = Theme.of(c);
        final clock =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p.location, style: theme.textTheme.bodySmall),
          Text(p.clock,
              style: theme.textTheme.headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w600))
        ]);
        final prayer =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Salat berikutnya', style: theme.textTheme.bodySmall),
          Text('${p.prayer} ${p.time}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.primary)),
          if (p.time != '--:--' && p.countdown.isNotEmpty)
            Text(p.countdown, style: theme.textTheme.bodySmall)
        ]);
        return Material(
            color: const Color(0xff22221d),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: p.schedule,
                child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: LayoutBuilder(
                        builder: (c, b) => b.maxWidth /
                                    MediaQuery.textScalerOf(c).scale(1) <
                                240
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [clock, const Divider(), prayer])
                            : Row(children: [
                                Expanded(child: clock),
                                const SizedBox(width: 8),
                                Expanded(child: prayer),
                                const Icon(Icons.chevron_right, size: 18)
                              ])))));
      });
}
