import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/markaz_theme.dart';

// Exact key order and variants from SIAKAD src/lib/exam-keyboard.ts.
const arabicRows = [
  ['ض', 'ص', 'ث', 'ق', 'ف', 'غ', 'ع', 'ه', 'خ', 'ح', 'ج'],
  ['ش', 'س', 'ي', 'ب', 'ل', 'ا', 'ت', 'ن', 'م', 'ك', 'ط'],
  ['ذ', 'ء', 'ؤ', 'ر', 'ى', 'ة', 'و', 'ز', 'ظ', 'د'],
];
const harakat = ['َ', 'ُ', 'ِ', 'ّ', 'ْ'];
const keyVariants = {
  'ا': ['ا', 'أ', 'إ', 'آ', 'ٱ'],
  'و': ['و', 'ؤ'],
  'ي': ['ي', 'ى', 'ئ'],
  'ء': ['ء', 'أ', 'إ', 'ؤ', 'ئ'],
  'ه': ['ه', 'ة'],
  'ة': ['ة', 'ه', 'ت'],
  'ل': ['ل', 'لا', 'لأ', 'لإ', 'لآ'],
  'لا': ['لا', 'لأ', 'لإ', 'لآ'],
  'َ': ['َ', 'ً', 'ٰ'],
  'ُ': ['ُ', 'ٌ'],
  'ِ': ['ِ', 'ٍ'],
  'ّ': ['ّ', 'َّ', 'ُّ', 'ِّ', 'ًّ', 'ٌّ', 'ٍّ'],
  'ْ': ['ْ', 'ّ'],
  '.': ['.', ',', '،', '؛', ':'],
  '؟': ['؟', '?', '!'],
};
String keyDisplay(String key) =>
    RegExp(r'^[\u064B-\u065F\u0670]').hasMatch(key) ? 'ـ$key' : key;
bool arabicText(String text) {
  final first = RegExp(r'[A-Za-z\u0621-\u064A]').firstMatch(text);
  return first == null || RegExp(r'[\u0621-\u064A]').hasMatch(first[0]!);
}

TextEditingValue insertExamText(TextEditingValue value, String inserted) {
  final selection = value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: value.text.length);
  final start = selection.start.clamp(0, value.text.length);
  final end = selection.end.clamp(start, value.text.length);
  return TextEditingValue(
      text: value.text.replaceRange(start, end, inserted),
      selection: TextSelection.collapsed(offset: start + inserted.length));
}

TextEditingValue deleteExamText(TextEditingValue value) {
  final s = value.selection.isValid
      ? value.selection
      : TextSelection.collapsed(offset: value.text.length);
  if (!s.isCollapsed) return insertExamText(value, '');
  if (s.start == 0) return value;
  // Match the web: remove a combining mark before removing its base letter.
  final width = value.text.substring(0, s.start).runes.last > 0xffff ? 2 : 1;
  return insertExamText(
      value.copyWith(
          selection: TextSelection(
              baseOffset: s.start - width, extentOffset: s.start)),
      '');
}

class ExamKeyboardController extends ChangeNotifier {
  TextEditingController? target;
  ValueChanged<String>? changed;
  bool multiline = true;
  void activate(
      TextEditingController controller, ValueChanged<String> onChanged,
      {bool multiple = true}) {
    target = controller;
    changed = onChanged;
    multiline = multiple;
    notifyListeners();
  }

  void close() {
    target = null;
    changed = null;
    notifyListeners();
  }

  void insert(String text) {
    if (target == null) return;
    target!.value = insertExamText(
        target!.value, multiline ? text : text.replaceAll('\n', ''));
    changed?.call(target!.text);
  }

  void delete() {
    if (target == null) return;
    target!.value = deleteExamText(target!.value);
    changed?.call(target!.text);
  }

  void move(bool forward) {
    final t = target;
    if (t == null) return;
    final s = t.selection.isValid
        ? t.selection
        : TextSelection.collapsed(offset: t.text.length);
    var pos = forward ? s.end : s.start;
    if (s.isCollapsed) {
      if (forward && pos < t.text.length)
        pos += t.text.substring(pos).runes.first > 0xffff ? 2 : 1;
      if (!forward && pos > 0)
        pos -= t.text.substring(0, pos).runes.last > 0xffff ? 2 : 1;
    }
    t.selection = TextSelection.collapsed(offset: pos);
  }
}

class ExamTextInput extends StatefulWidget {
  const ExamTextInput(
      {super.key,
      required this.value,
      required this.label,
      required this.keyboard,
      required this.onChanged,
      this.multiline = true});
  final String value, label;
  final bool multiline;
  final ExamKeyboardController keyboard;
  final ValueChanged<String> onChanged;
  @override
  State<ExamTextInput> createState() => _ExamInput();
}

class _ExamInput extends State<ExamTextInput> {
  late final TextEditingController controller =
      TextEditingController(text: widget.value);
  @override
  void didUpdateWidget(ExamTextInput old) {
    super.didUpdateWidget(old);
    if (controller.text != widget.value)
      controller.value = TextEditingValue(
          text: widget.value,
          selection: TextSelection.collapsed(offset: widget.value.length));
    if (widget.keyboard.target == controller)
      widget.keyboard.changed = widget.onChanged;
  }

  @override
  void dispose() {
    if (widget.keyboard.target == controller) {
      widget.keyboard.target = null;
      widget.keyboard.changed = null;
    }
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => TextField(
                controller: controller,
                readOnly: true,
                showCursor: true,
                keyboardType: TextInputType.none,
                autocorrect: false,
                enableSuggestions: false,
                enableIMEPersonalizedLearning: false,
                contextMenuBuilder: (_, __) => const SizedBox.shrink(),
                textDirection: arabicText(value.text)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                style: const TextStyle(
                    fontFamily: 'Amiri', fontSize: 21, height: 1.5),
                minLines: 1,
                maxLines: widget.multiline ? 5 : 1,
                decoration: InputDecoration(labelText: widget.label),
                onTap: () {
                  widget.keyboard.activate(controller, widget.onChanged,
                      multiple: widget.multiline);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted)
                      Scrollable.ensureVisible(context, alignment: .2);
                  });
                },
              ));
}

class ExamKeyboard extends StatefulWidget {
  const ExamKeyboard({super.key, required this.controller});
  final ExamKeyboardController controller;
  @override
  State<ExamKeyboard> createState() => _Keyboard();
}

class _Keyboard extends State<ExamKeyboard> {
  bool get landscape =>
      MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
  String mode = 'ar';
  bool upper = false;
  String? variant;
  Timer? hold;
  @override
  void dispose() {
    hold?.cancel();
    super.dispose();
  }

  Widget key(String text,
          {IconData? icon, VoidCallback? action, int flex = 1}) =>
      Expanded(
          flex: flex,
          child: Padding(
              padding: const EdgeInsets.all(2),
              child: Semantics(
                  button: true,
                  label: text,
                  child: Listener(
                      onPointerDown: (_) {
                        hold?.cancel();
                        if (keyVariants.containsKey(text))
                          hold = Timer(const Duration(milliseconds: 450), () {
                            if (mounted) setState(() => variant = text);
                          });
                      },
                      onPointerCancel: (_) {
                        hold?.cancel();
                      },
                      onPointerUp: (_) {
                        hold?.cancel();
                      },
                      child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {
                                if (variant == null)
                                  (action ??
                                      () => widget.controller.insert(text))();
                              },
                              child: SizedBox(
                                  height: landscape ? 28 : 40,
                                  child: Center(
                                      child: icon != null
                                          ? Transform.flip(
                                              flipX: text == 'Hapus' &&
                                                  mode == 'ar',
                                              child: Icon(icon, size: 20))
                                          : Text(keyDisplay(text),
                                              style: TextStyle(
                                                  fontSize: text == 'Spasi'
                                                      ? 15
                                                      : landscape
                                                          ? 18
                                                          : mode == 'ar'
                                                              ? 23
                                                              : 17,
                                                  height: 1.1,
                                                  fontFamily: mode == 'ar' &&
                                                          text != 'Spasi'
                                                      ? 'Amiri'
                                                      : 'Roboto'))))))))));
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (widget.controller.target == null) {
          variant = null;
          hold?.cancel();
          return const SizedBox.shrink();
        }
        final rows = mode == 'ar'
            ? arabicRows
            : mode == 'id'
                ? ['qwertyuiop', 'asdfghjkl', 'zxcvbnm']
                    .map((r) => (upper ? r.toUpperCase() : r).split(''))
                    .toList()
                : [
                    '1234567890'.split(''),
                    '١٢٣٤٥٦٧٨٩٠'.split(''),
                    ['؟', '!', '،', '.', '؛', ':', '-', '(', ')', '/']
                  ];
        return Material(
            color: MarkazColors.tint,
            child: SafeArea(
                top: false,
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height *
                            (landscape ? .60 : .48)),
                    child: SingleChildScrollView(
                        child: MediaQuery.withClampedTextScaling(
                            maxScaleFactor: 1.2,
                            child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(children: [
                                        for (final m in [
                                          ('ar', 'عربي'),
                                          ('id', 'ABC'),
                                          ('num', '123')
                                        ])
                                          Expanded(
                                              child: TextButton(
                                                  onPressed: () {
                                                    hold?.cancel();
                                                    setState(() {
                                                      mode = m.$1;
                                                      variant = null;
                                                    });
                                                  },
                                                  child: Text(m.$2,
                                                      style: TextStyle(
                                                          fontWeight: mode ==
                                                                  m.$1
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                          color: MarkazColors
                                                              .ink)))),
                                        IconButton(
                                            tooltip: 'Tutup keyboard',
                                            onPressed: widget.controller.close,
                                            icon: const Icon(
                                                Icons.keyboard_hide_outlined))
                                      ]),
                                      if (variant != null)
                                        Wrap(children: [
                                          for (final v in keyVariants[variant]!)
                                            TextButton(
                                                onPressed: () {
                                                  widget.controller.insert(v);
                                                  setState(
                                                      () => variant = null);
                                                },
                                                child: Text(keyDisplay(v),
                                                    style: const TextStyle(
                                                        fontFamily: 'Amiri',
                                                        fontSize: 24))),
                                          IconButton(
                                              onPressed: () => setState(
                                                  () => variant = null),
                                              icon: const Icon(Icons.close))
                                        ])
                                      else if (mode == 'ar')
                                        Row(children: [
                                          for (final h in harakat) key(h)
                                        ]),
                                      for (var i = 0; i < rows.length; i++)
                                        Directionality(
                                            textDirection: TextDirection.ltr,
                                            child: Row(children: [
                                              for (final letter in rows[i])
                                                key(letter),
                                              if (i == 2)
                                                key('Hapus',
                                                    icon: mode == 'ar'
                                                        ? Icons
                                                            .backspace_outlined
                                                        : Icons.backspace,
                                                    action: widget
                                                        .controller.delete),
                                            ])),
                                      Row(children: [
                                        if (mode == 'id')
                                          key('Shift',
                                              icon: Icons.keyboard_capslock,
                                              action: () => setState(
                                                  () => upper = !upper)),
                                        key('Kursor kiri',
                                            icon: Icons.chevron_left,
                                            action: () =>
                                                widget.controller.move(false)),
                                        key('Spasi',
                                            flex: 4,
                                            action: () =>
                                                widget.controller.insert(' ')),
                                        key('Kursor kanan',
                                            icon: Icons.chevron_right,
                                            action: () =>
                                                widget.controller.move(true)),
                                        key('Enter',
                                            icon: Icons.keyboard_return,
                                            action: () =>
                                                widget.controller.insert('\n'))
                                      ]),
                                    ])))))));
      });
}
