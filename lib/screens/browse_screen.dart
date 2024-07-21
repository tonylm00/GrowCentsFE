import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/asset.dart';
import '../providers/trade_provider.dart';
import '../providers/blog_provider.dart';
import 'article_detail_page.dart';

class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key});

  @override
  _BrowsePageState createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  String searchQuery = '';
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BlogProvider>(context, listen: false).fetchBlogPosts();
      Provider.of<TradeProvider>(context, listen: false).fetchTopAssets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tradeProvider = Provider.of<TradeProvider>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 40), // To leave space for the fixed button
            const Text(
              'Esplora',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search for assets',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 20),
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
          return const Center(child: Text('No articles available'));
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
              trailing: blogPost.viewed ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => ArticleDetailPage(blogPost: blogPost),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.ease;

                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(seconds: 1),
                  ),
                ).then((_) {
                  Provider.of<BlogProvider>(context, listen: false).markAsViewed(blogPost);
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
      return const Center(child: Text('No assets available'));
    }

    final stocks = tradeProvider.topAssets.where((asset) => Asset.STOCKS.contains(asset['ticker'])).toList();
    final etfs = tradeProvider.topAssets.where((asset) => Asset.ETFS.contains(asset['ticker'])).toList();
    final bonds = tradeProvider.topAssets.where((asset) => Asset.BONDS.contains(asset['ticker'])).toList();

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Stocks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        ...stocks.map((asset) => _buildAssetListTile(asset)).toList(),
        const Divider(thickness: 1, color: Colors.grey),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text('ETFs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        ...etfs.map((asset) => _buildAssetListTile(asset)).toList(),
        const Divider(thickness: 1, color: Colors.grey),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Bonds', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        ...bonds.map((asset) => _buildAssetListTile(asset)).toList(),
      ],
    );
  }

  Widget _buildAssetListTile(Map<String, dynamic> asset) {
    final company = asset['company'] ?? 'Unknown';
    final ticker = asset['ticker'] ?? 'N/A';
    final history = asset['history'] as List<dynamic>? ?? [];

    final spots = history
        .map((point) => FlSpot(
      DateTime.parse(point['Date']).millisecondsSinceEpoch.toDouble(),
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
        // Implement navigation to asset details
      },
    );
  }



  Widget _buildEsgContent(TradeProvider tradeProvider) {
    return ListView.builder(
      itemCount: 10, // Sostituisci con il numero reale di articoli ESG
      itemBuilder: (context, index) {
        return ListTile(
          title: Text('ESG Article ${index + 1}'),
          subtitle: Text('Description of ESG Article ${index + 1}'),
          onTap: () {
            // Implementa la navigazione ai dettagli dell'articolo ESG
          },
        );
      },
    );
  }
}