class AppConfigResponse {
  final bool hideLocation;
  final bool hideSaveAnalysis;

  AppConfigResponse({
    required this.hideLocation,
    required this.hideSaveAnalysis,
  });

  /// Whether the Save Analysis CTA should be shown.
  bool get canSendReport => !hideSaveAnalysis;

  factory AppConfigResponse.fromJson(Map<String, dynamic> json) {
    // Support both flat responses:
    //   { "hide_location": true, "hide_save_analysis": false }
    // and wrapped responses:
    //   { "success": true, "data": { ... } }
    final dynamic data = json['data'];
    final Map<String, dynamic> payload = data is Map
        ? Map<String, dynamic>.from(data)
        : json;

    return AppConfigResponse(
      hideLocation: payload['hide_location'] == true,
      hideSaveAnalysis: payload['hide_save_analysis'] == true,
    );
  }
}
