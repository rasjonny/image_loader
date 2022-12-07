import 'dart:developer';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:async/async.dart' show StreamGroup;

void main() {
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: const HomePage(),
    ),
  );
}

abstract class LoadAction {
  const LoadAction();
}

class ImageLoadAction extends LoadAction {
  const ImageLoadAction();
}

class AppState {
  final bool isLoading;
  final Object? error;
  final Uint8List? data;

  const AppState({
    required this.isLoading,
    required this.error,
    required this.data,
  });

  const AppState.empty()
      : data = null,
        error = null,
        isLoading = false;

  @override
  bool operator ==(covariant AppState other) =>
      isLoading == other.isLoading &&
      (data ?? []).isEqualto(other.data ?? []) &&
      error == other.error;

  @override
  String toString() {
    return {
      'isLoading': isLoading,
      'hasData': data != null,
      'error': error,
    }.toString();
  }

  @override
  int get hashCode => Object.hash(isLoading, error, data);
}

extension RandomUrlPicker<T> on Iterable<T> {
  T getRandomUrl(Iterable<T> urls) {
    return elementAt(math.Random().nextInt(length));
  }
}

typedef UrlPicker = String Function(Iterable<String>);
typedef UrlLoader = Future<Uint8List> Function(String url);

class AppBloc extends Bloc<ImageLoadAction, AppState> {
  String _pickUrl(Iterable<String> urls) => urls.getRandomUrl(urls);
  Future<Uint8List> _loadUrl(String url) =>
      NetworkAssetBundle(Uri.parse(url)).load(url).then(
            (byte) => byte.buffer.asUint8List(),
          );
  AppBloc({
    required Iterable<String> urls,
    Duration? waitBeforeLoading,
    UrlLoader? urlLoader,
    UrlPicker? urlPicker,
  }) : super(const AppState.empty()) {
    on<ImageLoadAction>((event, emit) async {
      emit(
        const AppState(
          isLoading: true,
          error: null,
          data: null,
        ),
      );
      try {
        if (waitBeforeLoading != null) {
          await Future.delayed(waitBeforeLoading);
        }
        final url = (urlPicker ?? _pickUrl)(urls);

        final data = await (urlLoader ?? _loadUrl)(url);

        emit(AppState(isLoading: false, error: null, data: data));
      } catch (e) {
        emit(AppState(isLoading: false, error: e, data: null));
      }
    });
  }
}

class TopBloc extends AppBloc {
  TopBloc({
    required Iterable<String> urls,
    Duration? waitBeforeLoading,
  }) : super(
          urls: urls,
          waitBeforeLoading: waitBeforeLoading,
        );
}

class BottomBloc extends AppBloc {
  BottomBloc({
    Duration? waitBeforeLoading,
    required Iterable<String> urls,
  }) : super(
          urls: urls,
          waitBeforeLoading: waitBeforeLoading,
        );
}

const images = [
  'https://bit.ly/3x7J5Qt',
  'https://bit.ly/3ywI8l6',
  'https://bit.ly/3wnASpW',
];

extension StartWith<T> on Stream<T> {
  Stream<T> startWith(T value) {
    return StreamGroup.merge([this, Stream<T>.value(value)]);
  }
}

class AppBlocView<T extends AppBloc> extends StatelessWidget {
  const AppBlocView({super.key});

  void startUpdating(BuildContext context) {
    Stream.periodic(
      const Duration(seconds: 10),
      ((_) => const ImageLoadAction()),
    ).startWith(const ImageLoadAction()).forEach((imageLoadAction) {
      context.read<T>().add(imageLoadAction);
    });
  }

  @override
  Widget build(BuildContext context) {
    startUpdating(context);
    return Expanded(
      child: BlocBuilder<T, AppState>(
        builder: (context, state) {
          log(state.toString());

          if (state.data != null) {
            final data = state.data;
            return Expanded(
              child: Column(
                children: [
                  Image.memory(
                    data!,
                    fit: BoxFit.fitHeight,
                  ),
                ],
              ),
            );
          } else if (state.error != null) {
            final error = state.error.toString();
            return Text(error);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

extension Comaparison<E> on List<E> {
  bool isEqualto(List<E> other) {
    if (identical(this, other)) {
      return true;
    }
    if (length != other.length) {
      return false;
    }
    for (var i = 0; i < length; i++) {
      if (this[i] != other[i]) {
        return false;
      }
    }
    return true;
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: ((context) => TopBloc(
                  urls: images,
                  waitBeforeLoading: const Duration(seconds: 5),
                )),
          ),
          BlocProvider(
            create: ((context) => BottomBloc(
                  urls: images,
                  waitBeforeLoading: const Duration(seconds: 5),
                )),
          ),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: const [
            AppBlocView<TopBloc>(),
            AppBlocView<BottomBloc>(),
          ],
        ),
      ),
    );
  }
}
