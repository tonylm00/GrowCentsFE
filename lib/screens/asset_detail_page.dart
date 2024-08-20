import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/trade_provider.dart';

class AssetDetailPage extends StatefulWidget {
  final String ticker;

  const AssetDetailPage({required this.ticker, Key? key}) : super(key: key);

  @override
  _AssetDetailPageState createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  String selectedPeriod = '1mo';
  Map<String, dynamic>? assetDetails;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAssetDetails();
  }

  Future<void> fetchAssetDetails() async {
    try {
      final response = await http.get(Uri.parse('http://10.0.2.2:5000/trades/asset_details/${widget.ticker}?period=$selectedPeriod'));

      if (response.statusCode == 200) {
        setState(() {
          assetDetails = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore nel caricamento dei dettagli dell\'asset')),
        );
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore nel caricamento dei dettagli dell\'asset')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : assetDetails == null
            ? const Center(child: Text('Nessun dato disponibile'))
            : SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                '${assetDetails!['company']} - ${assetDetails!['ticker']}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildPeriodButtons(),
              const SizedBox(height: 20),
              SizedBox(
                height: 300,
                child: _buildGraph(assetDetails!['history']),
              ),
              const SizedBox(height: 20),
              _buildCollapsibleTable(),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => _showAddTradeDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: const Text('Add Trade', style: TextStyle(fontSize: 17)),
                ),
              ),
            ],
          ),
        ),
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
              fetchAssetDetails();
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

  Widget _buildGraph(List<dynamic> history) {
    if (history.isEmpty) {
      return const Center(child: Text('Nessun dato disponibile'));
    }

    final spots = history.map((point) {
      final date = DateTime.parse(point['Date']).millisecondsSinceEpoch.toDouble();
      final closePrice = (point['Close'] ?? 0.0).toDouble();
      return FlSpot(date, closePrice);
    }).toList();

    final isLoss = spots.isNotEmpty && (spots.last.y < spots.first.y);
    final chartColor = isLoss ? Colors.red : Colors.green;

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 4,
            color: chartColor,
            belowBarData: BarAreaData(
              show: true,
              color: chartColor.withOpacity(0.25),
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
        ),
      ),
    );
  }

  Widget _buildCollapsibleTable() {
    final recentHistory = assetDetails!['history']
        .where((record) => DateTime.parse(record['Date']).isAfter(DateTime.now().subtract(const Duration(days: 30))))
        .toList();

    return ExpansionTile(
      title: const Text('Andamento mensile'),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 10,
            columns: const [
              DataColumn(label: Text('Data')),
              DataColumn(label: Text('Apertura')),
              DataColumn(label: Text('Chiusura')),
              DataColumn(label: Text('Minimo')),
              DataColumn(label: Text('Massimo')),
              DataColumn(label: Text('Volume')),
            ],
            rows: recentHistory.map<DataRow>((record) {
              return DataRow(
                cells: [
                  DataCell(Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(record['Date'])))),
                  DataCell(Text((record['Open'] as double).toStringAsFixed(2))),
                  DataCell(Text((record['Close'] as double).toStringAsFixed(2))),
                  DataCell(Text((record['Low'] as double).toStringAsFixed(2))),
                  DataCell(Text((record['High'] as double).toStringAsFixed(2))),
                  DataCell(Text(record['Volume'].toString())),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showAddTradeDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    double? unitPrice;
    double? quantity;
    DateTime? selectedDate;

    void _submitForm() async {
      if (formKey.currentState?.validate() ?? false) {
        formKey.currentState?.save();

        final tradeData = {
          'ticker': assetDetails!['ticker'],
          'unit_price': unitPrice,
          'quantity': quantity,
          'date': selectedDate?.toIso8601String(),
        };

        final response = await http.post(
          Uri.parse('http://10.0.2.2:5000/trades/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(tradeData),
        );

        if (response.statusCode == 200) {
          if (mounted) {
            await Provider.of<TradeProvider>(context, listen: false).fetchTrades();
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false); // Redirect to home page
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Errore nell\'aggiunta del trade')),
            );
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Trade'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text('Ticker: ${assetDetails!['ticker']}'),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Prezzo dell\' asset'),
                        keyboardType: TextInputType.number,
                        onSaved: (value) {
                          unitPrice = double.parse(value!);
                        },
                        validator: (value) {
                          if (value == null || double.tryParse(value) == null) {
                            return 'Inserisci un prezzo valido';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Quantità'),
                        keyboardType: TextInputType.number,
                        onSaved: (value) {
                          quantity = double.parse(value!);
                        },
                        validator: (value) {
                          if (value == null || double.tryParse(value) == null) {
                            return 'Inserisci una quantità valida';
                          }
                          return null;
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedDate == null
                                  ? 'Nessuna data selezionata!'
                                  : 'Data: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}',
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              ).then((pickedDate) {
                                if (pickedDate == null) {
                                  return;
                                }
                                setState(() {
                                  selectedDate = pickedDate;
                                });
                              });
                            },
                            child: const Text(
                              'Scegli data',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                  ),
                  child: const Text('Conferma'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
