import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trade_provider.dart';

class EsgDataPopup extends StatefulWidget {
  @override
  _EsgDataPopupState createState() => _EsgDataPopupState();
}

class _EsgDataPopupState extends State<EsgDataPopup> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _formData = {
    'employees': 0,
    'altman': 0.0,
    'piotroski': 0.0,
    'decarbonization_target': {
      'target_year': 0,
      'comprehensiveness': 0.0,
      'ambition': 0.0,
      'temperature_goal': 0.0,
    },
    'involvement': {
      'Alcoholic Beverages': 'No',
      'Adult Entertainment': 'No',
      'Gambling': 'No',
      'Tobacco Products': 'No',
      'Animal Testing': 'No',
      'Fur and Specialty Leather': 'No',
      'Controversial Weapons': 'No',
      'Small Arms': 'No',
      'Catholic Values': 'No',
      'GMO': 'No',
      'Military Contracting': 'No',
      'Pesticides': 'No',
      'Thermal Coal': 'No',
      'Palm Oil': 'No',
    },
    'controversies': {
      'Environment': 'Green',
      'Social': 'Green',
      'Customers': 'Green',
      'Human Rights & Community': 'Green',
      'Labor Rights & Supply Chain': 'Green',
      'Governance': 'Green',
    },
    'sdgs': {
      'No Poverty': 'No',
      'No Hunger': 'No',
      'Good Health and Well-Being': 'No',
      'Quality Education': 'No',
      'Gender Equality': 'No',
      'Clean Water and Sanitation': 'No',
      'Affordable and Clean Energy': 'No',
      'Decent Work and Economic Growth': 'No',
      'Industry, Innovation and Infrastructure': 'No',
      'Reduced Inequalities': 'No',
      'Sustainable Cities and Communities': 'No',
      'Responsible Consumption and Production': 'No',
      'Climate Action': 'No',
      'Life under Water': 'No',
      'Life on Land': 'No',
      'Peace, Justice and Strong Institutions': 'No',
      'Partnerships for the Goals': 'No',
    },
  };
  double? _esgScore;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calculate ESG via Data'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNumberField('Number of employees', 'employees'),
              _buildNumberField('Altman Z-Score', 'altman', isDouble: true),
              _buildNumberField('Piotroski F-Score', 'piotroski', isDouble: true),
              const SizedBox(height: 20),
              //_buildDecarbonizationTargetFields(),
              const SizedBox(height: 20),
              //_buildInvolvementFields(),
              const SizedBox(height: 20),
              //_buildControversiesFields(),
              const SizedBox(height: 20),
              //_buildSdgsFields(),
              const SizedBox(height: 20),
              if (_esgScore != null)
                Text('ESG Score: $_esgScore', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: _calculateEsgScore,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text('Calculate', style: TextStyle(fontSize: 17)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(horizontal: 33, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text('Close', style: TextStyle(fontSize: 17)),
        ),
      ],
    );
  }

  Widget _buildNumberField(String label, String key, {bool isDouble = false}) {
    return TextFormField(
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      onSaved: (value) {
        if (isDouble) {
          _formData[key] = double.parse(value!);
        } else {
          _formData[key] = int.parse(value!);
        }
      },
      validator: (value) => value == null || value.isEmpty ? 'Enter valid $label' : null,
    );
  }

  Widget _buildDecarbonizationTargetFields() {
    return ExpansionTile(
      title: const Text('Decarbonization Target'),
      children: [
        _buildNumberField('Target Year', 'decarbonization_target.target_year'),
        _buildNumberField('Comprehensiveness (%)', 'decarbonization_target.comprehensiveness', isDouble: true),
        _buildNumberField('Ambition per annum (%)', 'decarbonization_target.ambition', isDouble: true),
        _buildNumberField('Temperature Goal', 'decarbonization_target.temperature_goal', isDouble: true),
      ],
    );
  }

  Widget _buildInvolvementFields() {
    return ExpansionTile(
      title: const Text('Involvement'),
      children: _formData['involvement'].keys.map<Widget>((key) {
        return _buildRadioGroup(key, 'involvement');
      }).toList(),
    );
  }

  Widget _buildControversiesFields() {
    return ExpansionTile(
      title: const Text('Controversies'),
      children: _formData['controversies'].keys.map<Widget>((key) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: _buildRadioGroup(key, 'controversies', options: ['Red', 'Orange', 'Yellow', 'Green']),
        );
      }).toList(),
    );
  }

  Widget _buildSdgsFields() {
    return ExpansionTile(
      title: const Text('Sustainable Development Goals (SDGs)'),
      children: _formData['sdgs'].keys.map<Widget>((key) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: _buildRadioGroup(key, 'sdgs', options: ['No', 'Aligned', 'Strongly Aligned']),
        );
      }).toList(),
    );
  }

  Widget _buildRadioGroup(String label, String groupKey, {List<String> options = const ['Yes', 'No']}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Column(
          children: options.map<Widget>((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: _formData[groupKey][label],
              onChanged: (value) {
                setState(() {
                  _formData[groupKey][label] = value;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _calculateEsgScore() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      final tradeProvider = Provider.of<TradeProvider>(context, listen: false);
      await tradeProvider.fetchDataEsgScore(context, _formData);
    }
  }
}
