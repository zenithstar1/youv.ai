class AppConfigResponse {
  final bool hideLocation;

  AppConfigResponse({
    required this.hideLocation,
  });

  factory AppConfigResponse.fromJson(Map<String, dynamic> json) {
    // Support both flat responses:
    //   { "hide_location": true }
    // and wrapped responses:
    //   { "success": true, "data": { "hide_location": true } }
    final dynamic data = json['data'];
    final Map<String, dynamic> payload = data is Map
        ? Map<String, dynamic>.from(data)
        : json;

    return AppConfigResponse(
      hideLocation: payload['hide_location'] == true,
    );
  }
}