import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fixburgh/features/routing/data/agency_directory.dart';
import 'package:fixburgh/features/routing/domain/routing_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final bundled = File('assets/directory/agencies.json').readAsStringSync();

  Future<AgencyDirectory> directory(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    return AgencyDirectory(
      await SharedPreferences.getInstance(),
      loadBundled: () async => bundled,
      firestore: () => throw StateError('no Firebase in tests'),
    );
  }

  test('uses the bundled directory with no cache', () async {
    final d = await directory({});
    final engine = RoutingEngine.fromRecords(await d.load());
    expect(engine.byId(RoutingEngine.penndotId), isNotNull);
    expect(engine.agencyCount, greaterThan(130));
  });

  test('cached Firestore records replace bundled ones by id', () async {
    final d = await directory({
      'directory.agencies': jsonEncode([
        {
          'id': 'penndot-d11',
          'name': 'PennDOT District 11',
          'type': 'state',
          'phone': '412-555-0100',
        },
        {'id': 'new-office', 'name': 'New office', 'type': 'municipal'},
      ]),
    });
    final engine = RoutingEngine.fromRecords(await d.load());
    expect(engine.byId('penndot-d11')!.phone, '412-555-0100');
    expect(engine.byId('new-office'), isNotNull);
    expect(engine.byId('allegheny-dpw'), isNotNull);
  });

  test('a broken cache falls back to the bundled data', () async {
    final d = await directory({'directory.agencies': '{not json'});
    expect(RoutingEngine.fromRecords(await d.load()).agencyCount, 138);
  });

  test('refresh failures keep the current data', () async {
    expect(await (await directory({})).refresh(), isFalse);
  });

  test('records missing required fields are skipped', () {
    final engine = RoutingEngine.fromRecords([
      {'id': 'ok', 'name': 'OK', 'type': 'municipal'},
      {'id': 'broken', 'type': 'municipal'},
    ]);
    expect(engine.agencyCount, 1);
  });

  test('timestamps become dates when cached', () {
    final out = jsonSafe({
      'lastVerifiedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 4)),
      'categories': ['pothole'],
      'ref': Object(),
    });
    expect(out, {
      'lastVerifiedAt': '2026-10-04',
      'categories': ['pothole'],
      'ref': null,
    });
  });

  test('utility emergency lines for wires and gas', () {
    final engine = RoutingEngine.fromJson(bundled);
    expect(
      engine.emergencyLines('wires').map((a) => a.id),
      containsAll(['duquesne-light', 'west-penn-power']),
    );
    expect(
      engine.emergencyLines('gas').map((a) => a.id),
      containsAll(['peoples-gas', 'columbia-gas-pa']),
    );
    // Utilities never take over road routing.
    expect(engine.emergencyLines('flood'), isEmpty);
  });
}
