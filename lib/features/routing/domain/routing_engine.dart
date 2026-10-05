import 'dart:convert';

import 'package:fixburgh/features/report/domain/report.dart';
import 'package:fixburgh/features/routing/domain/municipality_locator.dart';
import 'package:fixburgh/features/routing/domain/road_owner_locator.dart';

/// An office that can fix things (BRD section 14.1, `agencies`).
class Agency {
  const Agency({
    required this.id,
    required this.name,
    required this.type,
    this.phone,
    this.phoneLabel,
    this.email,
    this.website,
    this.webFormUrl,
    this.address,
    this.hours,
    this.municipalityIds = const [],
  });

  factory Agency.fromJson(Map<String, dynamic> j) => Agency(
    id: j['id'] as String,
    name: j['name'] as String,
    type: j['type'] as String,
    phone: j['phone'] as String?,
    phoneLabel: j['phoneLabel'] as String?,
    email: j['email'] as String?,
    website: j['website'] as String?,
    webFormUrl: j['webFormUrl'] as String?,
    address: j['address'] as String?,
    hours: j['hours'] as String?,
    municipalityIds:
        (j['municipalityIds'] as List?)?.cast<String>() ?? const [],
  );

  final String id;
  final String name;

  /// `state`, `county`, `municipal` or `311`.
  final String type;
  final String? phone;

  /// How to show the number, e.g. "1-800-FIX-ROAD".
  final String? phoneLabel;
  final String? email;
  final String? website;
  final String? webFormUrl;
  final String? address;
  final String? hours;
  final List<String> municipalityIds;
}

/// Why this office was chosen; the UI turns it into a sentence.
enum RoutingReason {
  stateRoad,
  turnpike,
  countyRoad,
  localRoad,
  municipalService,
}

class RoutingResult {
  const RoutingResult({
    required this.agency,
    required this.municipality,
    required this.road,
    required this.reason,
    this.alternate,
  });

  final Agency agency;
  final Municipality municipality;
  final RoadMatch road;
  final RoutingReason reason;

  /// Second choice to show if the first office says it isn't theirs.
  final Agency? alternate;
}

/// Decides which office fixes a problem (BRD section 8, Appendix A).
class RoutingEngine {
  RoutingEngine(List<Agency> agencies)
    : _byId = {for (final a in agencies) a.id: a},
      _byMunicipality = {
        for (final a in agencies.where((a) => a.type == 'municipal'))
          for (final m in a.municipalityIds) m: a,
      },
      _municipal311 = {
        for (final a in agencies.where((a) => a.type == '311'))
          for (final m in a.municipalityIds) m: a,
      };

  factory RoutingEngine.fromJson(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return RoutingEngine([
      for (final a in (json['agencies'] as List).cast<Map<String, dynamic>>())
        Agency.fromJson(a),
    ]);
  }

  static const penndotId = 'penndot-d11';
  static const turnpikeId = 'pa-turnpike';
  static const countyId = 'allegheny-dpw';

  /// Categories the municipality handles wherever they are: sidewalks
  /// belong to property owners/municipalities, dumping is code enforcement,
  /// and streetlight ownership is set per municipality.
  static const Set<ReportCategory> _alwaysMunicipal = {
    ReportCategory.sidewalk,
    ReportCategory.dumping,
    ReportCategory.streetlight,
  };

  final Map<String, Agency> _byId;
  final Map<String, Agency> _byMunicipality;
  final Map<String, Agency> _municipal311;

  int get agencyCount => _byId.length;

  /// The municipality's own office, preferring its 311 line when it has one.
  Agency municipalOffice(Municipality m) =>
      _municipal311[m.id] ??
      _byMunicipality[m.id] ??
      Agency(id: 'muni-${m.id}', name: m.name, type: 'municipal');

  RoutingResult route({
    required Municipality municipality,
    required RoadMatch road,
    required ReportCategory category,
  }) {
    final local = municipalOffice(municipality);
    if (_alwaysMunicipal.contains(category)) {
      return RoutingResult(
        agency: local,
        municipality: municipality,
        road: road,
        reason: RoutingReason.municipalService,
        alternate: road.owner == RoadOwner.local ? null : _ownerAgency(road),
      );
    }
    final owner = _ownerAgency(road);
    if (owner == null) {
      return RoutingResult(
        agency: local,
        municipality: municipality,
        road: road,
        reason: RoutingReason.localRoad,
      );
    }
    return RoutingResult(
      agency: owner,
      municipality: municipality,
      road: road,
      reason: switch (road.owner) {
        RoadOwner.penndot => RoutingReason.stateRoad,
        RoadOwner.turnpike => RoutingReason.turnpike,
        _ => RoutingReason.countyRoad,
      },
      alternate: local,
    );
  }

  Agency? _ownerAgency(RoadMatch road) => switch (road.owner) {
    RoadOwner.penndot => _byId[penndotId],
    RoadOwner.turnpike => _byId[turnpikeId],
    RoadOwner.county => _byId[countyId],
    RoadOwner.local => null,
  };
}
