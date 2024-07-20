import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/trade.dart';
import '../providers/trade_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedPeriod = '1mo';
  int? touchedIndex;

  @override
  void initState() {
    super.initState();
    final tradeProvider = Provider.of<TradeProvider>(context, listen: false);
    tradeProvider.fetchTrades();
    tradeProvider.fetchGraphData(selectedPeriod);
  }

  @override
  Widget build(BuildContext context) {
    final tradeProvider = Provider.of<TradeProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40), // To leave space for the fixed button
                  const Text(
                    'Capitale',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${tradeProvider.portfolioValue.toStringAsFixed(2)} €',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${tradeProvider.portfolioChangePercentage.toStringAsFixed(2)} %',
                    style: TextStyle(
                      fontSize: 24,
                      color: tradeProvider.portfolioChangePercentage >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPeriodButtons(),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
                    child: _buildGraph(tradeProvider.graphData),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Posizioni aperte',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Stocks, ETFs & Bonds',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  _buildInvestmentsList(tradeProvider),
                  const SizedBox(height: 20),
                  _buildPieChart(tradeProvider),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(0.1), // Smaller padding for smaller border
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 3,
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/mifid');
                },
                icon: const Icon(
                  Icons.person,
                  color: Colors.black,
                  size: 25, // Smaller icon size
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/browse');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // More rounded border
                    ),
                  ),
                  child: const Text('Esplora', style: TextStyle(fontSize: 17)), // Larger text
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/add_trade');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // More rounded border
                    ),
                  ),
                  child: const Text('Transfer', style: TextStyle(fontSize: 17)), // Larger text
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodButtons() {
    final periods = ['1mo', '3mo', '6mo', '1y', 'max'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: periods.map((period) {
        return ElevatedButton(
          onPressed: () {
            setState(() {
              selectedPeriod = period;
              Provider.of<TradeProvider>(context, listen: false).fetchGraphData(selectedPeriod);
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedPeriod == period ? Colors.black : Colors.grey,
          ),
          child: Text(period),
        );
      }).toList(),
    );
  }

  Widget _buildGraph(List<FlSpot> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final interval = data.length > 1 ? (data.last.x - data.first.x) / 3 : 1.0;

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            barWidth: 4,
            color: Colors.green,
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withOpacity(0.25),
            ),
            dotData: FlDotData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                final formattedDate = '${date.day}/${date.month}';
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              },
              interval: interval,
            ),
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
        borderData: FlBorderData(
          show: false,
        ),
        gridData: FlGridData(
          show: false,
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.black.withOpacity(0.7),
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                const textStyle = TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                );
                final date = DateTime.fromMillisecondsSinceEpoch(touchedSpot.x.toInt());
                final formattedDate = '${date.day}/${date.month}/${date.year}';
                return LineTooltipItem(
                  '${touchedSpot.y.toStringAsFixed(2)} €\n$formattedDate',
                  textStyle,
                );
              }).toList();
            },
          ),
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (response == null || response.lineBarSpots == null) {
              return;
            }
          },
        ),
      ),
    );
  }

  Widget _buildInvestmentsList(TradeProvider tradeProvider) {
    final groupedTrades = <String, List<Trade>>{};
    for (var trade in tradeProvider.trades) {
      if (!groupedTrades.containsKey(trade.ticker)) {
        groupedTrades[trade.ticker] = [];
      }
      groupedTrades[trade.ticker]!.add(trade);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groupedTrades.length,
      itemBuilder: (context, index) {
        final ticker = groupedTrades.keys.elementAt(index);
        final trades = groupedTrades[ticker]!;
        final totalQuantity = trades.fold(0.0, (sum, trade) => sum + trade.quantity);
        final averagePrice = trades.fold(0.0, (sum, trade) => sum + (trade.unitPrice * trade.quantity)) / totalQuantity;

        return FutureBuilder<double>(
          future: tradeProvider.fetchCurrentPrice(ticker),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const ListTile(
                title: Text('Loading...'),
              );
            } else if (snapshot.hasError) {
              return const ListTile(
                title: Text('Error loading price'),
              );
            } else {
              final currentPrice = snapshot.data!;
              final priceChange = ((currentPrice - averagePrice) / averagePrice) * 100;

              return ListTile(
                title: Text(ticker),
                subtitle: Text(trades.first.company),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${currentPrice.toStringAsFixed(2)} €',
                      style: TextStyle(
                        color: currentPrice >= averagePrice ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      '${priceChange.toStringAsFixed(2)} %',
                      style: TextStyle(
                        color: priceChange >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  _showTradeDetails(context, trades);
                },
              );
            }
          },
        );
      },
    );
  }

  void _showTradeDetails(BuildContext context, List<Trade> trades) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Posizioni aperte per ${trades.first.ticker}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: trades.length,
              itemBuilder: (context, index) {
                final trade = trades[index];
                final formattedDate = DateFormat('dd/MM/yyyy').format(trade.date);
                return Dismissible(
                  key: Key(trade.id.toString()),
                  onDismissed: (direction) {
                    Provider.of<TradeProvider>(context, listen: false).deleteTrade(trade.id);
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text('${trade.type} - Trade del: $formattedDate'),
                    subtitle: Text(' € ${trade.unitPrice} X ${trade.quantity} = ${trade.quantity * trade.unitPrice} €'),
                  ),
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              child: const Text(
                'Chiudi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPieChart(TradeProvider tradeProvider) {
    final stocksTotal = tradeProvider.trades
        .where((trade) => trade.type == 'Stocks')
        .fold(0.0, (sum, trade) => sum + (trade.unitPrice * trade.quantity));
    final etfsTotal = tradeProvider.trades
        .where((trade) => trade.type == 'ETFs')
        .fold(0.0, (sum, trade) => sum + (trade.unitPrice * trade.quantity));
    final bondsTotal = tradeProvider.trades
        .where((trade) => trade.type == 'Bonds')
        .fold(0.0, (sum, trade) => sum + (trade.unitPrice * trade.quantity));

    final total = stocksTotal + etfsTotal + bondsTotal;

    if (total == 0) {
      return const Center(child: Text('Dati insufficienti per il grafico a torta!'));
    }

    final sections = <PieChartSectionData>[];

    if (stocksTotal > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.lightGreen,
          value: (stocksTotal / total) * 100,
          title: '${(stocksTotal / total * 100).toStringAsFixed(1)}%',
          radius: touchedIndex == 0 ? 60 : 50,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    if (etfsTotal > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.green,
          value: (etfsTotal / total) * 100,
          title: '${(etfsTotal / total * 100).toStringAsFixed(1)}%',
          radius: touchedIndex == 1 ? 60 : 50,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    if (bondsTotal > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.green[900],
          value: (bondsTotal / total) * 100,
          title: '${(bondsTotal / total * 100).toStringAsFixed(1)}%',
          radius: touchedIndex == 2 ? 60 : 50,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
                  setState(() {
                    if (pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                      touchedIndex = -1;
                      return;
                    }
                    touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Stocks', Colors.lightGreen),
        _buildLegendItem('ETFs', Colors.green),
        _buildLegendItem('Bonds', Colors.green[900]!),
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(title),
      ],
    );
  }
}
