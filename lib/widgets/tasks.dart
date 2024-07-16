import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importa il package provider per la gestione dello stato.

import '../providers/todo_provider.dart'; // Importa il provider TodoProvider che gestisce le operazioni CRUD per gli elementi Todo.

// Widget StatefulWidget che rappresenta l'interfaccia utente per gestire le attività Todo.
class TasksWidget extends StatefulWidget {
  const TasksWidget({Key? key}) : super(key: key);

  @override
  State<TasksWidget> createState() => _TasksWidgetState();
}

class _TasksWidgetState extends State<TasksWidget> {
  TextEditingController newTaskController = TextEditingController(); // Controller per gestire il campo di testo per il nuovo task.

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Riga contenente il campo di testo per aggiungere un nuovo task e il pulsante "Add".
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: newTaskController,
                  decoration: const InputDecoration(
                    labelText: 'New ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10,),
              ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.amberAccent), // Colore di sfondo del pulsante "Add".
                      foregroundColor: MaterialStateProperty.all(Colors.purple) // Colore del testo del pulsante "Add".
                  ),
                  child: const Text("Add"), // Testo del pulsante "Add".
                  onPressed: () {
                    // Quando si preme il pulsante "Add", chiama il metodo addTodo di TodoProvider per aggiungere un nuovo task.
                    Provider.of<TodoProvider>(context, listen: false).addTodo(newTaskController.text);
                    newTaskController.clear(); // Cancella il campo di testo dopo aver aggiunto il task.
                  }
              )
            ],
          ),
          // FutureBuilder per ottenere e visualizzare tutti i task.
          FutureBuilder(
            future: Provider.of<TodoProvider>(context, listen: false).getTodos, // Chiama il metodo getTodos di TodoProvider per ottenere i task.
            builder: (ctx, snapshot) =>
            snapshot.connectionState == ConnectionState.waiting
                ? const Center(child: CircularProgressIndicator()) // Mostra un indicatore di caricamento se i dati sono in caricamento.
                :
            Consumer<TodoProvider>(
              child: Center(
                heightFactor: MediaQuery.of(context).size.height * 0.03,
                child: const Text('You have no tasks.', style: TextStyle(fontSize: 18),), // Testo mostrato se non ci sono task.
              ),
              builder: (ctx, todoProvider, child) => todoProvider.items.isEmpty
                  ?  child as Widget // Se non ci sono task, mostra il child (il messaggio "You have no tasks.").
                  : Padding(
                padding: const EdgeInsets.only(top: 20),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: ListView.builder(
                      itemCount: todoProvider.items.length,
                      itemBuilder: (ctx, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: ListTile(
                          tileColor: Colors.black12, // Colore di sfondo della tile.
                          leading: Checkbox(
                              value: todoProvider.items[i].isExecuted, // Valore di check del Checkbox basato sullo stato isExecuted del Todo.
                              activeColor: Colors.purple, // Colore del Checkbox quando è attivo.
                              onChanged: (newValue) {
                                // Quando il Checkbox viene modificato, chiama executeTask di TodoProvider per aggiornare lo stato del task.
                                Provider.of<TodoProvider>(context, listen: false).executeTask(todoProvider.items[i].id);
                              }
                          ),
                          title: Text(todoProvider.items[i].itemName), // Mostra il nome del task.
                          trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red), // Icona per eliminare il task.
                              onPressed: () {
                                // Quando si preme l'icona di eliminazione, chiama deleteTodo di TodoProvider per eliminare il task.
                                Provider.of<TodoProvider>(context, listen: false).deleteTodo(todoProvider.items[i].id);
                              }
                          ),
                          onTap: () {},
                        ),
                      )
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
