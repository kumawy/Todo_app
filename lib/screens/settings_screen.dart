import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../focus_provider.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});
  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _focus;
  late final TextEditingController _rest;
  String? _error;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<FocusProvider>();
    _focus = TextEditingController(text: '${settings.focusMinutes}');
    _rest = TextEditingController(text: '${settings.breakMinutes}');
  }

  @override
  void dispose() {
    _focus.dispose();
    _rest.dispose();
    super.dispose();
  }

  void _changed() => setState(() {
    _error = null;
    _saved = false;
  });

  String? _validate(String? value) {
    final minutes = int.tryParse(value?.trim() ?? '');
    return minutes == null || minutes < 1 || minutes > 120
        ? 'Введите от 1 до 120 минут.'
        : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _error = null;
      _saved = false;
    });
    try {
      await context.read<FocusProvider>().saveSettings(
        int.parse(_focus.text.trim()),
        int.parse(_rest.text.trim()),
      );
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Не удалось сохранить настройки. Попробуйте ещё раз.',
        );
      }
    }
  }

  Widget _durationField(
    String label,
    TextEditingController controller,
    List<int> presets,
    bool saving,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextFormField(
        controller: controller,
        enabled: !saving,
        validator: _validate,
        keyboardType: TextInputType.number,
        onChanged: (_) => _changed(),
        decoration: InputDecoration(labelText: label, suffixText: 'мин'),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: presets
            .map(
              (minutes) => ChoiceChip(
                label: Text('$minutes мин'),
                selected: int.tryParse(controller.text.trim()) == minutes,
                showCheckmark: false,
                onSelected: saving
                    ? null
                    : (_) {
                        controller.text = '$minutes';
                        _changed();
                      },
              ),
            )
            .toList(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<FocusProvider>();
    final dirty =
        int.tryParse(_focus.text.trim()) != settings.focusMinutes ||
        int.tryParse(_rest.text.trim()) != settings.breakMinutes;
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Ваш ритм',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Выберите удобное время для работы и отдыха.',
                style: TextStyle(color: appMuted, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: appBorder),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Длительность сеансов',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _durationField('Фокус', _focus, [
                      25,
                      45,
                      60,
                    ], settings.saving),
                    const SizedBox(height: 24),
                    _durationField('Перерыв', _rest, [
                      5,
                      10,
                      15,
                    ], settings.saving),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Изменения применятся к следующему сеансу или после сброса таймера.',
                style: TextStyle(fontSize: 13, color: appMuted, height: 1.5),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: settings.saving || !dirty ? null : _save,
                child: Text(
                  settings.saving ? 'Сохранение…' : 'Сохранить настройки',
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: motionDuration(context),
                child: _error != null
                    ? Text(
                        _error!,
                        key: const ValueKey('save-error'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
                    : _saved
                    ? Semantics(
                        liveRegion: true,
                        child: const Text(
                          'Настройки сохранены',
                          key: ValueKey('saved'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF26846B)),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
