import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/todo_item.dart'; // Importa il modello TodoItem che presumibilmente rappresenta un'attività da fare.

// Questa classe gestisce la comunicazione con il server e la gestione degli elementi Todo.
class TodoProvider with ChangeNotifier {
  List<TodoItem> _items = []; // Lista privata di elementi Todo.
  final url = 'http://10.0.2.2:5000/todo'; // URL del server Flask dove sono gestiti gli elementi Todo.

  // Getter per ottenere una copia della lista privata _items.
  List<TodoItem> get items {
    return [..._items];
  }

  // Metodo per aggiungere un nuovo Todo al server.
  Future<void> addTodo(String task) async {
    if(task.isEmpty) { // Verifica che il nome del task non sia vuoto.
      return; // Esce immediatamente se il task è vuoto.
    }
    // Costruisce il corpo della richiesta con il nome del task e il flag per indicare se è stato eseguito.
    Map<String, dynamic> request = {"name": task, "is_executed": false};
    final headers = {'Content-Type': 'application/json'}; // Header per indicare che il corpo è JSON.
    // Effettua una richiesta POST al server per aggiungere il nuovo Todo.
    final response = await http.post(Uri.parse('$url/'), headers: headers, body: json.encode(request));
    // Decodifica la risposta JSON ricevuta dal server.
    Map<String, dynamic> responsePayload = json.decode(response.body);
    // Crea un nuovo oggetto TodoItem utilizzando i dati ricevuti e lo aggiunge alla lista locale _items.
    final todo = TodoItem(
        id: responsePayload["id"],
        itemName: responsePayload["name"],
        isExecuted: responsePayload["is_executed"]
    );
    _items.add(todo); // Aggiunge il nuovo Todo alla lista locale.
    notifyListeners(); // Notifica gli ascoltatori che i dati sono stati aggiornati.
  }

  // Metodo per ottenere tutti gli elementi Todo dal server.
  Future<void> get getTodos async {
    http.Response response; // Variabile per memorizzare la risposta HTTP.
    try {
      response = await http.get(Uri.parse(url)); // Effettua una richiesta GET per ottenere gli elementi Todo.
      List<dynamic> body = json.decode(response.body); // Decodifica la risposta JSON ricevuta.
      // Mappa ogni elemento della lista decodificata in un oggetto TodoItem e aggiungilo alla lista _items.
      _items = body.map((e) => TodoItem(
          id: e['id'],
          itemName: e['name'],
          isExecuted: e['is_executed']
      )).toList();
    } catch (e) {
      print(e); // Gestisce gli errori stampandoli sulla console.
    }
    notifyListeners(); // Notifica gli ascoltatori che i dati sono stati aggiornati.
  }

  // Metodo per eliminare un Todo dal server dato il suo ID.
  Future<void> deleteTodo(int todoId) async {
    http.Response response; // Variabile per memorizzare la risposta HTTP.
    try {
      response = await http.delete(Uri.parse("$url/$todoId")); // Effettua una richiesta DELETE al server per eliminare il Todo.
      final body = json.decode(response.body); // Decodifica la risposta JSON ricevuta.
      // Rimuove l'elemento dalla lista _items se l'eliminazione è avvenuta con successo.
      _items.removeWhere((element) => element.id == body["id"]);
    } catch (e) {
      print(e); // Gestisce gli errori stampandoli sulla console.
    }
    notifyListeners(); // Notifica gli ascoltatori che i dati sono stati aggiornati.
  }

  // Metodo per segnare un Todo come eseguito o non eseguito nel server.
  Future<void> executeTask(int todoId) async {
    try {
      final response = await http.patch(Uri.parse("$url/$todoId")); // Effettua una richiesta PATCH per aggiornare lo stato del Todo.
      Map<String, dynamic> responsePayload = json.decode(response.body); // Decodifica la risposta JSON ricevuta.
      // Aggiorna lo stato del Todo corrispondente nella lista _items con quello ricevuto dal server.
      _items.forEach((element) {
        if(element.id == responsePayload["id"]) {
          element.isExecuted = responsePayload["is_executed"]; // Aggiorna lo stato isExecuted del Todo.
        }
      });
    } catch (e) {
      print(e); // Gestisce gli errori stampandoli sulla console.
    }
    notifyListeners(); // Notifica gli ascoltatori che i dati sono stati aggiornati.
  }
}
