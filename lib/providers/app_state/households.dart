part of '../app_state.dart';

/// Month selection, households, membership and account actions.
extension AppStateHouseholds on AppState {
  Future<void> setMonth(String monthId) async {
    final hid = _activeHid;
    if (hid == null) return;
    if (_monthId == monthId) return;
    final known =
        _months.any((m) => m.id == monthId) ||
        await _sync.hasMonth(hid, monthId);
    if (!known) {
      final exists = await _repo.monthExists(hid, monthId);
      if (!exists) {
        throw StateError('Month does not exist. Create it first.');
      }
    }
    _monthId = monthId;
    BudgetMonth? fromList;
    for (final m in _months) {
      if (m.id == monthId) {
        fromList = m;
        break;
      }
    }
    final bundle = await _sync.loadMonth(hid, monthId);
    if (bundle != null) {
      _applyMonthBundle(bundle);
    }
    // Live months list already has cascaded leftoverFromPrior; month-scoped
    // local cache can lag until pull-to-refresh / watchMonth catches up.
    if (fromList != null) {
      _selectedMonth = fromList;
    }
    _notify();
    await _listenMonthData(hid, monthId, waitForFirst: bundle == null);
    _notify();
  }

  Future<void> createMonth({
    required String monthId,
    String? copyFromMonthId,
    bool empty = false,
    bool rolloverLeftover = false,
    Set<String>? categoryIdsToCopy,
  }) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    if (empty) {
      await _repo.createEmptyMonth(
        householdId: hid,
        monthId: monthId,
        rolloverLeftover: rolloverLeftover,
      );
    } else {
      final copyFrom =
          copyFromMonthId ??
          _months.where((m) => m.id != monthId).firstOrNull?.id;
      if (copyFrom != null && copyFrom.isNotEmpty) {
        await _repo.createMonthFromCopy(
          householdId: hid,
          fromMonthId: copyFrom,
          toMonthId: monthId,
          rolloverLeftover: rolloverLeftover,
          categoryIds: categoryIdsToCopy,
        );
      } else {
        await _repo.createEmptyMonth(
          householdId: hid,
          monthId: monthId,
          rolloverLeftover: rolloverLeftover,
        );
      }
    }
    await setMonth(monthId);
  }

  Future<void> setLocale(String code) async {
    _localeCode = code;
    _notify();
    final uid = _firebaseUser?.uid;
    if (uid != null) {
      await _auth.updateLocale(uid, code);
    }
  }

  Future<void> createHousehold(String name) async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return;
    final h = await _repo.createHousehold(
      name: name,
      creatorUid: uid,
      creatorName: currentDisplayName,
    );
    final ids = [...?_appUser?.householdIds];
    if (!ids.contains(h.id)) ids.add(h.id);
    _appUser = _appUser?.copyWith(householdIds: ids, activeHouseholdId: h.id);
    await _refreshMyHouseholds();
    await _auth.refreshMembershipClaims();
    await _attachHousehold(h.id);
  }

  Future<void> updateHouseholdName(String name) async {
    final hid = _activeHid;
    if (hid == null) throw StateError('No household');
    await _repo.updateHouseholdName(householdId: hid, name: name);
    await _refreshMyHouseholds();
  }

  Future<void> joinHousehold(String inviteCode) async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return;
    final h = await _repo.joinHousehold(
      inviteCode: inviteCode,
      uid: uid,
      displayName: currentDisplayName,
    );
    final ids = [...?_appUser?.householdIds];
    if (!ids.contains(h.id)) ids.add(h.id);
    _appUser = _appUser?.copyWith(householdIds: ids, activeHouseholdId: h.id);
    await _refreshMyHouseholds();
    await _auth.refreshMembershipClaims();
    await _attachHousehold(h.id);
  }

  Future<void> switchHousehold(String householdId) async {
    final uid = _firebaseUser?.uid;
    if (uid == null) return;
    if (_appUser?.activeHouseholdId == householdId &&
        _household?.id == householdId) {
      return;
    }
    if (!(_appUser?.householdIds.contains(householdId) ?? false)) {
      throw StateError('Not a member of this household');
    }
    await _auth.setActiveHouseholdId(uid, householdId);
    _appUser = _appUser?.copyWith(activeHouseholdId: householdId);
    await _attachHousehold(householdId);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> deleteHousehold() async {
    final uid = _firebaseUser?.uid;
    final household = _household;
    if (uid == null || household == null) throw StateError('No household');
    if (!household.isOwnedBy(uid)) {
      throw StateError('Only the owner can delete the household');
    }
    final deletedId = household.id;
    await _detachBudgetListeners();
    try {
      await _repo.deleteHousehold(householdId: deletedId, ownerUid: uid);
    } catch (e) {
      await _attachHousehold(deletedId);
      rethrow;
    }
    final remaining = (_appUser?.householdIds ?? const [])
        .where((id) => id != deletedId)
        .toList();
    _appUser = _appUser?.copyWith(
      householdIds: remaining,
      activeHouseholdId: remaining.isEmpty ? null : remaining.first,
      clearActiveHouseholdId: remaining.isEmpty,
    );
    await _refreshMyHouseholds();
    await _auth.refreshMembershipClaims();
    if (remaining.isEmpty) {
      _household = null;
      _notify();
    } else {
      await _attachHousehold(remaining.first);
    }
  }

  Future<void> leaveHousehold() async {
    final uid = _firebaseUser?.uid;
    final household = _household;
    if (uid == null || household == null) throw StateError('No household');
    if (household.isOwnedBy(uid)) {
      throw StateError('owner-must-delete');
    }
    final leftId = household.id;
    await _repo.leaveHousehold(householdId: leftId, uid: uid);
    final remaining = (_appUser?.householdIds ?? const [])
        .where((id) => id != leftId)
        .toList();
    _appUser = _appUser?.copyWith(
      householdIds: remaining,
      activeHouseholdId: remaining.isEmpty ? null : remaining.first,
      clearActiveHouseholdId: remaining.isEmpty,
    );
    await _refreshMyHouseholds();
    await _auth.refreshMembershipClaims();
    if (remaining.isEmpty) {
      await _detachBudgetListeners();
      _notify();
    } else {
      await _attachHousehold(remaining.first);
    }
  }

  Future<void> removeMember(String memberUid) async {
    final hid = _household?.id;
    if (hid == null) throw StateError('No household');
    if (!isHouseholdOwner) {
      throw StateError('Only the owner can remove members');
    }
    if (memberUid == _firebaseUser?.uid) {
      throw StateError('Use leave household');
    }
    await _repo.removeMember(householdId: hid, memberUid: memberUid);
  }

  Future<void> setMemberRole(String memberUid, String role) async {
    final hid = _household?.id;
    if (hid == null) throw StateError('No household');
    if (!isHouseholdOwner) throw StateError('Only the owner can change roles');
    await _repo.setMemberRole(
      householdId: hid,
      memberUid: memberUid,
      role: role,
    );
  }

  Future<void> deleteAccount({String? password}) async {
    final uid = _firebaseUser?.uid;
    if (uid == null) throw StateError('Not signed in');
    for (final h in _myHouseholds) {
      if (h.isOwnedBy(uid)) {
        throw StateError('must-delete-household-first');
      }
    }
    final ids = List<String>.from(_appUser?.householdIds ?? const []);
    for (final hid in ids) {
      try {
        await _repo.leaveHousehold(householdId: hid, uid: uid);
      } catch (_) {}
    }
    await _detachBudgetListeners();
    _household = null;
    _myHouseholds = [];
    await _auth.deleteUserDoc(uid);
    await _auth.deleteAuthUser(password: password);
  }

  Future<String> duplicateCurrentMonth() async {
    final hid = _activeHid;
    final from = _monthId;
    if (hid == null || from == null) throw StateError('No month selected');
    final next = await _repo.duplicateMonth(
      householdId: hid,
      fromMonthId: from,
    );
    await setMonth(next);
    return next;
  }
}
