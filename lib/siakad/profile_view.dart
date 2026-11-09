part of 'features.dart';

extension _ProfileView on _Page {
  String profileValue(dynamic value) =>
      value == null || val(value).trim().isEmpty || val(value) == '—'
          ? 'Belum diisi'
          : val(value);

  Widget profileHeader() {
    final identity =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(profileValue(user['nama']),
          style: const TextStyle(
              fontSize: 22, height: 1.25, fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text('NIS ${profileValue(user['id'])}',
          style: const TextStyle(color: MarkazColors.muted)),
      const SizedBox(height: 10),
      badge(user['isAktif'] == true
          ? 'Aktif'
          : user['isAktif'] == false
              ? 'Tidak aktif'
              : 'Status belum tersedia'),
    ]);
    final photo = ExcludeSemantics(
        child: Container(
            key: const ValueKey('profile-photo-placeholder'),
            width: 88,
            height: 88,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MarkazColors.ivory,
                border: Border.all(color: MarkazColors.line))));
    return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 24),
        child: LayoutBuilder(builder: (context, box) {
          if (box.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(14) > 20) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [photo, const SizedBox(height: 16), identity]);
          }
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            photo,
            const SizedBox(width: 18),
            Expanded(child: identity)
          ]);
        }));
  }

  Widget profileGroup(
          String title, IconData icon, List<(String, dynamic)> values,
          {Widget? footer}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(icon, size: 20, color: MarkazColors.muted),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)))
            ]),
            const SizedBox(height: 10),
            Container(
                decoration: BoxDecoration(
                    color: MarkazColors.surface,
                    border: Border.all(color: MarkazColors.line),
                    borderRadius: BorderRadius.circular(14)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < values.length; i++) ...[
                        if (i > 0)
                          const Divider(height: 1, color: MarkazColors.line),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(values[i].$1,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: MarkazColors.muted)),
                                  const SizedBox(height: 4),
                                  Text(profileValue(values[i].$2),
                                      style: const TextStyle(
                                          fontSize: 15,
                                          height: 1.4,
                                          fontWeight: FontWeight.w500)),
                                ])),
                      ],
                      if (footer != null) ...[
                        const Divider(height: 1, color: MarkazColors.line),
                        footer,
                      ],
                    ])),
          ]));

  Widget profileAction(String title, IconData icon, Future<void> Function() fn,
          {bool danger = false}) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Icon(icon,
                  color: danger ? MarkazColors.danger : MarkazColors.ink),
              title: Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: danger ? MarkazColors.danger : MarkazColors.ink)),
              trailing:
                  danger ? null : const Icon(Icons.chevron_right, size: 20),
              enabled: !working,
              onTap: () => run(fn)));

  Future<void> editStudyMonth() async {
    final form = GlobalKey<FormState>();
    var value = user['bulanKe']?.toString() ?? '';
    var saving = false;
    String? failure;
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, update) => PopScope(
                canPop: !saving,
                child: AlertDialog(
                    scrollable: true,
                    title: const MarkazDialogTitle('Ubah bulan belajar',
                        icon: Icons.school_outlined),
                    content: Form(
                        key: form,
                        child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                  initialValue: value,
                                  enabled: !saving,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: 'Bulan ke-'),
                                  onChanged: (text) => value = text,
                                  validator: (text) =>
                                      (int.tryParse(text?.trim() ?? '') ?? 0) <
                                              1
                                          ? 'Masukkan angka bulan mulai dari 1.'
                                          : null),
                              if (failure != null)
                                Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: Text(failure!,
                                        style: const TextStyle(
                                            color: MarkazColors.danger))),
                            ])),
                    actions: [
                      TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.pop(dialogContext),
                          child: const Text('Batal')),
                      FilledButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!form.currentState!.validate()) return;
                                  update(() {
                                    saving = true;
                                    failure = null;
                                  });
                                  try {
                                    await get('me/update-bulan', body: {
                                      'bulanKe': int.parse(value.trim())
                                    });
                                  } catch (e) {
                                    if (context.mounted)
                                      update(() {
                                        saving = false;
                                        failure = e.toString();
                                      });
                                    return;
                                  }
                                  if (!mounted) return;
                                  // Keep the confirmed value visible even if refreshing the parent fails.
                                  updateView(() => profile = {
                                        ...profile,
                                        'santri': {
                                          ...user,
                                          'bulanKe': int.parse(value.trim())
                                        }
                                      });
                                  if (dialogContext.mounted)
                                    Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(this.context)
                                      .showSnackBar(const SnackBar(
                                          content: Text(
                                              'Bulan belajar tersimpan.')));
                                  try {
                                    await widget.onChanged();
                                  } catch (_) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(this.context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Perubahan tersimpan. Muat ulang untuk memperbarui data akun.')));
                                    }
                                  }
                                },
                          child: Text(saving ? 'Menyimpan…' : 'Simpan')),
                    ]))));
  }

  List<Widget> profileContent() => [
        profileHeader(),
        profileGroup('Data pribadi', Icons.badge_outlined, [
          ('Tempat lahir', user['tempatLahir']),
          ('Tanggal lahir', date(user['tanggalLahir'])),
          ('Alamat', user['alamat']),
        ]),
        profileGroup('Tempat tinggal', Icons.home_outlined, [
          ('Sakan', user['sakan']),
          ('Kamar', user['kamar']),
          ('Nomor lemari', user['nomorLemari']),
        ]),
        profileGroup(
            'Masa belajar',
            Icons.school_outlined,
            [
              ('Bulan ke-', user['bulanKe']),
              (
                'Masa aktif',
                adjustDufahName(val(obj(
                    obj(data['data'])['masaAktif'])['berakhirPadaDufahNama']))
              ),
            ],
            footer: profileAction(
                'Ubah bulan belajar', Icons.edit_outlined, editStudyMonth)),
        profileAction('Kartu santri', Icons.credit_card_outlined, () async {
          // The PPDB file provider must never receive the SIAKAD session cookie.
          final r = await http
              .get(Uri.https('ppdb.markazarabiyah.site',
                  '/api/digital-card/siakad/${user['id']}', {'download': '1'}))
              .timeout(const Duration(seconds: 25));
          if (r.statusCode != 200)
            throw const PortalError('Kartu santri belum tersedia.');
          final b = r.bodyBytes;
          final mime = b.length > 4 &&
                  b[0] == 0x25 &&
                  b[1] == 0x50 &&
                  b[2] == 0x44 &&
                  b[3] == 0x46
              ? 'application/pdf'
              : b.length > 4 && b[0] == 0x89 && b[1] == 0x50
                  ? 'image/png'
                  : b.length > 3 && b[0] == 0xff && b[1] == 0xd8
                      ? 'image/jpeg'
                      : null;
          if (mime == null)
            throw const PortalError('Format kartu santri tidak didukung.');
          if (mounted)
            await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => SantriFileView(
                        title: 'Kartu santri',
                        bytes: b,
                        type: mime,
                        filename:
                            'kartu-santri.${mime == 'image/jpeg' ? 'jpg' : mime.split('/').last}')));
        }),
        const Divider(color: MarkazColors.line),
        profileAction('Keluar akun', Icons.logout, () async {
          if (await confirm(
              'Keluar akun?', 'Sesi SIAKAD di perangkat ini akan dihapus.')) {
            await widget.onLogout?.call();
          }
        }, danger: true),
      ];
}
