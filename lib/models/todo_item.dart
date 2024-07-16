// Classe che rappresenta un singolo elemento Todo.
class TodoItem {
  dynamic id; // Identificatore univoco del task (può essere di qualsiasi tipo dinamico, come un numero o una stringa).
  String itemName; // Nome o descrizione del task.
  bool isExecuted; // Indica se il task è stato completato o meno.

  // Costruttore della classe TodoItem.
  TodoItem({this.id, required this.itemName, required this.isExecuted});
// 'required' indica che itemName e isExecuted sono parametri obbligatori per creare un'istanza di TodoItem.
}
