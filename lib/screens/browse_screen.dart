import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/asset.dart';
import '../providers/trade_provider.dart';
import '../providers/blog_provider.dart';
import '../widgets/esg_data_popup.dart';
import 'article_detail_page.dart';
import 'asset_detail_page.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  _BrowsePageState createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  int selectedIndex = 0;
  bool sortAscending = true;
  bool sortByEsg = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BlogProvider>(context, listen: false).fetchBlogPosts();
      Provider.of<TradeProvider>(context, listen: false).fetchTopAssets();
      Provider.of<TradeProvider>(context, listen: false).fetchEsgData();
      Provider.of<TradeProvider>(context, listen: false).fetchSupportedTickers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tradeProvider = Provider.of<TradeProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Esplora',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Barra di ricerca
                Autocomplete<Map<String, dynamic>>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<Map<String, dynamic>>.empty();
                    }
                    return tradeProvider.filterSupportedTickers(textEditingValue.text);
                  },
                  displayStringForOption: (Map<String, dynamic> option) =>
                  '${option['ticker']} - ${option['company']}',
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: 'Cerca un asset',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                    );
                  },
                  onSelected: (Map<String, dynamic> selection) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssetDetailPage(ticker: selection['ticker']),
                      ),
                    );
                  },
                ),



                const SizedBox(height: 20),

                // Pulsanti delle categorie (Learning, Asset, ESG)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCategoryButton('Learning', 0),
                    _buildCategoryButton('Asset', 1),
                    _buildCategoryButton('ESG', 2),
                  ],
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: _buildContent(tradeProvider),
                ),
              ],
            ),
          ),

          if (selectedIndex == 2)
            Positioned(
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
              child: ElevatedButton(
                onPressed: () {
                  tradeProvider.fetchEsgData();
                  showDialog(
                    context: context,
                    builder: (context) => EsgDataPopup(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                child: const Text('Calcola ESG'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String title, int index) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          selectedIndex = index;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: selectedIndex == index ? Colors.black : Colors.grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Text(title),
    );
  }

  Widget _buildContent(TradeProvider tradeProvider) {
    switch (selectedIndex) {
      case 0:
        return _buildLearningContent();
      case 1:
        return _buildAssetContent(tradeProvider);
      case 2:
        return _buildEsgContent(tradeProvider);
      default:
        return Container();
    }
  }

  Widget _buildLearningContent() {
    return Consumer<BlogProvider>(
      builder: (context, blogProvider, child) {
        if (blogProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (blogProvider.blogPosts.isEmpty) {
          return const Center(child: Text('Nessun articolo disponibile'));
        }

        return ListView.builder(
          itemCount: blogProvider.blogPosts.length,
          itemBuilder: (context, index) {
            final blogPost = blogProvider.blogPosts[index];
            final previewContent = blogPost.content.length > 50
                ? '${blogPost.content.substring(0, 50)}...'
                : blogPost.content;

            return ListTile(
              title: Hero(
                tag: 'articleTitle_${blogPost.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Text(blogPost.title),
                ),
              ),
              subtitle: Text(
                previewContent,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: blogPost.viewed ? const Icon(
                  Icons.check, color: Colors.green) : null,
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        ArticleDetailPage(blogPost: blogPost),
                    transitionsBuilder: (context, animation, secondaryAnimation,
                        child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.ease;

                      var tween = Tween(begin: begin, end: end).chain(
                          CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(seconds: 1),
                  ),
                ).then((_) {
                  Provider.of<BlogProvider>(context, listen: false)
                      .markAsViewed(blogPost);
                });
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAssetContent(TradeProvider tradeProvider) {
    if (tradeProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tradeProvider.topAssets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final stocks = tradeProvider.topAssets.where((asset) => Asset.STOCKS.contains(asset['ticker'])).toList();
    final etfs = tradeProvider.topAssets.where((asset) => Asset.ETFS.contains(asset['ticker'])).toList();
    final bonds = tradeProvider.topAssets.where((asset) => Asset.BONDS.contains(asset['ticker'])).toList();

    return ListView(
      children: [
        if (stocks.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Stocks',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          ...stocks.map((asset) => _buildAssetListTile(asset)).toList(),
          const Divider(thickness: 1, color: Colors.grey),
        ],
        if (etfs.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('ETFs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          ...etfs.map((asset) => _buildAssetListTile(asset)).toList(),
          const Divider(thickness: 1, color: Colors.grey),
        ],
        if (bonds.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Bonds',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          ...bonds.map((asset) => _buildAssetListTile(asset)).toList(),
        ],
      ],
    );
  }

  Widget _buildAssetListTile(Map<String, dynamic> asset) {
    final company = asset['company'] ?? 'Unknown';
    final ticker = asset['ticker'] ?? 'N/A';
    final history = asset['history'] as List<dynamic>? ?? [];

    final spots = history
        .map((point) =>
        FlSpot(
          DateTime
              .parse(point['Date'])
              .millisecondsSinceEpoch
              .toDouble(),
          (point['Close'] ?? 0.0).toDouble(),
        ))
        .toList();

    final isLoss = spots.isNotEmpty && (spots.last.y < spots.first.y);
    final chartColor = isLoss ? Colors.red : Colors.green;

    return ListTile(
      title: Text(company),
      subtitle: Text(ticker),
      trailing: SizedBox(
        width: 70,
        height: 35,
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 1,
                color: chartColor,
                belowBarData: BarAreaData(
                  show: true,
                  color: chartColor.withOpacity(0.3),
                ),
                dotData: FlDotData(show: false),
              ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: false),
            lineTouchData: LineTouchData(enabled: false),
          ),
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssetDetailPage(ticker: asset['ticker']),
          ),
        );
      },
    );
  }

  Widget _buildEsgContent(TradeProvider tradeProvider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  sortByEsg = false;
                  sortAscending = !sortAscending;
                  tradeProvider.sortEsgData(sortAscending, sortByEsg);
                });
              },
              child: Text(
                !sortByEsg
                    ? (sortAscending ? 'Ordina per Nome \u2191' : 'Ordina per Nome \u2193')
                    : 'Ordina per Nome',
                style: const TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  sortByEsg = true;
                  sortAscending = !sortAscending;
                  tradeProvider.sortEsgData(sortAscending, sortByEsg);
                });
              },
              child: Text(
                sortByEsg
                    ? (sortAscending ? 'Ordina per ESG \u2191' : 'Ordina per ESG \u2193')
                    : 'Ordina per ESG',
                style: const TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
        Consumer<TradeProvider>(
          builder: (context, tradeProvider, _) {
            if (tradeProvider.isLoading) {
              return const CircularProgressIndicator();
            }

            if (tradeProvider.esgData.isEmpty) {
              return const Text('Nessun dato disponibile');
            }

            return Expanded(
              child: ListView.builder(
                itemCount: tradeProvider.esgData.length,
                itemBuilder: (context, index) {
                  final data = tradeProvider.esgData[index];
                  return ListTile(
                    title: Text(data['company']),
                    trailing: Text(data['esg'].toString()),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
