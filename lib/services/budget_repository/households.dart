part of '../budget_repository.dart';

/// Household lifecycle and membership.
extension BudgetRepositoryHouseholds on BudgetRepository {
  Future<Household> createHousehold({
    required String name,
    required String creatorUid,
    String? creatorName,
  }) async {
    final ref = _db.collection('households').doc();
    final profileName = (creatorName ?? '').trim().isEmpty
        ? 'Member'
        : creatorName!.trim();
    final household = Household(
      id: ref.id,
      name: name.trim(),
      memberIds: [creatorUid],
      inviteCode: _generateInviteCode(),
      createdBy: creatorUid,
      memberProfiles: {
        creatorUid: MemberProfile(
          uid: creatorUid,
          name: profileName,
          role: 'owner',
        ),
      },
    );
    await ref.set(household.toMap());
    await _addUserMembership(creatorUid, household.id);
    return household;
  }

  Future<Household> joinHousehold({
    required String inviteCode,
    required String uid,
    String? displayName,
  }) async {
    final code = inviteCode.trim().toUpperCase();
    final query = await _db
        .collection('households')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw StateError('Invite code not found');
    }
    final doc = query.docs.first;
    final data = doc.data();
    final members = List<String>.from(data['memberIds'] as List? ?? []);
    if (!members.contains(uid)) {
      members.add(uid);
      final profileName = (displayName ?? '').trim().isEmpty
          ? 'Member'
          : displayName!.trim();
      await doc.reference.update({
        'memberIds': members,
        'memberProfiles.$uid': {'name': profileName, 'role': 'editor'},
      });
    }
    await _addUserMembership(uid, doc.id);
    return Household.fromMap(doc.id, {...data, 'memberIds': members});
  }

  Future<void> _addUserMembership(String uid, String householdId) async {
    await _db.collection('users').doc(uid).update({
      'householdIds': FieldValue.arrayUnion([householdId]),
      'activeHouseholdId': householdId,
    });
  }

  Future<void> _removeUserMembership(String uid, String householdId) async {
    final ref = _db.collection('users').doc(uid);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final ids = List<String>.from(data['householdIds'] as List? ?? const []);
    ids.remove(householdId);
    final active = data['activeHouseholdId'] as String?;
    final newActive = ids.contains(active)
        ? active
        : (ids.isEmpty ? null : ids.first);
    await ref.update({
      'householdIds': ids,
      if (newActive == null)
        'activeHouseholdId': FieldValue.delete()
      else
        'activeHouseholdId': newActive,
    });
  }

  Future<List<Household>> fetchHouseholdsByIds(List<String> ids) async {
    final result = await Future.wait(
      ids.where((id) => id.isNotEmpty).map((id) async {
        final snap = await _householdRef(id).get();
        if (!snap.exists || snap.data() == null) return null;
        return Household.fromMap(snap.id, snap.data()!);
      }),
    );
    return result.whereType<Household>().toList();
  }

  Future<void> updateHouseholdName({
    required String householdId,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await _householdRef(householdId).update({'name': trimmed});
  }

  Future<void> _deleteQueryDocs(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    final snap = await col.get();
    if (snap.docs.isEmpty) return;
    await _commitInChunks([
      for (final doc in snap.docs) (batch) => batch.delete(doc.reference),
    ]);
  }

  Future<void> deleteHousehold({
    required String householdId,
    required String ownerUid,
  }) async {
    final snap = await _householdRef(householdId).get();
    final memberIds = List<String>.from(
      snap.data()?['memberIds'] as List? ?? [ownerUid],
    );
    if (!memberIds.contains(ownerUid)) {
      memberIds.add(ownerUid);
    }

    const monthSubs = [
      'incomeSources',
      'incomeEntries',
      'plans',
      'expenses',
      'deposits',
      'potBalances',
      'loanPayments',
    ];
    final months = await _months(householdId).get();
    for (final month in months.docs) {
      for (final name in monthSubs) {
        await _deleteQueryDocs(month.reference.collection(name));
      }
    }
    await _deleteQueryDocs(_months(householdId));
    await _deleteQueryDocs(_categories(householdId));
    await _deleteQueryDocs(_subcategories(householdId));
    await _deleteQueryDocs(_loans(householdId));
    await _deleteQueryDocs(
      _householdRef(householdId).collection('recurringBills'),
    );
    await _householdRef(householdId).delete();

    for (final uid in memberIds) {
      try {
        await _removeUserMembership(uid, householdId);
      } catch (_) {}
    }
  }

  Future<void> leaveHousehold({
    required String householdId,
    required String uid,
  }) async {
    final ref = _householdRef(householdId);
    final snap = await ref.get();
    if (snap.exists) {
      final members = List<String>.from(
        snap.data()?['memberIds'] as List? ?? const [],
      );
      members.remove(uid);
      await ref.update({
        'memberIds': members,
        'memberProfiles.$uid': FieldValue.delete(),
      });
    }
    await _removeUserMembership(uid, householdId);
  }

  Future<void> removeMember({
    required String householdId,
    required String memberUid,
  }) async {
    await leaveHousehold(householdId: householdId, uid: memberUid);
  }

  Future<void> setMemberRole({
    required String householdId,
    required String memberUid,
    required String role,
  }) async {
    await _householdRef(
      householdId,
    ).update({'memberProfiles.$memberUid.role': role});
  }
}
