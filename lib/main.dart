import 'package:flutter/material.dart';
import 'package:flutter_growcents/providers/blog_provider.dart';
import 'package:flutter_growcents/screens/browse_screen.dart';
import 'package:provider/provider.dart';
import 'providers/mifid_provider.dart';
import 'providers/trade_provider.dart';
import 'screens/home_screen.dart';
import 'screens/mifid_screen.dart';
import 'screens/add_trade_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MifidProvider()),
        ChangeNotifierProvider(create: (context) => TradeProvider()),
        ChangeNotifierProvider(create: (context) => BlogProvider()),

      ],
      child: MaterialApp(
        title: 'Personal Finance App',
        home: const HomeScreen(),
        routes: {
          '/mifid': (context) => const MifidScreen(),
          '/add_trade': (context) => const AddTradeScreen(),
          '/browse': (context) => const BrowsePage(),

        },
      ),
    );
  }
}
