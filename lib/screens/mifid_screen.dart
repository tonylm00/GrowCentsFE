import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mifid_provider.dart';

class MifidScreen extends StatefulWidget {
  const MifidScreen({super.key});

  @override
  _MifidScreenState createState() => _MifidScreenState();
}

class _MifidScreenState extends State<MifidScreen> {
  final Map<String, int> _answers = {};
  bool _lastQuestionNo = false;

  void _submitAnswers() {
    if (_answers.length < 12 || _answers.values.contains(null)) {
      _showAlert();
    } else if (_lastQuestionNo) {
      _showAlert();
    } else {
      Provider.of<MifidProvider>(context, listen: false).executeMifid(_answers).then((_) {
        final result = Provider.of<MifidProvider>(context, listen: false).result;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Risultato MiFID'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Profilo di rischio: ${result!.riskProfile}'),
                Text('Allocazione degli asset: ${result.assetAllocation}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }

  void _showAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Errore'),
        content: const Text('Per favore, fornisci informazioni accurate e completa il questionario.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const Text(
              'Questionario MiFID',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildInfoSection(),
            const SizedBox(height: 20),
            _buildQuestionSection('Situazione finanziaria', [
              _buildQuestion('1. Reddito annuale lordo:', [
                'Meno di 25.000 €',
                'Tra 25.000 € e 50.000 €',
                'Tra 50.000 € e 100.000 €',
                'Oltre 100.000 €'
              ]),
              _buildQuestion('2. Patrimonio netto (escludendo la residenza principale):', [
                'Meno di 50.000 €',
                'Tra 50.000 € e 100.000 €',
                'Tra 100.000 € e 500.000 €',
                'Oltre 500.000 €'
              ]),
              _buildQuestion('3. Esperienza di investimento (in anni):', [
                'Nessuna esperienza',
                'Meno di 2 anni',
                'Tra 2 e 5 anni',
                'Oltre 5 anni'
              ]),
            ]),
            _buildQuestionSection('Obiettivi di investimento', [
              _buildQuestion('1. Qual è il tuo principale obiettivo di investimento?', [
                'Conservazione del capitale',
                'Generazione di reddito',
                'Crescita del capitale',
                'Speculazione'
              ]),
              _buildQuestion('2. Qual è il tuo orizzonte temporale di investimento?', [
                'Meno di 1 anno',
                'Tra 1 e 3 anni',
                'Tra 3 e 5 anni',
                'Oltre 5 anni'
              ]),
            ]),
            _buildQuestionSection('Conoscenza ed esperienza', [
              _buildQuestion('1. Quali tipi di strumenti finanziari conosci?', [
                'Solo azioni e obbligazioni',
                'Azioni, obbligazioni e fondi comuni di investimento',
                'Azioni, obbligazioni, fondi comuni di investimento ed ETF',
                'Strumenti complessi come derivati e forex'
              ]),
              _buildQuestion('2. Con quale frequenza effettui operazioni finanziarie?', [
                'Mai',
                'Meno di una volta all\'anno',
                'Una o due volte all\'anno',
                'Più di due volte all\'anno'
              ]),
            ]),
            _buildQuestionSection('Tolleranza al rischio', [
              _buildQuestion('1. Come ti sentiresti se il valore del tuo portafoglio di investimenti diminuisse del 10% in un breve periodo?', [
                'Molto preoccupato',
                'Moderatamente preoccupato',
                'Leggermente preoccupato',
                'Non preoccupato'
              ]),
              _buildQuestion('2. Saresti disposto a rischiare una parte del tuo capitale per ottenere potenzialmente rendimenti più elevati?', [
                'No',
                'Sì, ma solo una piccola parte (fino al 10%)',
                'Sì, una parte moderata (fino al 25%)',
                'Sì, una parte significativa (oltre il 25%)'
              ]),
            ]),
            _buildQuestionSection('Profilo dell\'investitore', [
              _buildQuestion('1. Come descriveresti la tua conoscenza degli investimenti e del mercato finanziario?', [
                'Principiante',
                'Intermedio',
                'Avanzato',
                'Esperto'
              ]),
              _buildQuestion('2. Hai mai investito in strumenti complessi come derivati o forex?', [
                'No',
                'Sì, occasionalmente',
                'Sì, frequentemente',
                'Sì, molto frequentemente'
              ]),
            ]),
            _buildQuestionSection('Conferma', [
              _buildQuestion('Confermo che le informazioni fornite sono accurate e complete.', [
                'Sì',
                'No'
              ]),
            ]),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitAnswers,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
              ),
              child: const Text('Conferma'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionSection(String title, List<Widget> questions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...questions,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildQuestion(String question, List<String> answers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
        Column(
          children: answers.asMap().entries.map((entry) {
            int idx = entry.key;
            String answer = entry.value;
            return RadioListTile(
              title: Text(answer),
              value: idx,
              groupValue: _answers[question],
              onChanged: (value) {
                setState(() {
                  _answers[question] = value as int;
                  if (question == 'Confermo che le informazioni fornite sono accurate e complete.' && value == 1) {
                    _lastQuestionNo = true;
                  } else {
                    _lastQuestionNo = false;
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10.0),
      child: Image.asset(
        'assets/images/mifid.jpg',
        height: 150,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}
