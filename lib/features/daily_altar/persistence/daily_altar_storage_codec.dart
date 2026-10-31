import '../model/daily_altar_evening_response.dart';
import '../model/daily_altar_obedience_response.dart';
import '../model/daily_altar_personal_prayer.dart';
import '../model/daily_altar_posture.dart';
import '../model/daily_altar_reflection_response.dart';
import '../model/daily_altar_session.dart';
import '../model/daily_altar_stage.dart';
import '../model/daily_altar_user_response.dart';
import '../services/daily_altar_response_validator.dart';
import 'daily_altar_storage_exception.dart';
import 'daily_altar_stored_record.dart';

/// Converts My Daily Altar domain objects to Hive-safe primitive maps.
///
/// Explicit schema versioning gives us a migration boundary if the feature
/// evolves later.
class DailyAltarStorageCodec {
  const DailyAltarStorageCodec({
    this.responseValidator = const DailyAltarResponseValidator(),
  });

  static const int currentSchemaVersion = 1;

  final DailyAltarResponseValidator responseValidator;

  Map<String, dynamic> encode(DailyAltarStoredRecord record) {
    _validateRecord(record);

    return <String, dynamic>{
      'schemaVersion': currentSchemaVersion,
      'contentId': record.contentId,
      'session': _encodeSession(record.session),
      'response': _encodeResponse(record.response),
    };
  }

  DailyAltarStoredRecord decode(Object? raw) {
    try {
      final root = _asMap(raw, 'root');

      final schemaVersion = root['schemaVersion'];

      if (schemaVersion != currentSchemaVersion) {
        throw DailyAltarStorageException(
          'Unsupported Daily Altar storage schema: $schemaVersion',
        );
      }

      final contentId = root['contentId'];

      if (contentId is! String || contentId.trim().isEmpty) {
        throw const DailyAltarStorageException(
          'Stored contentId is missing or invalid.',
        );
      }

      final session = _decodeSession(
        _asMap(root['session'], 'session'),
      );

      final response = _decodeResponse(
        _asMap(root['response'], 'response'),
      );

      final record = DailyAltarStoredRecord(
        session: session,
        contentId: contentId,
        response: response,
      );

      _validateRecord(record);

      return record;
    } on DailyAltarStorageException {
      rethrow;
    } catch (error) {
      throw DailyAltarStorageException(
        'Stored Daily Altar data is invalid.',
        error,
      );
    }
  }

  Map<String, dynamic> _encodeSession(
    DailyAltarSession session,
  ) {
    return <String, dynamic>{
      'id': session.id,
      'localDate': session.localDate.toIso8601String(),
      'stage': session.stage.name,
      'posture': session.posture?.name,
      'startedAt': session.startedAt?.toIso8601String(),
      'morningCompletedAt': session.morningCompletedAt?.toIso8601String(),
      'completedAt': session.completedAt?.toIso8601String(),
    };
  }

  DailyAltarSession _decodeSession(
    Map<String, dynamic> map,
  ) {
    final id = _requiredString(map, 'id');
    final localDate = _requiredDate(map, 'localDate');

    return DailyAltarSession(
      id: id,
      localDate: localDate,
      stage: _stage(
        _requiredString(map, 'stage'),
      ),
      posture: _posture(
        map['posture'],
      ),
      startedAt: _optionalDate(
        map['startedAt'],
        'startedAt',
      ),
      morningCompletedAt: _optionalDate(
        map['morningCompletedAt'],
        'morningCompletedAt',
      ),
      completedAt: _optionalDate(
        map['completedAt'],
        'completedAt',
      ),
    );
  }

  Map<String, dynamic> _encodeResponse(
    DailyAltarUserResponse response,
  ) {
    return <String, dynamic>{
      'sessionId': response.sessionId,
      'reflection': response.reflection == null
          ? null
          : <String, dynamic>{
              'aboutGod': response.reflection!.aboutGod,
              'aboutMe': response.reflection!.aboutMe,
              'response': response.reflection!.response,
            },
      'personalPrayer': response.personalPrayer == null
          ? null
          : <String, dynamic>{
              'text': response.personalPrayer!.text,
            },
      'obedience': response.obedience == null
          ? null
          : <String, dynamic>{
              'commitment': response.obedience!.commitment,
              'completed': response.obedience!.completed,
              'completedAt': response.obedience!.completedAt?.toIso8601String(),
            },
      'evening': response.evening == null
          ? null
          : <String, dynamic>{
              'rememberedWord': response.evening!.rememberedWord,
              'obedienceReflection': response.evening!.obedienceReflection,
              'relevanceReflection': response.evening!.relevanceReflection,
              'heartResponse': response.evening!.heartResponse,
              'carryForward': response.evening!.carryForward,
            },
      'updatedAt': response.updatedAt?.toIso8601String(),
    };
  }

  DailyAltarUserResponse _decodeResponse(
    Map<String, dynamic> map,
  ) {
    final reflectionMap = _optionalMap(
      map['reflection'],
      'reflection',
    );

    final prayerMap = _optionalMap(
      map['personalPrayer'],
      'personalPrayer',
    );

    final obedienceMap = _optionalMap(
      map['obedience'],
      'obedience',
    );

    final eveningMap = _optionalMap(
      map['evening'],
      'evening',
    );

    return DailyAltarUserResponse(
      sessionId: _requiredString(
        map,
        'sessionId',
      ),
      reflection: reflectionMap == null
          ? null
          : DailyAltarReflectionResponse(
              aboutGod: _optionalString(
                reflectionMap['aboutGod'],
              ),
              aboutMe: _optionalString(
                reflectionMap['aboutMe'],
              ),
              response: _optionalString(
                reflectionMap['response'],
              ),
            ),
      personalPrayer: prayerMap == null
          ? null
          : DailyAltarPersonalPrayer(
              text: _requiredString(
                prayerMap,
                'text',
              ),
            ),
      obedience: obedienceMap == null
          ? null
          : DailyAltarObedienceResponse(
              commitment: _requiredString(
                obedienceMap,
                'commitment',
              ),
              completed: obedienceMap['completed'] == true,
              completedAt: _optionalDate(
                obedienceMap['completedAt'],
                'obedience.completedAt',
              ),
            ),
      evening: eveningMap == null
          ? null
          : DailyAltarEveningResponse(
              rememberedWord: _optionalString(
                eveningMap['rememberedWord'],
              ),
              obedienceReflection: _optionalString(
                eveningMap['obedienceReflection'],
              ),
              relevanceReflection: _optionalString(
                eveningMap['relevanceReflection'],
              ),
              heartResponse: _optionalString(
                eveningMap['heartResponse'],
              ),
              carryForward: _optionalString(
                eveningMap['carryForward'],
              ),
            ),
      updatedAt: _optionalDate(
        map['updatedAt'],
        'updatedAt',
      ),
    );
  }

  void _validateRecord(
    DailyAltarStoredRecord record,
  ) {
    if (record.contentId.trim().isEmpty) {
      throw const DailyAltarStorageException(
        'contentId must not be empty.',
      );
    }

    if (record.session.id.trim().isEmpty) {
      throw const DailyAltarStorageException(
        'session.id must not be empty.',
      );
    }

    if (record.response.sessionId != record.session.id) {
      throw const DailyAltarStorageException(
        'Session and response IDs do not match.',
      );
    }

    try {
      responseValidator.validate(record.response);
    } catch (error) {
      throw DailyAltarStorageException(
        'Daily Altar response is invalid.',
        error,
      );
    }
  }

  Map<String, dynamic> _asMap(
    Object? value,
    String field,
  ) {
    if (value is! Map) {
      throw DailyAltarStorageException(
        '$field must be an object.',
      );
    }

    try {
      return Map<String, dynamic>.from(value);
    } catch (error) {
      throw DailyAltarStorageException(
        '$field contains invalid keys.',
        error,
      );
    }
  }

  Map<String, dynamic>? _optionalMap(
    Object? value,
    String field,
  ) {
    if (value == null) {
      return null;
    }

    return _asMap(value, field);
  }

  String _requiredString(
    Map<String, dynamic> map,
    String field,
  ) {
    final value = map[field];

    if (value is! String || value.trim().isEmpty) {
      throw DailyAltarStorageException(
        '$field must be a non-empty string.',
      );
    }

    return value;
  }

  String? _optionalString(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw const DailyAltarStorageException(
        'Expected optional string value.',
      );
    }

    return value;
  }

  DateTime _requiredDate(
    Map<String, dynamic> map,
    String field,
  ) {
    final value = _requiredString(map, field);

    try {
      return DateTime.parse(value);
    } catch (error) {
      throw DailyAltarStorageException(
        '$field contains an invalid date.',
        error,
      );
    }
  }

  DateTime? _optionalDate(
    Object? value,
    String field,
  ) {
    if (value == null) {
      return null;
    }

    if (value is! String || value.isEmpty) {
      throw DailyAltarStorageException(
        '$field contains an invalid date.',
      );
    }

    try {
      return DateTime.parse(value);
    } catch (error) {
      throw DailyAltarStorageException(
        '$field contains an invalid date.',
        error,
      );
    }
  }

  DailyAltarStage _stage(String value) {
    return DailyAltarStage.values.firstWhere(
      (stage) => stage.name == value,
      orElse: () => throw DailyAltarStorageException(
        'Unknown Daily Altar stage: $value',
      ),
    );
  }

  DailyAltarPosture? _posture(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw const DailyAltarStorageException(
        'Stored posture is invalid.',
      );
    }

    return DailyAltarPosture.values.firstWhere(
      (posture) => posture.name == value,
      orElse: () => throw DailyAltarStorageException(
        'Unknown Daily Altar posture: $value',
      ),
    );
  }
}
