part of '../exam.dart';

extension _QuestionControls on _Exam {
  Widget rich(dynamic v) {
    final text = v?.toString() ?? '';
    final rtl = arabicText(text.replaceAll(RegExp(r'<[^>]*>'), ''));
    return Directionality(
        textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
        child: Html(data: text, style: {
          'body': Style(
              color: MarkazColors.ink,
              fontFamily: rtl ? 'Amiri' : 'Roboto',
              fontSize: FontSize(rtl ? 21 : 16),
              margin: Margins.zero),
        }));
  }

  List<Widget> controls(Json q) {
    final a = obj(answers[id(q)]),
        dt = obj(q['dataTambahan'] is String
            ? jsonDecode(q['dataTambahan'])
            : q['dataTambahan']),
        j = obj(a['jawabanData']);
    final type = val(q['tipeSoal']);
    void save(Json v) => edit(q, {
          'jawabanData': {...j, ...v}
        });
    final opts = rows(q[widget.tauzi ? 'jawabanList' : 'opsiList']);
    Widget input(
            String label, String initial, void Function(String) fn) =>
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ExamTextInput(
                key: ValueKey('${id(q)}:$label'),
                value: initial,
                label: label,
                keyboard: keyboard,
                onChanged: fn));
    Widget pick(dynamic label, dynamic current, List opts,
            void Function(dynamic) fn) =>
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Card(
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          rich(label),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final option in opts.toSet())
                              ChoiceChip(
                                  label: Text(val(option), softWrap: true),
                                  selected: current == option,
                                  onSelected: (_) =>
                                      fn(current == option ? null : option)),
                          ]),
                        ]))));
    if (opts.isNotEmpty)
      return [
        Text(
            type == 'PG_MULTI'
                ? 'Pilih semua jawaban yang sesuai.'
                : type == 'BENAR_SALAH'
                    ? 'Tentukan benar atau salah.'
                    : 'Pilih satu jawaban.',
            style: const TextStyle(color: MarkazColors.muted)),
        for (final o in opts)
          Builder(builder: (context) {
            final selected = type == 'PG_MULTI'
                ? (j['selectedIds'] as List? ?? []).contains(o['id'])
                : a[widget.tauzi ? 'jawabanId' : 'opsiId'] == o['id'];
            return Card(
                color: selected ? MarkazColors.tint : Colors.white,
                child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      if (type == 'PG_MULTI') {
                        final ids = Set.of(j['selectedIds'] as List? ?? []);
                        selected ? ids.remove(o['id']) : ids.add(o['id']);
                        save({'selectedIds': ids.toList()});
                      } else
                        edit(q,
                            {widget.tauzi ? 'jawabanId' : 'opsiId': o['id']});
                    },
                    child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                  type == 'PG_MULTI'
                                      ? (selected
                                          ? Icons.check_box_outlined
                                          : Icons.check_box_outline_blank)
                                      : (selected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off),
                                  size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                    rich(o['teks']),
                                    if (o['gambarUrl'] != null)
                                      Image.network(
                                          widget.api.origin
                                              .resolve(o['gambarUrl'])
                                              .toString(),
                                          errorBuilder: (_, __, ___) =>
                                              const Text(
                                                  'Gambar belum termuat.')),
                                  ])),
                            ]))));
          }),
      ];
    if (type == 'MENJODOHKAN' || type == 'DRAG_KATEGORI') {
      final match = type == 'MENJODOHKAN',
          k = match ? 'pairs' : 'items',
          l = match ? 'left' : 'text',
          r = match ? 'right' : 'category';
      final entries = rows(j[k]);
      return [
        for (final item in (match
                ? dt['lefts']
                : rows(dt['items']).map((i) => i['text'])) ??
            [])
          pick(
              item,
              entries.where((e) => e[l] == item).firstOrNull?[r],
              List.of(dt[match ? 'rights' : 'categories'] ?? []),
              (v) => save({
                    k: [
                      ...entries.where((e) => e[l] != item),
                      {l: item, r: v}
                    ]
                  }))
      ];
    }
    if (type == 'SUSUN_HURUF') {
      final original = List.of(dt['hurufAcak'] ?? []);
      final selected = List<int>.from(j['susunanIndices'] ?? [])
          .where((i) => i >= 0 && i < original.length)
          .toList();
      return [
        const Text('اضغط الحروف لترتيبها، واضغط الحرف المختار لإعادته.',
            textDirection: TextDirection.rtl),
        const SizedBox(height: 12),
        Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < selected.length; i++)
                InputChip(
                    label: Text(val(original[selected[i]]),
                        style:
                            const TextStyle(fontFamily: 'Amiri', fontSize: 24)),
                    onDeleted: () {
                      final next = [...selected]..removeAt(i);
                      save({'susunanIndices': next});
                    }),
            ])),
        const Divider(),
        Directionality(
            textDirection: TextDirection.rtl,
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < original.length; i++)
                ActionChip(
                    label: Text(val(original[i]),
                        style:
                            const TextStyle(fontFamily: 'Amiri', fontSize: 24)),
                    onPressed: selected.contains(i)
                        ? null
                        : () => save({
                              'susunanIndices': [...selected, i]
                            })),
            ])),
        TextButton(
            onPressed: () => save({'susunanIndices': []}),
            child: const Text('Susun ulang'))
      ];
    }
    if (type == 'MENGURUTKAN') {
      final original = List.of(dt['items'] ?? []);
      final order = List.of(j['items'] ?? original);
      return [
        const Text(
            'Geser pegangan untuk mengurutkan, atau gunakan tombol naik/turun.'),
        ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: order.length,
            onReorder: (from, to) {
              if (to > from) to--;
              final next = [...order];
              next.insert(to, next.removeAt(from));
              save({'items': next});
            },
            itemBuilder: (context, i) => Card(
                key: ValueKey('${id(q)}:order:$i'),
                child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          rich(order[i]),
                          Row(children: [
                            Text('${i + 1}'),
                            const Spacer(),
                            for (final delta in [-1, 1])
                              IconButton(
                                  tooltip: delta < 0 ? 'Naik' : 'Turun',
                                  onPressed:
                                      i + delta < 0 || i + delta >= order.length
                                          ? null
                                          : () {
                                              final next = [...order];
                                              next.insert(
                                                  i + delta, next.removeAt(i));
                                              save({'items': next});
                                            },
                                  icon: Icon(delta < 0
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward)),
                            ReorderableDragStartListener(
                                index: i,
                                child: const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Icon(Icons.drag_handle)))
                          ])
                        ])))),
        TextButton(
            onPressed: () => save({'items': order}),
            child: const Text('Simpan urutan'))
      ];
    }
    if (type == 'DRAG_TO_BLANK' || type == 'PARAGRAF_RUMPANG') {
      final values = obj(j['answers']);
      final paragraph = val(dt['paragraf']).replaceAll(RegExp(r'<[^>]*>'), '');
      final tokens = RegExp(r'\{\{(\d+)\}\}').allMatches(paragraph).toList();
      final indices = tokens.isNotEmpty
          ? tokens.map((m) => m[1]!).toList()
          : rows(dt['blanks']).map((b) => '${b['index']}').toList();
      final bank = List<String>.from(dt['wordBank'] ?? []);
      bool available(String word) =>
          values.values.where((v) => v == word).length <
          bank.where((w) => w == word).length;
      Widget hole(String index) => type == 'PARAGRAF_RUMPANG'
          ? SizedBox(
              width: 150,
              child: input(
                  'Isian $index',
                  values[index]?.toString() ?? '',
                  (v) => save({
                        'answers': {...values, index: v}
                      })))
          : DragTarget<String>(
              onWillAcceptWithDetails: (d) => available(d.data),
              onAcceptWithDetails: (d) => save({
                    'answers': {...values, index: d.data}
                  }),
              builder: (context, candidate, rejected) => OutlinedButton(
                  onPressed: () {
                    final next = {...values}..remove(index);
                    save({'answers': next});
                  },
                  style: OutlinedButton.styleFrom(
                      backgroundColor: candidate.isNotEmpty
                          ? MarkazColors.gold
                          : MarkazColors.tint),
                  child: Text(values[index]?.toString() ?? 'Isian $index')));
      final spans = <InlineSpan>[];
      var cursor = 0;
      for (final token in tokens) {
        spans.add(TextSpan(text: paragraph.substring(cursor, token.start)));
        spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
                padding: const EdgeInsets.all(4), child: hole(token[1]!))));
        cursor = token.end;
      }
      spans.add(TextSpan(text: paragraph.substring(cursor)));
      return [
        if (type == 'DRAG_TO_BLANK')
          const Text(
              'Ketuk kata untuk mengisi bagian kosong berikutnya, atau geser ke isian. Ketuk isian untuk mengosongkannya.'),
        const SizedBox(height: 12),
        Text.rich(TextSpan(children: spans),
            textDirection:
                arabicText(paragraph) ? TextDirection.rtl : TextDirection.ltr,
            style: const TextStyle(
                fontFamily: 'Amiri', fontSize: 22, height: 1.8)),
        if (tokens.isEmpty)
          for (final index in indices) hole(index),
        if (type == 'DRAG_TO_BLANK')
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final word in bank)
              Draggable<String>(
                  data: word,
                  maxSimultaneousDrags: available(word) ? 1 : 0,
                  feedback: Material(
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(word,
                              style: const TextStyle(fontSize: 22)))),
                  child: ActionChip(
                      label: Text(word),
                      onPressed: !available(word)
                          ? null
                          : () {
                              final blank = indices
                                  .where((i) =>
                                      values[i] == null || values[i] == '')
                                  .firstOrNull;
                              if (blank != null)
                                save({
                                  'answers': {...values, blank: word}
                                });
                            })),
          ]),
      ];
    }
    if (type == 'TABEL_TASRIF') {
      final cells = obj(j['cells']);
      final headers = List.of(dt['headers'] ?? []);
      return [
        const Text(
            'Isi sel yang kosong. Geser tabel untuk melihat kolom lainnya.',
            style: TextStyle(color: MarkazColors.muted)),
        const SizedBox(height: 12),
        SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Directionality(
                textDirection: TextDirection.rtl,
                child: Table(
                  defaultColumnWidth: const FixedColumnWidth(150),
                  columnWidths: const {0: FixedColumnWidth(80)},
                  border: TableBorder.all(color: MarkazColors.line),
                  children: [
                    TableRow(
                        decoration:
                            const BoxDecoration(color: MarkazColors.tint),
                        children: [
                          const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('الصيغة')),
                          for (final h in headers)
                            Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(val(h))),
                        ]),
                    for (final (i, r) in rows(dt['rows']).indexed)
                      TableRow(children: [
                        Padding(
                            padding: const EdgeInsets.all(12),
                            child: rich(r['label'])),
                        for (var k = 0; k < headers.length; k++)
                          Padding(
                              padding: const EdgeInsets.all(8),
                              child: Builder(builder: (_) {
                                final c =
                                    rows(r['cells']).elementAtOrNull(k) ?? {};
                                return c['isBlank'] == true
                                    ? input(
                                        '${val(r['label'])} · ${headers[k]}',
                                        val(cells['$i-$k']) == '—'
                                            ? ''
                                            : val(cells['$i-$k']),
                                        (v) => save({
                                              'cells': {...cells, '$i-$k': v}
                                            }))
                                    : rich(val(c['value']).split('|').first);
                              })),
                      ])
                  ],
                )))
      ];
    }
    if (type == 'IDENTIFIKASI_KESALAHAN') {
      final words = (dt['words'] as List?) ??
          rows(dt['segments']).map((s) => s['text']).toList();
      final multi = dt['words'] == null;
      final indices = List.of(j['selectedIndices'] ?? []);
      return [
        for (final (i, w) in words.indexed)
          CheckboxListTile(
              title: Text(val(w)),
              value: multi ? indices.contains(i) : j['selectedIndex'] == i,
              onChanged: (v) {
                if (multi) {
                  v == true ? indices.add(i) : indices.remove(i);
                  save({'selectedIndices': indices});
                } else {
                  save({'selectedIndex': i});
                }
              })
      ];
    }
    if (type == 'STABILO_SYNTAX') {
      final assigns = obj(j['assignments']);
      return [
        for (final (i, w) in List.of(dt['words'] ?? []).indexed)
          pick(
              '${w is Map ? w['text'] : w} (${i + 1})',
              assigns['$i'],
              [
                for (final cat in dt['categories'] ?? [])
                  cat is Map ? cat['name'] : cat
              ],
              (v) => save({
                    'assignments': {...assigns, '$i': v}
                  }))
      ];
    }
    if (type == 'JARING_RELASI') {
      final conn = rows(j['connections']);
      return [
        for (final (i, w) in List.of(dt['leftItems'] ?? []).indexed)
          ExpansionTile(title: Text(val(w)), children: [
            for (final (k, v) in List.of(dt['rightItems'] ?? []).indexed)
              Builder(builder: (_) {
                final sel = List.of(
                    conn.where((c) => c['left'] == i).firstOrNull?['right'] ??
                        []);
                return CheckboxListTile(
                    title: Text(val(v)),
                    value: sel.contains(k),
                    onChanged: (b) {
                      b == true ? sel.add(k) : sel.remove(k);
                      save({
                        'connections': [
                          ...conn.where((c) => c['left'] != i),
                          {'left': i, 'right': sel}
                        ]
                      });
                    });
              })
          ])
      ];
    }
    if (!widget.tauzi &&
        !{
          'ESSAY',
          'ESSAY_SINGKAT',
          'ESSAY_ARAB',
          'ESSAY_PANJANG',
          'ESSAY_GAMBAR',
          'ISIAN_SAMPING',
          'ISIAN_BAWAH',
          'KITABAH'
        }.contains(type))
      return [
        Text(
            'Jenis soal $type belum didukung. Hubungi pengawas; jangan kirim jawaban pengganti.')
      ];
    return [
      if (dt['huruf'] is List) rich((dt['huruf'] as List).join(' · ')),
      input('Jawaban Anda', a['jawabanTeks'] ?? '',
          (v) => edit(q, {'jawabanTeks': v}))
    ];
  }
}
