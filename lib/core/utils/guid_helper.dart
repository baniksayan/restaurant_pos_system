/// Helpers for the all-zero GUID the API uses as a "no value" placeholder.
///
/// Several PosWebApi response DTOs declare non-nullable `Guid` fields that the
/// underlying stored procedure never selects — `Order/getOrderDetailById` is
/// the notable one, whose `Sp_GetOrderViewNew` returns BillNo and
/// GeneratedBillNo but no BillId. Those fields come back serialized as
/// "00000000-0000-0000-0000-000000000000" rather than null, so a plain
/// null/isNotEmpty check treats the placeholder as a real id. Passing it on to
/// something like SavePayment targets a bill that does not exist, and the
/// payment silently fails to settle anything.
class GuidHelper {
  GuidHelper._();

  static const String empty = '00000000-0000-0000-0000-000000000000';

  /// True when [value] is null, blank, or the all-zero placeholder.
  static bool isNullOrEmpty(String? value) {
    if (value == null) return true;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return true;
    return trimmed.toLowerCase() == empty;
  }

  /// True when [value] is a usable identifier.
  static bool isValid(String? value) => !isNullOrEmpty(value);

  /// [value] when it is a real id, otherwise null — handy for collapsing the
  /// placeholder back to null before storing or passing it along.
  static String? orNull(String? value) => isValid(value) ? value!.trim() : null;
}
