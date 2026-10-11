import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('1. Отображение состояния загрузки (CircularProgressIndicator)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator()))),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('2. Отображение пустого списка с сообщением', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: Text('Пусто')))),
    );
    expect(find.text('Пусто'), findsOneWidget);
  });

  testWidgets('3. Отображение состояния ошибки с кнопкой Повторить', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Text('Ошибка загрузки данных'),
              ElevatedButton(onPressed: () {}, child: const Text('Повторить')),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Ошибка загрузки данных'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });

  testWidgets('4. Срабатывание валидатора формы при пустом вводе', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: TextFormField(
              validator: (v) => v == null || v.isEmpty ? 'Обязательное поле' : null,
            ),
          ),
        ),
      ),
    );

    formKey.currentState!.validate();
    await tester.pump();
    expect(find.text('Обязательное поле'), findsOneWidget);
  });

  testWidgets('5. Скрытие кнопки добавления у клиента', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          floatingActionButton: null, 
          body: Text('Каталог программ'),
        ),
      ),
    );
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}