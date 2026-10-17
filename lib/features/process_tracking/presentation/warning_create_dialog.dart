import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/genisleyen_metin.dart';

class WarningDraft {
  final String text;
  final String? audioPath;

  const WarningDraft({required this.text, this.audioPath});
}

Future<WarningDraft?> showWarningCreateDialog(BuildContext context) async {
  final recorder = AudioRecorder();
  String draft = '';
  String? validationMessage;
  String? audioPath;
  bool recording = false;

  InputDecoration warningField(BuildContext context) {
    final c = context.colors;
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.rField),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: 'Lütfen detay giriniz.',
      hintStyle: TextStyle(fontFamily: kBody, fontSize: 15.5, color: c.faint),
      counterStyle: TextStyle(fontFamily: kBody, fontSize: 12, color: c.muted),
      isDense: true,
      filled: true,
      fillColor: c.surface2,
      contentPadding: const EdgeInsets.fromLTRB(16, 15, 22, 15),
      border: border(c.border2),
      enabledBorder: border(c.border2),
      disabledBorder: border(c.border),
      focusedBorder: border(c.accent, 1.8),
    );
  }

  Future<void> stopRecording(StateSetter setDialogState) async {
    final path = await recorder.stop();
    audioPath = path;
    setDialogState(() => recording = false);
  }

  final result = await showDialog<WarningDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Uyarı Ekle'),
        scrollable: true,
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                maxLength: 500,
                inputFormatters: [LengthLimitingTextInputFormatter(500)],
                onChanged: (value) => draft = value,
                style: TextStyle(
                  fontFamily: kBody,
                  fontSize: 15.5,
                  color: context.colors.ink,
                ),
                cursorColor: context.colors.accent,
                decoration: warningField(context),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      if (recording) {
                        await stopRecording(setDialogState);
                        return;
                      }
                      if (!await recorder.hasPermission()) {
                        setDialogState(
                          () => validationMessage = 'Sesli not için mikrofon izni gerekli.',
                        );
                        return;
                      }
                      final temp = await getTemporaryDirectory();
                      final path =
                          '${temp.path}/warning-${DateTime.now().millisecondsSinceEpoch}.m4a';
                      await recorder.start(
                        const RecordConfig(
                          encoder: AudioEncoder.aacLc,
                          bitRate: 128000,
                          sampleRate: 44100,
                        ),
                        path: path,
                      );
                      setDialogState(() {
                        recording = true;
                        audioPath = null;
                        validationMessage = null;
                      });
                    } catch (_) {
                      setDialogState(
                        () => validationMessage = 'Ses kaydı başlatılamadı.',
                      );
                    }
                  },
                  icon: Icon(recording ? LucideIcons.square : LucideIcons.mic),
                  label: Text(
                    recording
                        ? 'Kaydı Bitir'
                        : audioPath != null
                        ? 'Sesli Notu Yeniden Kaydet'
                        : 'Sesli Not Kaydet',
                  ),
                ),
              ),
              if (audioPath != null && !recording) ...[
                const SizedBox(height: 8),
                Text(
                  'Sesli not hazır',
                  style: TextStyle(
                    fontFamily: kBody,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.colors.sub,
                  ),
                ),
              ],
              if (validationMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  validationMessage!,
                  style: TextStyle(
                    fontFamily: kBody,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: context.colors.bad,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (recording) await recorder.stop();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () async {
              final value = draft.trim();
              if (value.isEmpty) {
                setDialogState(
                  () => validationMessage = 'Uyarı detayı zorunludur.',
                );
                return;
              }
              if (recording) await stopRecording(setDialogState);
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop(
                  WarningDraft(text: value, audioPath: audioPath),
                );
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    ),
  );

  if (recording) {
    try {
      await recorder.stop();
    } catch (_) {}
  }
  await recorder.dispose();
  return result;
}