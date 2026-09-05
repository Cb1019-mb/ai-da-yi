import 'package:flutter/material.dart';

import '../../engine/skin_season.dart';
import '../../state/wardrobe_store.dart';
import '../../theme/app_theme.dart';
import '../widgets/common.dart';

class SkinQuizSheet extends StatefulWidget {
  const SkinQuizSheet({super.key});

  @override
  State<SkinQuizSheet> createState() => _SkinQuizSheetState();
}

class _SkinQuizSheetState extends State<SkinQuizSheet> {
  late List<int?> _choices;
  String? _result;

  @override
  void initState() {
    super.initState();
    _choices = List.filled(skinSeasonQuestions.length, null);
  }

  bool get _allAnswered => _choices.every((c) => c != null);

  void _diagnose() {
    final result = diagnoseSkinSeason(_choices.cast<int>());
    setState(() => _result = result);
  }

  void _apply() {
    final store = WardrobeStore.instance;
    store.updateProfile(store.profile.copyWith(skinSeason: _result));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xl),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SheetHandle(),
          const SizedBox(height: AppSpacing.md),
          const Text('肤色四季型诊断',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink)),
          const SizedBox(height: 6),
          const Text('回答 8 道题，判断最适合你的色系',
              style: TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < skinSeasonQuestions.length; i++)
            _questionCard(i),
          const SizedBox(height: AppSpacing.lg),
          if (_result != null) ...[
            _resultCard(_result!),
            const SizedBox(height: AppSpacing.md),
          ],
          SizedBox(
            width: double.infinity,
            child: _result == null
                ? FilledButton(
                    onPressed: _allAnswered ? _diagnose : null,
                    child: Text(_allAnswered ? '查看结果' : '请答完所有题目'),
                  )
                : FilledButton(
                    onPressed: _apply,
                    child: const Text('应用此季型'),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _questionCard(int index) {
    final q = skinSeasonQuestions[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${index + 1}. ${q.text}',
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var j = 0; j < q.options.length; j++)
              TagChip(
                label: q.options[j].label,
                selected: _choices[index] == j,
                onTap: () => setState(() {
                  _choices[index] = j;
                  _result = null;
                }),
              ),
          ],
        ),
      ]),
    );
  }

  Widget _resultCard(String season) {
    final advice = skinSeasonAdvice[season] ?? const [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.claySoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('你的季型：$season',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.clayInk)),
        const SizedBox(height: 8),
        Text('推荐色系：${advice.join(' · ')}',
            style: const TextStyle(
                fontSize: 13, color: AppColors.ink, height: 1.5)),
      ]),
    );
  }
}
