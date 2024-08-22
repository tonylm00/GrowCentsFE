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
        padding: const EdgeInsets.all(20.0),
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
                assetDetails!['company'],
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                assetDetails!['ticker'],
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              _buildCurrentPriceAndChange(),
              const SizedBox(height: 20),
              _buildPeriodButtons(),
              const SizedBox(height: 20),
              SizedBox(
                height: 190,
                child: _buildGraph(assetDetails!['history']),
              ),
              const SizedBox(height: 20),
              _buildCompanyDetails(),
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
                  child: const Text('Aggiungi al portafoglio', style: TextStyle(fontSize: 17)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPriceAndChange() {
    if (assetDetails == null || assetDetails!['history'].isEmpty) {
      return const SizedBox.shrink();
    }

    // Estrai il prezzo corrente e il prezzo all'inizio del periodo selezionato
    final history = assetDetails!['history'];
    final currentPrice = history.last['Close'];
    final initialPrice = history.first['Close'];
    final changePercentage = ((currentPrice - initialPrice) / initialPrice) * 100;

    final isPositiveChange = changePercentage >= 0;
    final changeColor = isPositiveChange ? Colors.green : Colors.red;
    final changeSymbol = isPositiveChange ? '+' : '';

    return Row(
      children: [
        Text(
          'Valore corrente: ${currentPrice.toStringAsFixed(2)} €',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        Text(
          '($changeSymbol${changePercentage.toStringAsFixed(2)}%)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: changeColor),
        ),
      ],
    );
  }


  Widget _buildPeriodButtons() {
    final periods = ['1mo', '6mo', '1y', '2y', '5y'];
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
      title: const Text('Ultimi dati finanziari'),
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

  Widget _buildCompanyDetails() {
    final companyOfficers = assetDetails!['companyOfficers'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCompanyDetailsCollapse(),
        const SizedBox(height: 10),
        _buildDescriptionTile(),
        const SizedBox(height: 10),
        _buildOfficersTile(companyOfficers),

      ],
    );
  }


  Widget _buildCompanyDetailsCollapse() {
    final rows = [
      _buildDataRow('Città', assetDetails!['city']),
      _buildDataRow('Paese', assetDetails!['country']),
      _buildDataRow('Codice postale', assetDetails!['zip']),
      _buildDataRow('Settore', assetDetails!['sector']),
      _buildDataRow('Industria', assetDetails!['industry']),
      _buildDataRow('Dipendenti', assetDetails!['fullTimeEmployees']?.toString()),
      _buildDataRow('Rischio Audit', _formatRiskValue(assetDetails!['auditRisk'])),
      _buildDataRow('Rischio Consiglio di Amministrazione', _formatRiskValue(assetDetails!['boardRisk'])),
    ];

    // Filtra le righe che non hanno valore N/A o null
    final filteredRows = rows.where((row) => row != null).toList();

    // Se tutte le righe sono N/A o null, non mostrare il collapse
    if (filteredRows.isEmpty) {
      return const SizedBox.shrink(); // Restituisce uno spazio vuoto se non ci sono dati da mostrare
    }

    return ExpansionTile(
      title: const Text(
        'Dettagli dell\'azienda',
        style: TextStyle(fontSize: 16),
      ),
      children: [
        DataTable(
          columnSpacing: 10,
          columns: const [
            DataColumn(label: SizedBox()),
            DataColumn(label: SizedBox()),
          ],
          rows: filteredRows.cast<DataRow>(), // Cast a DataRow dopo il filtraggio
        ),
      ],
    );
  }

  DataRow? _buildDataRow(String label, String? value) {
    if (value == null || value == 'N/A') return null;
    return DataRow(
      cells: [
        DataCell(Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        DataCell(Text(value)),
      ],
    );
  }

  String _formatRiskValue(dynamic value) {
    if (value != null && value != 'N/A') {
      return '$value su 10';
    } else {
      return 'N/A';
    }
  }


  Widget _buildOfficersTile(List<dynamic> companyOfficers) {
    // Filtra i dirigenti che hanno valori non nulli e non N/A
    final filteredOfficers = companyOfficers.where((officer) =>
    officer['name'] != null &&
        officer['name'] != 'N/A' &&
        officer['title'] != null &&
        officer['title'] != 'N/A').toList();

    // Se non ci sono dirigenti validi, non visualizzare nulla
    if (filteredOfficers.isEmpty) {
      return const SizedBox.shrink();
    }

    return ExpansionTile(
      title: const Text(
        'Dirigenti',
        style: TextStyle(fontSize: 16),
      ),
      children: filteredOfficers.map((officer) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${officer['name']}'),
          subtitle: Text('${officer['title']} (${officer['yearBorn'] ?? 'N/A'})'),
        );
      }).toList(),
    );
  }


  Widget _buildDescriptionTile() {
    final description = assetDetails!['longBusinessSummary'];
    if (description == null || description == 'N/A') return const SizedBox.shrink();

    return ExpansionTile(
      title: const Text(
        'Descrizione ufficiale',
        style: TextStyle(fontSize: 16),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(description),
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
            Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
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
              title: const Text('Aggiungi al portafoglio'),
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
