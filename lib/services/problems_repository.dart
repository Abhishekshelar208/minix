import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:minix/models/problem.dart';

abstract class ProblemsRepository {
  Future<List<String>> listProblemIdsByDomain(String domain);
  Future<Map<String, Problem>> fetchProblemsByIds(List<String> ids);
}

class FirebaseProblemsRepository implements ProblemsRepository {
  final FirebaseDatabase _db;
  final Map<String, Problem> _cache = {};

  FirebaseProblemsRepository({FirebaseDatabase? db}) : _db = db ?? FirebaseDatabase.instance;

  @override
  Future<List<String>> listProblemIdsByDomain(String domain) async {
    final snap = await _db.ref('ProblemsByDomain/$domain').get();
    final value = snap.value;
    if (value is Map) {
      return value.keys.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  @override
  Future<Map<String, Problem>> fetchProblemsByIds(List<String> ids) async {
    final Map<String, Problem> result = {};
    final List<String> toFetch = [];

    for (final id in ids) {
      if (_cache.containsKey(id)) {
        result[id] = _cache[id]!;
      } else {
        toFetch.add(id);
      }
    }

    // Fetch remaining in parallel
    final futures = toFetch.map((id) async {
      final snap = await _db.ref('Problems/$id').get();
      final data = snap.value;
      if (data is Map) {
        final p = Problem.fromMap(id, data);
        _cache[id] = p;
        result[id] = p;
      }
    }).toList();

    await Future.wait(futures);
    return result;
  }
}
