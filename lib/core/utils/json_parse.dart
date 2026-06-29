Map<String, dynamic> parseJsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return {
      for (final entry in value.entries)
        if (entry.key != null) entry.key.toString(): entry.value,
    };
  }

  return const {};
}

String parseString(Object? value, {String fallback = ''}) {
  if (value is String) {
    return value;
  }
  if (value == null) {
    return fallback;
  }

  return value.toString();
}

num? parseNullableNum(Object? value) {
  if (value is num) {
    return value;
  }
  if (value is String) {
    return num.tryParse(value);
  }

  return null;
}

double? parseNullableDouble(Object? value) {
  return parseNullableNum(value)?.toDouble();
}

int? parseNullableInt(Object? value) {
  return parseNullableNum(value)?.toInt();
}

DateTime? parseNullableDateTime(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }

  return null;
}
