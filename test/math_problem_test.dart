import 'dart:math';

import 'package:alarm_xv/challenges/math_problem.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('math generator respects difficulty and validity constraints', () {
    final generator = MathProblemGenerator(Random(42));
    String? previousKey;

    for (var index = 0; index < 500; index++) {
      final problem = generator.next(previousKey: previousKey);

      expect(problem.left, inInclusiveRange(20, 90));
      expect(problem.right, inInclusiveRange(20, 90));
      expect(problem.answer, greaterThanOrEqualTo(0));
      if (problem.isAddition) expect(problem.answer, lessThanOrEqualTo(200));
      expect(problem.key, isNot(previousKey));
      previousKey = problem.key;
    }
  });
}
