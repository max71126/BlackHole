import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape_small.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart';

import 'package:blackhole/CustomWidgets/custom_physics.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/Screens/Search/search.dart';

List items = [];
List globalItems = [];
List cachedItems = [];
List cachedGlobalItems = [];
bool fetched = false;
bool emptyRegional = false;
bool emptyGlobal = false;

class TopCharts extends StatefulWidget {
  final String region;
  const TopCharts({Key? key, required this.region}) : super(key: key);

  @override
  _TopChartsState createState() => _TopChartsState();
}

class _TopChartsState extends State<TopCharts> {
  @override
  Widget build(BuildContext cntxt) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(
                  child: Text(
                    'Local',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyText1!.color),
                  ),
                ),
                Tab(
                  child: Text(
                    'Global',
                    style: TextStyle(
                        color: Theme.of(context).textTheme.bodyText1!.color),
                  ),
                ),
              ],
            ),
            title: Text(
              'Spotify Top Charts',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).textTheme.bodyText1!.color,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Builder(
              builder: (BuildContext context) {
                return Transform.rotate(
                  angle: 22 / 7 * 2,
                  child: IconButton(
                    color: Theme.of(context).iconTheme.color,
                    icon: const Icon(Icons
                        .horizontal_split_rounded), // line_weight_rounded),
                    onPressed: () {
                      Scaffold.of(cntxt).openDrawer();
                    },
                    tooltip:
                        MaterialLocalizations.of(cntxt).openAppDrawerTooltip,
                  ),
                );
              },
            ),
          ),
          body: TabBarView(
            physics: const CustomPhysics(),
            children: [
              TopPage(
                region: widget.region,
              ),
              const TopPage(
                region: 'global',
              ),
            ],
          ),
        ));
  }
}

Future<List> scrapData(String region) async {
  // print('starting expensive operation');
  final HtmlUnescape unescape = HtmlUnescape();
  const String authority = 'www.spotifycharts.com';
  final String unencodedPath = '/regional/$region/daily/latest/';
  final Response res = await get(Uri.https(authority, unencodedPath));

  if (res.statusCode != 200) return List.empty();
  final List result = RegExp(
          r'\<td class=\"chart-table-image\"\>\n[ ]*?\<a href=\"https:\/\/open\.spotify\.com\/track\/(.*?)\" target=\"_blank\"\>\n[ ]*?\<img src=\"(https:\/\/i\.scdn\.co\/image\/.*?)\"\>\n[ ]*?\<\/a\>\n[ ]*?<\/td\>\n[ ]*?<td class=\"chart-table-position\">([0-9]*?)<\/td>\n[ ]*?<td class=\"chart-table-trend\">[.|\n| ]*<.*\n[ ]*<.*\n[ ]*<.*\n[ ]*<.*\n[ ]*<td class=\"chart-table-track\">\n[ ]*?<strong>(.*?)<\/strong>\n[ ]*?<span>by (.*?)<\/span>\n[ ]*?<\/td>\n[ ]*?<td class="chart-table-streams">(.*?)<\/td>')
      .allMatches(res.body)
      .map((m) {
    return {
      'id': m[1],
      'image': m[2],
      'position': m[3],
      'title': unescape.convert(m[4]!),
      'album': '',
      'artist': unescape.convert(m[5]!),
      'streams': m[6],
      'region': region,
    };
  }).toList();
  // print('finished expensive operation');
  return result;
}

class TopPage extends StatefulWidget {
  final String region;
  const TopPage({Key? key, required this.region}) : super(key: key);
  @override
  _TopPageState createState() => _TopPageState();
}

class _TopPageState extends State<TopPage> {
  Future<void> getData(String region) async {
    fetched = true;
    final List temp = await compute(scrapData, region);
    setState(() {
      if (region == 'global') {
        globalItems = temp;
        if (globalItems.isNotEmpty) {
          cachedGlobalItems = globalItems;
          Hive.box('cache').put(region, globalItems);
        }
        emptyGlobal = globalItems.isEmpty && cachedGlobalItems.isEmpty;
      } else {
        items = temp;
        if (items.isNotEmpty) {
          cachedItems = items;
          Hive.box('cache').put(region, items);
        }
        emptyRegional = items.isEmpty && cachedItems.isEmpty;
      }
    });
  }

  Future<void> getCachedData(String region) async {
    fetched = true;
    if (region != 'global') {
      cachedItems =
          await Hive.box('cache').get(region, defaultValue: []) as List;
    }
    if (region == 'global') {
      cachedGlobalItems =
          await Hive.box('cache').get(region, defaultValue: []) as List;
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (widget.region == 'global' && globalItems.isEmpty) {
      getCachedData(widget.region);
      getData(widget.region);
    } else {
      if (items.isEmpty) {
        getCachedData(widget.region);
        getData(widget.region);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isGlobal = widget.region == 'global';
    if (!fetched) {
      getCachedData(widget.region);
      getData(widget.region);
    }
    final List showList = isGlobal ? cachedGlobalItems : cachedItems;
    final bool isListEmpty = isGlobal ? emptyGlobal : emptyRegional;
    return Column(
      children: [
        if (showList.length <= 50)
          Expanded(
            child: isListEmpty
                ? EmptyScreen().emptyScreen(context, 0, ':( ', 100, 'ERROR', 60,
                    'Service Unavailable', 20)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.width / 7,
                          width: MediaQuery.of(context).size.width / 7,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).accentColor),
                            strokeWidth: 5,
                          )),
                    ],
                  ),
          )
        else
          Expanded(
              child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: showList.length,
            itemExtent: 70.0,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      const Image(
                        image: AssetImage('assets/cover.jpg'),
                      ),
                      if (showList[index]['image'] != '')
                        CachedNetworkImage(
                          imageUrl: showList[index]['image'].toString(),
                          errorWidget: (context, _, __) => const Image(
                            image: AssetImage('assets/cover.jpg'),
                          ),
                          placeholder: (context, url) => const Image(
                            image: AssetImage('assets/cover.jpg'),
                          ),
                        ),
                    ],
                  ),
                ),
                title: Text(
                  showList[index]['position'] == null
                      ? '${showList[index]["title"]}'
                      : '${showList[index]['position']}. ${showList[index]["title"]}',
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${showList[index]['artist']}',
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SearchPage(
                              query: showList[index]['title'].toString())));
                },
              );
            },
          )),
      ],
    );
  }
}
