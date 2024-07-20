import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../providers/trade_provider.dart';

class AddTradeScreen extends StatefulWidget {
  const AddTradeScreen({super.key});

  @override
  _AddTradeScreenState createState() => _AddTradeScreenState();
}

class _AddTradeScreenState extends State<AddTradeScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTicker;
  String? _selectedTickerDisplay;
  double? _unitPrice;
  double? _quantity;
  DateTime? _selectedDate;
  Map<String, String> _supportedTickers = {};
  bool _isLoading = true;
  final TextEditingController _tickerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSupportedTickers();
  }

  Future<void> _fetchSupportedTickers() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:5000/trades/supported_tickers'));
    final data = json.decode(response.body) as Map<String, dynamic>;
    if (mounted) {
      setState(() {
        _supportedTickers = data.map((key, value) => MapEntry(key, value as String));
        _isLoading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final tradeData = {
        'ticker': _selectedTicker,
        'unit_price': _unitPrice,
        'quantity': _quantity,
        'date': _selectedDate?.toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/trades/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(tradeData),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          await Provider.of<TradeProvider>(context, listen: false).fetchTrades();
          Navigator.pop(context);
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

  void _presentDatePicker() {
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
        _selectedDate = pickedDate;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Aggiungi Trade',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildTickerSearchField(),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Prezzo dell\' asset'),
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  _unitPrice = double.parse(value!);
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
                  _quantity = double.parse(value!);
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
                      _selectedDate == null
                          ? 'Nessuna data selezionata!'
                          : 'Data: ${_selectedDate!.toLocal()}'.split(' ')[0],
                    ),
                  ),
                  TextButton(
                    onPressed: _presentDatePicker,
                    child: const Text(
                      'Scegli data',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                child: const Text('Conferma'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTickerSearchField() {
    return TypeAheadFormField<String>(
      textFieldConfiguration: TextFieldConfiguration(
        decoration: const InputDecoration(labelText: 'Ticker'),
        controller: _tickerController,
      ),
      suggestionsCallback: (pattern) async {
        return _supportedTickers.keys.where((String option) {
          return option.contains(pattern.toUpperCase());
        });
      },
      debounceDuration: const Duration(milliseconds: 300),
      itemBuilder: (context, String suggestion) {
        return ListTile(
          title: Text('$suggestion - ${_supportedTickers[suggestion]}'),
        );
      },
      onSuggestionSelected: (String suggestion) {
        setState(() {
          _selectedTicker = suggestion;
          _selectedTickerDisplay = '$suggestion - ${_supportedTickers[suggestion]}';
          _tickerController.text = _selectedTickerDisplay!;
        });
      },
      validator: (value) {
        if (_selectedTicker == null || !_supportedTickers.containsKey(_selectedTicker!)) {
          return 'Inserisci un ticker valido';
        }
        return null;
      },
    );
  }
}
