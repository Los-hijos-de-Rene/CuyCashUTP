part of 'linked_devices_bloc.dart';

@freezed
sealed class LinkedDevicesEvent with _$LinkedDevicesEvent {
  const factory LinkedDevicesEvent.started() = LinkedDevicesStarted;
  const factory LinkedDevicesEvent.unlinkRequested(String id) =
      LinkedDevicesUnlinkRequested;
}
