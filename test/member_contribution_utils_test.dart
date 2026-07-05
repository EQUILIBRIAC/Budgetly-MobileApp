import 'package:budgetly_app/domain/entities/contribution_entities.dart';
import 'package:budgetly_app/features/member/domain/member_contribution_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dedupeByContribution deja una fila por gasto', () {
    const c1 = 'CN-luz';
    const c2 = 'CN-agua';
    final items = [
      MemberContribution(
        id: 'MC-1',
        memberId: 'HM-1',
        contributionId: c1,
        amount: 100,
        status: 0,
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 1),
      ),
      MemberContribution(
        id: 'MC-2',
        memberId: 'HM-1',
        contributionId: c1,
        amount: 100,
        status: 1,
        payedAt: DateTime(2026, 7, 4),
        createdAt: DateTime(2026, 7, 2),
        updatedAt: DateTime(2026, 7, 2),
      ),
      MemberContribution(
        id: 'MC-3',
        memberId: 'HM-1',
        contributionId: c2,
        amount: 145.83,
        status: 0,
        createdAt: DateTime(2026, 7, 1),
        updatedAt: DateTime(2026, 7, 1),
      ),
    ];

    final deduped = MemberContributionUtils.dedupeByContribution(
      items,
      validContributionIds: {c1, c2},
    );

    expect(deduped.length, 2);
    expect(
      deduped.firstWhere((e) => e.contributionId == c1).isPaid,
      isTrue,
    );
  });

  test('labelFor usa descripción de la contribución', () {
    final label = MemberContributionUtils.labelFor(
      MemberContribution(
        id: 'MC-x',
        memberId: 'HM-1',
        contributionId: 'CN-1',
        amount: 50,
        status: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      contributionsById: {
        'CN-1': Contribution(
          id: 'CN-1',
          billId: 'BG-1',
          householdId: 'HH-1',
          description: 'Aporte luz',
          deadlineForMembers: DateTime(2026, 8, 2),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      },
      billsById: {},
    );

    expect(label, 'Aporte luz');
  });

  test('dedupeByContribution agrupa duplicados del mismo billId', () {
    final contributionsById = {
      'CN-a': Contribution(
        id: 'CN-a',
        billId: 'BG-luz',
        householdId: 'HH-1',
        description: 'Aporte luz',
        deadlineForMembers: DateTime(2026, 8, 2),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      'CN-b': Contribution(
        id: 'CN-b',
        billId: 'BG-luz',
        householdId: 'HH-1',
        description: 'Aporte luz dup',
        deadlineForMembers: DateTime(2026, 8, 2),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    };

    final deduped = MemberContributionUtils.dedupeByContribution(
      [
        MemberContribution(
          id: 'MC-1',
          memberId: 'HM-1',
          contributionId: 'CN-a',
          amount: 100,
          status: 0,
          createdAt: DateTime(2026, 7, 1),
          updatedAt: DateTime(2026, 7, 1),
        ),
        MemberContribution(
          id: 'MC-2',
          memberId: 'HM-1',
          contributionId: 'CN-b',
          amount: 100,
          status: 1,
          payedAt: DateTime(2026, 7, 4),
          createdAt: DateTime(2026, 7, 2),
          updatedAt: DateTime(2026, 7, 2),
        ),
      ],
      contributionsById: contributionsById,
    );

    expect(deduped.length, 1);
    expect(deduped.first.isPaid, isTrue);
  });
}
