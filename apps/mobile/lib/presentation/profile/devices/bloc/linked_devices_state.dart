part of 'linked_devices_bloc.dart';

enum LinkedDevicesStatus { loading, ready, error }

enum DevicesMessage { unlinked, cannotUnlinkCurrent, error }

@freezed
abstract class LinkedDevicesState with _$LinkedDevicesState {
  const factory LinkedDevicesState({
    @Default(LinkedDevicesStatus.loading) LinkedDevicesStatus status,
    @Default(<LinkedDevice>[]) List<LinkedDevice> devices,
    String? unlinking,
    DevicesMessage? message,
  }) = _LinkedDevicesState;
}
