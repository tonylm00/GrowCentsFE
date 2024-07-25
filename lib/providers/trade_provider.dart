import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import '../models/trade.dart';

class TradeProvider with ChangeNotifier {
  double portfolioValue = 0.0;
  double portfolioChangePercentage = 0.0;
  List<FlSpot> graphData = [];
  List<Trade> trades = [];
  List<Map<String, dynamic>> topAssets = [];
  List<FlSpot> assetGraphData = [];
  List<Map<String, dynamic>> esgData = [];
  bool isLoading = false;

  Future<void> fetchPortfolioValue() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/trades/portfolio_value'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        portfolioValue = data['total_value'];
        double initialTotalValue = 0.0;
        for (var trade in trades) {
          initialTotalValue += trade.unitPrice * trade.quantity;
        }
        if (initialTotalValue > 0) {
          portfolioChangePercentage = ((portfolioValue - initialTotalValue) / initialTotalValue) * 100;
        } else {
          portfolioChangePercentage = 0.0;
        }
      } else {
        throw Exception('Failed to fetch portfolio value');
      }
    } catch (error) {
      print('Error fetching portfolio value: $error');
    }
    notifyListeners();
  }

  Future<void> fetchGraphData(String period) async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/trades/graph_data?period=$period'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        graphData = data.map<FlSpot>((point) {
          return FlSpot(
            DateTime.parse(point['Date']).millisecondsSinceEpoch.toDouble(),
            point['Close'].toDouble(),
          );
        }).toList();
      } else {
        throw Exception('Failed to fetch graph data');
      }
    } catch (error) {
      print('Error fetching graph data: $error');
    }
    notifyListeners();
  }

  Future<void> fetchTrades() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/trades'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        trades = data.map((tradeJson) => Trade.fromJson(tradeJson)).toList();
        await fetchPortfolioValue();
      } else {
        throw Exception('Failed to fetch trades');
      }
    } catch (error) {
      print('Error fetching trades: $error');
    }
    notifyListeners();
  }

  Future<void> fetchTopAssets() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/trades/top_assets'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        topAssets = data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch top assets');
      }
    } catch (error) {
      print('Error fetching top assets: $error');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> fetchGraphDataForAsset(String ticker, String period) async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/trades/graph_data?ticker=$ticker&period=$period'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        assetGraphData = data.map<FlSpot>((point) {
          return FlSpot(
            DateTime.parse(point['Date']).millisecondsSinceEpoch.toDouble(),
            point['Close'].toDouble(),
          );
        }).toList();
      } else {
        throw Exception('Failed to fetch graph data for asset');
      }
    } catch (error) {
      print('Error fetching graph data for asset: $error');
    }
    notifyListeners();
  }

  Future<bool> addTrade(Map<String, dynamic> newTrade) async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/trades/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(newTrade),
      );

      if (response.statusCode == 200) {
        final trade = Trade.fromJson(json.decode(response.body));
        trades.add(trade);
        await fetchPortfolioValue();
        notifyListeners();
        return true;
      } else {
        throw Exception('Failed to add trade');
      }
    } catch (error) {
      print('Error adding trade: $error');
      return false;
    }
  }

  Future<double> fetchCurrentPrice(String ticker) async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/trades/current_price?ticker=$ticker'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['price'].toDouble();
      } else {
        throw Exception('Failed to fetch current price');
      }
    } catch (error) {
      print('Error fetching current price: $error');
      return 0.0;
    }
  }

  Future<void> deleteTrade(int id) async {
    try {
      final response = await http.delete(Uri.parse('http://10.0.2.2:5000/trades/$id'));
      if (response.statusCode == 200) {
        trades.removeWhere((trade) => trade.id == id);
        await fetchPortfolioValue();
      } else {
        throw Exception('Failed to delete trade');
      }
    } catch (error) {
      print('Error deleting trade: $error');
    }
    notifyListeners();
  }

  Future<void> fetchDataEsgScore(BuildContext context, Map<String, dynamic> data) async {
    final url = Uri.parse('http://10.0.2.2:5000/esg/predict/data');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode(data);

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final esgScore = jsonResponse['esg'];
        _showEsgResult(context, esgScore);
      } else {
        throw Exception('Failed to fetch ESG score');
      }
    } catch (error) {
      print('Error fetching ESG score: $error');
      _showErrorDialog(context, 'Failed to fetch ESG score');
    }
  }

  Future<void> fetchEsgData() async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/esg/scores'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List;
        esgData = data.cast<Map<String, dynamic>>();
        print('DATI ESG: $esgData');  // Stampa di debug per verificare i dati ricevuti
      } else {
        throw Exception('Failed to fetch ESG data');
      }
    } catch (error) {
      print('Error fetching ESG data: $error');
    }

    isLoading = false;
    notifyListeners();
  }

  void sortEsgData(bool ascending, bool sortByEsg) {
    esgData.sort((a, b) {
      if (sortByEsg) {
        return ascending ? a['esg'].compareTo(b['esg']) : b['esg'].compareTo(a['esg']);
      } else {
        return ascending ? a['company'].compareTo(b['company']) : b['company'].compareTo(a['company']);
      }
    });
    notifyListeners();
  }

  void _showEsgResult(BuildContext context, double esgScore) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ESG Score'),
        content: Text('The calculated ESG score is: $esgScore'),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }
}
