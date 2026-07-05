import 'package:budgetly_app/core/utils/api_value_parsers.dart';
import 'package:budgetly_app/domain/entities/contribution_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MemberContribution.fromJson acepta status Pending/Done del API', () {
    final pending = MemberContribution.fromJson({
      'id': 'MC-1',
      'contributionId': 'CN-1',
      'memberId': 'HM-1',
      'amount': 50.0,
      'status': 'Pending',
      'payedAt': null,
    });
    expect(pending.status, 0);
    expect(pending.isPaid, isFalse);

    final done = MemberContribution.fromJson({
      'id': 'MC-2',
      'contributionId': 'CN-1',
      'memberId': 'HM-1',
      'amount': 100.0,
      'status': 'Done',
      'payedAt': '07/04/2026',
    });
    expect(done.status, 1);
    expect(done.isPaid, isTrue);
    expect(done.payedAt, DateTime(2026, 7, 4));
  });

  test('parseMemberContributionStatus normaliza variantes', () {
    expect(parseMemberContributionStatus('Pending'), 0);
    expect(parseMemberContributionStatus('Done'), 1);
    expect(parseMemberContributionStatus(1), 1);
    expect(parseMemberContributionStatus(true), 1);
  });
}
