import 'package:flutter/material.dart';
import '../theme/markaz_theme.dart';

enum MascotPose { welcome, unavailable, empty, help, success }

class MarkazMascot extends StatelessWidget {
  const MarkazMascot(
      {super.key, this.pose = MascotPose.welcome, this.size = 144});
  final MascotPose pose;
  final double size;
  @override
  Widget build(BuildContext context) {
    if (pose != MascotPose.welcome) {
      return ExcludeSemantics(
          child: Image.asset('assets/mascot/${pose.name}.webp',
              width: size,
              height: size,
              cacheWidth: (size * 2).round(),
              fit: BoxFit.contain));
    }
    // Original transparent sheet: clip the first pose without mirroring its Arabic text.
    return ExcludeSemantics(
        child: SizedBox(
            width: size * .81,
            height: size,
            child: ClipPath(
                clipper: _WelcomeClip(),
                child: OverflowBox(
                    alignment: Alignment.topLeft,
                    maxWidth: size * 2.09,
                    maxHeight: size * 2.09,
                    child: Image.asset('assets/mascot/poses.webp',
                        width: size * 2.09,
                        height: size * 2.09,
                        cacheWidth: (size * 4.18).round(),
                        fit: BoxFit.fill)))));
  }
}

class _WelcomeClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 0)
    ..lineTo(size.width * .90, 0)
    ..lineTo(size.width * .90, size.height * .59)
    ..lineTo(size.width * .98, size.height * .61)
    ..lineTo(size.width * .98, size.height * .83)
    ..lineTo(size.width * .84, size.height * .83)
    ..lineTo(size.width * .84, size.height)
    ..lineTo(0, size.height)
    ..close();
  @override
  bool shouldReclip(_WelcomeClip oldClipper) => false;
}

class WelcomePanel extends StatelessWidget {
  const WelcomePanel({super.key, this.name});
  final String? name;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Assalamu’alaikum${name == null ? '' : ','}',
                  style:
                      const TextStyle(fontSize: 13, color: MarkazColors.muted)),
              const SizedBox(height: 10),
              Text(name ?? 'Selamat datang di portal Markaz Arabiyah Tech',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontSize: 24, height: 1.12)),
              const SizedBox(height: 12),
              Text(
                  name == null
                      ? 'Semua layanan dalam genggaman Anda.'
                      : 'Ruang belajar dan layanan santri Anda.',
                  style: const TextStyle(
                      fontSize: 13, color: MarkazColors.muted, height: 1.4))
            ]);
        return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ColoredBox(
                color: MarkazColors.ivory,
                child: Stack(children: [
                  Positioned(
                      right: -55,
                      bottom: -70,
                      child: Container(
                          width: 210,
                          height: 255,
                          decoration: const BoxDecoration(
                              color: MarkazColors.gold,
                              borderRadius: BorderRadius.all(
                                  Radius.elliptical(120, 160))))),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 8, 16),
                      child: largeText
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                  copy,
                                  const Align(
                                      alignment: Alignment.centerRight,
                                      child: MarkazMascot(size: 160))
                                ])
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                  Expanded(child: copy),
                                  MarkazMascot(
                                      size: box.maxWidth < 340 ? 145 : 170)
                                ]))
                ])));
      });
}

class MarkazState extends StatelessWidget {
  const MarkazState(
      {super.key,
      required this.title,
      required this.message,
      this.pose = MascotPose.empty,
      this.actionLabel,
      this.onAction});
  final String title, message;
  final MascotPose pose;
  final String? actionLabel;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        MarkazMascot(pose: pose, size: 132),
        const SizedBox(height: 12),
        Text(title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: MarkazColors.muted)),
        if (onAction != null) ...[
          const SizedBox(height: 16),
          FilledButton(
              onPressed: onAction, child: Text(actionLabel ?? 'Coba lagi'))
        ]
      ]));
}

class FeatureCard extends StatefulWidget {
  const FeatureCard(
      {super.key,
      required this.label,
      required this.icon,
      required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => AnimatedScale(
      scale: pressed ? .97 : 1,
      duration: Duration(
          milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 100),
      child: Tooltip(
          message: widget.label,
          child: Material(
              color: MarkazColors.ivory,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: MarkazColors.line)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                  onTap: widget.onTap,
                  onHighlightChanged: (v) => setState(() => pressed = v),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 16),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                                color: MarkazColors.gold,
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(widget.icon,
                                size: 28, color: MarkazColors.ink)),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                            constraints: BoxConstraints(
                                minHeight:
                                    MediaQuery.textScalerOf(context).scale(30)),
                            child: Text(widget.label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.25,
                                    fontWeight: FontWeight.w500,
                                    color: MarkazColors.ink)))
                      ]))))));
}

class FeatureGrid extends StatelessWidget {
  const FeatureGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (c, box) {
        final scale = MediaQuery.textScalerOf(c).scale(12) / 12;
        final n = (box.maxWidth / (72 * scale)).floor().clamp(1, 4);
        final width = (box.maxWidth - (n - 1) * 10) / n;
        return Wrap(spacing: 10, runSpacing: 10, children: [
          for (final child in children) SizedBox(width: width, child: child)
        ]);
      });
}

class MarkazNavigation extends StatelessWidget {
  const MarkazNavigation(
      {super.key,
      required this.index,
      required this.onSelect,
      required this.items});
  final int index;
  final ValueChanged<int> onSelect;
  final List<(IconData, String)> items;
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: MarkazColors.line))),
      child: SafeArea(
          top: false,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                  child: Semantics(
                      selected: i == index,
                      button: true,
                      child: InkWell(
                          onTap: () => onSelect(i),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 2),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                        duration: Duration(
                                            milliseconds:
                                                MediaQuery.disableAnimationsOf(
                                                        context)
                                                    ? 0
                                                    : 100),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 5),
                                        decoration: BoxDecoration(
                                            color: i == index
                                                ? MarkazColors.gold
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: Icon(items[i].$1,
                                            color: i == index
                                                ? MarkazColors.ink
                                                : MarkazColors.muted,
                                            size: 23)),
                                    const SizedBox(height: 4),
                                    Text(items[i].$2,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 12,
                                            height: 1.2,
                                            fontWeight: i == index
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                            color: i == index
                                                ? MarkazColors.ink
                                                : MarkazColors.muted))
                                  ])))))
          ])));
}

/// A compact identity for dialogs; body and actions remain native Material.
class MarkazDialogTitle extends StatelessWidget {
  const MarkazDialogTitle(this.title,
      {super.key, this.icon = Icons.assignment_turned_in_outlined});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: MarkazColors.gold,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 22, color: MarkazColors.ink)),
            const SizedBox(height: 12),
            Text(title),
          ]);
}
