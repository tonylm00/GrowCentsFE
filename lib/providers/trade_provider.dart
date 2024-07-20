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
}
