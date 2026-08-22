import 'dart:math';

class MathProblem {
  const MathProblem({
    required this.left,
    required this.right,
    required this.isAddition,
  });

  final int left;
  final int right;
  final bool isAddition;

  int get answer => isAddition ? left + right : left - right;
  String get key => '$left${isAddition ? '+' : '-'}$right';
}

class MathProblemGenerator {
  MathProblemGenerator([Random? random]) : _random = random ?? Random();

  final Random _random;

  MathProblem next({String? previousKey}) {
    for (var attempt = 0; attempt < 20; attempt++) {
      final first = 20 + _random.nextInt(71);
      final second = 20 + _random.nextInt(71);
      final addition = _random.nextBool();
      final problem = MathProblem(
        left: addition ? first : max(first, second),
        right: addition ? second : min(first, second),
        isAddition: addition,
      );
      if (problem.key != previousKey) return problem;
    }
    return previousKey == '47+38'
        ? const MathProblem(left: 83, right: 29, isAddition: false)
        : const MathProblem(left: 47, right: 38, isAddition: true);
  }
}
