import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

void main() {
  runWidget(MultiViewApp(viewBuilder: (context) => const MyApp()));
}

class MultiViewApp extends StatefulWidget {
  const MultiViewApp({super.key, required this.viewBuilder});

  final WidgetBuilder viewBuilder;

  @override
  State<MultiViewApp> createState() => _MultiViewAppState();
}

class _MultiViewAppState extends State<MultiViewApp>
    with WidgetsBindingObserver {
  Map<Object, Widget> _views = <Object, Widget>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateViews();
  }

  @override
  void didChangeMetrics() {
    _updateViews();
  }

  void _updateViews() {
    final newViews = <Object, Widget>{};

    for (final FlutterView view
        in WidgetsBinding.instance.platformDispatcher.views) {
      newViews[view.viewId] =
          _views[view.viewId] ??
          View(
            view: view,
            child: Builder(builder: widget.viewBuilder),
          );
    }

    setState(() {
      _views = newViews;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ViewCollection(views: _views.values.toList(growable: false));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  String? get token => web.window.localStorage.getItem('demo_auth_token');

  @override
  Widget build(BuildContext context) {
    final authToken = token;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xff101827),
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(32),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Flutter Web App',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      authToken == null || authToken.isEmpty
                          ? 'No auth token found.'
                          : 'Signed in with token:\n$authToken',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        web.window.localStorage.removeItem('demo_auth_token');
                        web.window.location.href = '/';
                      },
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
