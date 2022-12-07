import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_loader/main.dart';

final text1 = "jo".toUint8List();
final text2 = "teddy".toUint8List();

extension ToList on String {
  Uint8List toUint8List() => Uint8List.fromList(codeUnits);
}

enum Error { dummy }

void main() {
  group(
    "app_bloc_test",
    (() {
      blocTest<AppBloc, AppState>(
        "initial state of the bloc",
        build: (() => AppBloc(urls: images)),
        verify: (bloc) => expect(
          bloc.state,
          const AppState.empty(),
        ),
      );
      blocTest(
        "testing the ability of loading1 url",
        build: (() => AppBloc(
              urls: [],
              urlPicker: (_) => '',
              urlLoader: (url) => Future.value(text1),
            )),
        act: (bloc) => bloc.add(const ImageLoadAction()),
        expect: () => [
          const AppState(
            isLoading: true,
            error: null,
            data: null,
          ),
          AppState(isLoading: false, error: null, data: text1),
        ],
      );
      blocTest(
        "throwing and catching error on urlLoader",
        build: (() => AppBloc(
              urls: [],
              urlPicker: (_) => '',
              urlLoader: (url) => Future.error(Error.dummy),
            )),
        act: (bloc) => bloc.add(const ImageLoadAction()),
        expect: () => [
          const AppState(
            isLoading: true,
            error: null,
            data: null,
          ),
          const AppState(
            isLoading: false,
            error: Error.dummy,
            data: null,
          ),
        ],
      );
      blocTest(
        "testing the ability of loading morethan one url",
        build: (() => AppBloc(
              urls: [],
              urlPicker: (_) => '',
              urlLoader: (url) => Future.value(text2),
            )),
        act: (bloc) {
          bloc.add(const ImageLoadAction());
          bloc.add(const ImageLoadAction());
        },
        expect: () => [
          const AppState(
            isLoading: true,
            error: null,
            data: null,
          ),
          AppState(isLoading: false, error: null, data: text2),
          const AppState(
            isLoading: true,
            error: null,
            data: null,
          ),
          AppState(isLoading: false, error: null, data: text2),
        ],
      );
    }),
  );
}
