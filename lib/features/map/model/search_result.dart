class SearchResult {
  final String name;
  final double lat;
  final double lon;

  SearchResult({
    required this.name,
    required this.lat,
    required this.lon,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      name: json['display_name'],
      lat: double.parse(json['lat']),
      lon: double.parse(json['lon']),
    );
  }
}
