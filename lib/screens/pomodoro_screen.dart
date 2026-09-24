import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'package:provider/provider.dart';
import '../focus_provider.dart';

class Pomodoro extends StatefulWidget {
  const Pomodoro({super.key});
  @override
  State<Pomodoro> createState() => _PomodoroState();
}

class _PomodoroState extends State<Pomodoro> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<FocusProvider>().refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<FocusProvider>();
    final seconds = timer.remainingSeconds;
    final time =
        '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
    final finished = seconds == 0;
    final status = finished
        ? 'Сеанс завершён'
        : timer.isRunning
        ? 'Идёт отсчёт'
        : timer.hasStarted
        ? 'На паузе'
        : 'Можно начинать';
    void startNext() {
      timer.reset(breakMode: !timer.isBreak);
      timer.start();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Таймер фокуса')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: motionDuration(context),
                  child: Text(
                    timer.isBreak ? 'Перерыв' : 'Время сосредоточиться',
                    key: ValueKey(timer.isBreak),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  timer.isBreak
                      ? 'Немного отдыха перед следующим шагом'
                      : 'Одна задача. Всё внимание — ей.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: appMuted, height: 1.5),
                ),
                const SizedBox(height: 32),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(end: timer.progress),
                            duration: motionDuration(context, 350),
                            builder: (context, value, _) =>
                                CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 7,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: appSurface,
                                  color: timer.isBreak
                                      ? const Color(0xFF26846B)
                                      : appPrimary,
                                  semanticsLabel: 'Прогресс сеанса',
                                  semanticsValue: '${(value * 100).round()}%',
                                ),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: 0.75,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FittedBox(
                                child: Text(
                                  time,
                                  style: const TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -2,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                    color: appInk,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              AnimatedSwitcher(
                                duration: motionDuration(context),
                                child: Text(
                                  status,
                                  key: ValueKey(status),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: appMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: finished
                          ? startNext
                          : timer.isRunning
                          ? timer.pause
                          : timer.start,
                      icon: Icon(
                        finished
                            ? Icons.arrow_forward
                            : timer.isRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      label: Text(
                        finished
                            ? (timer.isBreak
                                  ? 'Начать фокус'
                                  : 'Начать перерыв')
                            : timer.isRunning
                            ? 'Приостановить'
                            : timer.hasStarted
                            ? 'Продолжить'
                            : 'Начать',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: timer.hasStarted ? () => timer.reset() : null,
                  icon: const Icon(Icons.restart_alt, size: 18),
                  label: const Text('Сбросить'),
                ),
                if (!finished)
                  TextButton(
                    onPressed: () => timer.reset(breakMode: !timer.isBreak),
                    child: Text(
                      timer.isBreak ? 'Перейти к фокусу' : 'Перейти к перерыву',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
