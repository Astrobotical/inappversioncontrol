int compareVersions(String a, String b) {
  // Supports: "1.2.3" vs "1.2.10" (numeric segments)
  final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();

  final maxLen = pa.length > pb.length ? pa.length : pb.length;
  while (pa.length < maxLen) pa.add(0);
  while (pb.length < maxLen) pb.add(0);

  for (var i = 0; i < maxLen; i++) {
    if (pa[i] != pb[i]) return pa[i].compareTo(pb[i]);
  }
  return 0;
}