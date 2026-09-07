import 'dart:math';

/// Cálculo normativo SEA: ciclo noche = 1h después del atardecer (duración
/// 1h), ciclo mañana = 1h antes del amanecer (duración 1h).
///
/// Traducción directa del algoritmo NOAA que ya usa portal.h (función
/// calcSunEvent() en JavaScript) — mismo cálculo, mismo resultado, para que
/// la app y el portal siempre coincidan si algún día se comparan.
class SeaCalculator {
  SeaCalculator._();

  /// Devuelve el momento de salida o puesta de sol para [date] (se usa solo
  /// el día/mes/año, en la zona horaria local del teléfono) y la posición
  /// [lat]/[lon] en grados decimales. Devuelve null si el sol no sale o no
  /// se pone ese día en esa latitud (casos polares extremos).
  static DateTime? _sunEvent(DateTime date, double lat, double lon, bool isSunrise) {
    const rad = pi / 180;

    final jd = date.toUtc().millisecondsSinceEpoch / 86400000 + 2440587.5;
    final n = jd - 2451545.0;
    final L = (280.46 + 0.9856474 * n) % 360;
    final g = (357.528 + 0.9856003 * n) % 360;
    final lam = L + 1.915 * sin(g * rad) + 0.02 * sin(2 * g * rad);
    final eps = 23.439 - 0.0000004 * n;
    final ra = atan2(cos(eps * rad) * sin(lam * rad), cos(lam * rad)) / rad;
    final dec = asin(sin(eps * rad) * sin(lam * rad)) / rad;

    final cosHa = (sin(-0.8333 * rad) - sin(lat * rad) * sin(dec * rad)) /
        (cos(lat * rad) * cos(dec * rad));
    if (cosHa < -1 || cosHa > 1) return null; // sol no sale/se pone ese día ahí
    final ha = acos(cosHa) / rad;

    final noon = 12 - (lon / 15) - ((ra - (L % 360)) / 15);
    final evtUTC = isSunrise ? noon - ha / 15 : noon + ha / 15;

    // date.timeZoneOffset ya viene con el signo correcto (negativo si la
    // zona horaria local está detrás de UTC, como Chile continental).
    final offsetHours = date.timeZoneOffset.inMinutes / 60.0;
    final evtLoc = evtUTC + offsetHours;

    var h = evtLoc.floor() % 24;
    if (h < 0) h += 24;
    final m = ((evtLoc % 1) * 60).round();

    return DateTime(date.year, date.month, date.day, h, m);
  }

  static String _fmt(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// Calcula los 4 horarios normativos SEA para hoy, en la posición dada.
  /// Devuelve null si no se pudo calcular (posiciones polares extremas).
  static SeaSchedule? calculate({required double lat, required double lon}) {
    final today = DateTime.now();
    final sunrise = _sunEvent(today, lat, lon, true);
    final sunset = _sunEvent(today, lat, lon, false);
    if (sunrise == null || sunset == null) return null;

    final nightStart = sunset.add(const Duration(hours: 1));
    final nightEnd = nightStart.add(const Duration(hours: 1));
    final morningEnd = sunrise.subtract(const Duration(hours: 1));
    final morningStart = morningEnd.subtract(const Duration(hours: 1));

    return SeaSchedule(
      morningStart: _fmt(morningStart),
      morningEnd: _fmt(morningEnd),
      nightStart: _fmt(nightStart),
      nightEnd: _fmt(nightEnd),
    );
  }
}

class SeaSchedule {
  final String morningStart;
  final String morningEnd;
  final String nightStart;
  final String nightEnd;

  SeaSchedule({
    required this.morningStart,
    required this.morningEnd,
    required this.nightStart,
    required this.nightEnd,
  });
}
