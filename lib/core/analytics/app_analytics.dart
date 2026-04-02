import 'package:digia_ui/digia_ui.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class MyAppAnalytics implements DUIAnalytics {
  @override
  void onDataSourceError(
    String dataSourceType,
    String source,
    DataSourceErrorInfo errorInfo,
  ) {
    // Handle data source error, e.g. log to console or send to analytics service
    print(
      'Data source error: $dataSourceType from $source - ${errorInfo.message}',
    );
  }

  @override
  void onDataSourceSuccess(
    String dataSourceType,
    String source,
    dynamic metaData,
    dynamic perfData,
  ) {
    // Handle data source success, e.g. log performance data or send to analytics service
    print(
      'Data source success: $dataSourceType from $source - Performance: $perfData',
    );
  }

  @override
  void onEvent(List<AnalyticEvent> events) async {
    for (var event in events) {
      print("Event Name : ${event.name}");
      print("Event Payload : ${event.payload}");

      await FirebaseAnalytics.instance.logEvent(
        name: event.name,
        parameters: event.payload?.cast<String, Object>(),
      );
    }
  }
}
