import 'package:fa_bank/api/rss_provider.dart';
import 'package:webfeed/webfeed.dart';

class RssRepository {
  final RssProvider _rssProvider = RssProvider();

  Future<RssFeed> getRssRequest() => _rssProvider.getRSs();
}
