/// Utility to merge remote RTDB results into a local results list.
Map<String, int> mergeRemoteResults(List<dynamic> localResults, Map remote) {
  var added = 0, updated = 0;
  // remote structure: { courseId: { examType: { resultId: resultData } } }
  remote.forEach((courseKey, examsVal) {
    final courseId = courseKey.toString();
    if (examsVal is! Map) return;
    examsVal.forEach((examKey, resultsVal) {
      final examType = examKey.toString();
      if (resultsVal is! Map) return;
      resultsVal.forEach((rid, rdata) {
        if (rdata is! Map) return;
        final remoteResult = Map<String, Object?>.from(rdata);
        remoteResult['resultId'] = rid.toString();
        remoteResult['courseId'] = courseId;
        remoteResult['examType'] = examType;

        final idx = localResults.indexWhere((r) =>
            (r['resultId']?.toString() == remoteResult['resultId'].toString()) ||
            ((r['studentId'] == remoteResult['studentId']) && (r['courseId'] == courseId) && ((r['examType'] ?? '') == examType)));

        if (idx != -1) {
          // Create a merged copy to avoid runtime type mismatches when replacing
          // the list element; copying preserves a compatible runtime map type.
          final existing = localResults[idx] as Map;
          final merged = Map.of(existing);
          merged.addAll(remoteResult);
          // Mutate the existing map instance to avoid replacing the list element
          // (which can trigger runtime generic type checks). Add entries one by
          // one to avoid Map.addAll runtime type checks against the source map.
          existing.clear();
          for (final ent in merged.entries) {
            existing[ent.key] = ent.value;
          }
          updated++;
        } else {
          localResults.add(remoteResult);
          added++;
        }
      });
    });
  });

  return {'added': added, 'updated': updated};
}
