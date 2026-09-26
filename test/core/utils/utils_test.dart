import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veribus/core/utils/app_failure.dart';
import 'package:veribus/core/utils/money.dart';
import 'package:veribus/core/utils/validators.dart';
import 'package:veribus/extensions/app_failure_extensions.dart';
import 'package:veribus/l10n/gen/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn();

  group('Validators', () {
    test('email', () {
      final v = Validators.email(l10n);
      expect(v(''), l10n.validationRequired);
      expect(v('nope'), l10n.validationEmail);
      expect(v(' a@b.co '), isNull);
    });

    test('password needs 8 chars, a letter and a digit', () {
      final v = Validators.password(l10n);
      expect(v('abc123'), l10n.validationPassword);
      expect(v('abcdefgh'), l10n.validationPassword);
      expect(v('abcdefg1'), isNull);
    });

    test('matches', () {
      expect(Validators.matches(l10n, () => 'x')('y'), l10n.validationPasswordsMatch);
      expect(Validators.matches(l10n, () => 'x')('x'), isNull);
    });
  });

  group('AppFailure.from', () {
    DioException dio({int? status, DioExceptionType type = DioExceptionType.badResponse, Object? data}) {
      final options = RequestOptions(path: '/x');
      return DioException(
        requestOptions: options,
        type: type,
        response: status == null ? null : Response(requestOptions: options, statusCode: status, data: data),
      );
    }

    test('maps HTTP and network errors', () {
      expect(AppFailure.from(dio(status: 401)), isA<UnauthorizedFailure>());
      expect(AppFailure.from(dio(type: DioExceptionType.connectionError)), isA<NetworkFailure>());
      final server = AppFailure.from(dio(status: 422, data: {'message': 'Bad input'}));
      expect(server.message(l10n), 'Bad input');
      expect(server.isUnexpected, isFalse);
      expect(AppFailure.from(dio(status: 500)).isUnexpected, isTrue);
    });

    test('keeps AppFailures and wraps the rest', () {
      const failure = AuthFailure(AuthErrorCode.emailInUse);
      expect(AppFailure.from(failure), same(failure));
      expect(AppFailure.from(StateError('x')), isA<UnknownFailure>());
    });
  });

  group('Money', () {
    test('parses user input in both decimal styles', () {
      expect(Money.parse('12'), 1200);
      expect(Money.parse('12,5'), 1250);
      expect(Money.parse('12.50'), 1250);
      expect(Money.parse('1.234,56'), 123456);
      expect(Money.parse('1,234.56'), 123456);
      expect(Money.parse('1.234'), 123400);
      expect(Money.parse('€ 7,99'), 799);
      expect(Money.parse('0'), isNull);
      expect(Money.parse('abc'), isNull);
    });

    test('formats signed amounts', () {
      expect(Money.format(-1250), startsWith('−'));
      expect(Money.format(1250, signed: true), startsWith('+'));
      expect(Money.format(0, signed: true), isNot(startsWith('+')));
    });
  });
}
