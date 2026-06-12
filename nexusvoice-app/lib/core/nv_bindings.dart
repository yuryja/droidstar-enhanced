import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Native Function pointer signatures for callbacks
typedef StatusCbNative = Void Function(Int32 statusCode, Pointer<Utf8> msg, Pointer<Void> userdata);
typedef DataCbNative = Void Function(Pointer<Utf8> label, Pointer<Utf8> value, Pointer<Void> userdata);
typedef LogCbNative = Void Function(Pointer<Utf8> line, Pointer<Void> userdata);
typedef FileDownloadedCbNative = Void Function(Pointer<Utf8> filename, Pointer<Void> userdata);

// Dart equivalents of callback signatures
typedef StatusCbDart = void Function(int statusCode, Pointer<Utf8> msg, Pointer<Void> userdata);
typedef DataCbDart = void Function(Pointer<Utf8> label, Pointer<Utf8> value, Pointer<Void> userdata);
typedef LogCbDart = void Function(Pointer<Utf8> line, Pointer<Void> userdata);
typedef FileDownloadedCbDart = void Function(Pointer<Utf8> filename, Pointer<Void> userdata);

class NexusVoiceBindings {
  late final DynamicLibrary _lib;

  // Function Bindings
  late final Pointer<Void> Function() nvCreate;
  late final void Function(Pointer<Void>) nvDestroy;
  late final void Function(Pointer<Void>) nvPttStart;
  late final void Function(Pointer<Void>) nvPttStop;
  late final void Function(Pointer<Void>, int) nvPttClick;
  late final void Function(Pointer<Void>) nvProcessConnect;
  late final void Function(Pointer<Void>) nvProcessSettings;
  late final void Function(Pointer<Void>) nvCheckHostFiles;
  late final void Function(Pointer<Void>) nvUpdateHostFiles;
  late final void Function(Pointer<Void>) nvUpdateDmrIds;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvProcessModeChange;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvProcessHostChange;

  // Setters
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetCallsign;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetDmrid;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetEssid;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetBmPassword;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetTgifPassword;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetAslPassword;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetLatitude;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetLongitude;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetLocation;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetDescription;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetFreq;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetUrl;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetSwid;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetPkgid;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetDmrOptions;
  late final void Function(Pointer<Void>, int) nvSetDmrPc;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetModule;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetProtocol;
  late final void Function(Pointer<Void>, double) nvSetInputVolume;
  late final void Function(Pointer<Void>, double) nvSetOutputVolume;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetMycall;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetUrcall;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetRptr1;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetRptr2;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetUsrtxt;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetTxtimeout;
  late final void Function(Pointer<Void>, int) nvSetToggletx;
  late final void Function(Pointer<Void>, int) nvSetXrf2ref;
  late final void Function(Pointer<Void>, int) nvSetIpv6;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetVocoder;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetModem;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetPlayback;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetCapture;
  late final void Function(Pointer<Void>, Pointer<Utf8>) nvSetDmrtgid;
  late final void Function(Pointer<Void>, int) nvSetSlot;
  late final void Function(Pointer<Void>, int) nvSetCc;
  late final void Function(Pointer<Void>, int) nvSetDebug;
  late final void Function(Pointer<Void>, int) nvSetPttKey;

  // Getters
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetHosts;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetVocoders;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetModems;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetPlaybacks;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetCaptures;

  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetMode;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetHost;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetModule;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetCallsign;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetDmrid;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetEssid;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetBmPassword;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetTgifPassword;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetAslPassword;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetAmbestatustxt;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetMmdvmstatustxt;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetNetstatustxt;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetErrorText;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvGetDmrtgid;
  late final int Function(Pointer<Void>) nvGetPttKey;
  late final int Function(Pointer<Void>) nvGetOutputLevel;

  // Callback Setters
  late final void Function(Pointer<Void>, Pointer<NativeFunction<StatusCbNative>>, Pointer<Void>) nvSetStatusCb;
  late final void Function(Pointer<Void>, Pointer<NativeFunction<DataCbNative>>, Pointer<Void>) nvSetDataCb;
  late final void Function(Pointer<Void>, Pointer<NativeFunction<LogCbNative>>, Pointer<Void>) nvSetLogCb;
  late final void Function(Pointer<Void>, Pointer<NativeFunction<FileDownloadedCbNative>>, Pointer<Void>) nvSetFileDownloadedCb;

  // Memory & Logs
  late final void Function(Pointer<Void>, int, Pointer<Utf8>, Pointer<Utf8>, int, int, Pointer<Utf8>) nvSaveMemory;
  late final int Function(Pointer<Void>, int, Pointer<Utf8>, int) nvGetMemory;
  late final int Function(Pointer<Void>, Pointer<Utf8>, int) nvReadStationLog;
  late final void Function(Pointer<Void>) nvClearStationLog;

  NexusVoiceBindings() {
    final path = _getLibraryPath();
    _lib = DynamicLibrary.open(path);
    _initializeBindings();
  }

  String _getLibraryPath() {
    if (Platform.isMacOS) {
      const devPath = '/Users/yury/Documents/Proyectos/droidstar-enhaced/build/libnexusvoice_core.dylib';
      if (File(devPath).existsSync()) {
        return devPath;
      }
      return 'libnexusvoice_core.dylib';
    } else if (Platform.isWindows) {
      return 'nexusvoice_core.dll';
    } else {
      return 'libnexusvoice_core.so';
    }
  }

  void _initializeBindings() {
    nvCreate = _lib.lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>('nv_create');
    nvDestroy = _lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('nv_destroy');
    nvPttStart = _lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('nv_ptt_start');
    nvPttStop = _lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('nv_ptt_stop');
    nvPttClick = _lib.lookupFunction<Void Function(Pointer<Void>, Int32), void Function(Pointer<Void>, int)>('nv_ptt_click');
    nvProcessConnect = _lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('nv_process_connect');
    nvProcessSettings = _lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('nv_process_settings');
    nvCheckHostFiles = _lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('nv_check_host_files');
    nvUpdateHostFiles = _lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('nv_update_host_files');
    nvUpdateDmrIds = _lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('nv_update_dmr_ids');
    nvProcessModeChange = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_process_mode_change');
    nvProcessHostChange = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_process_host_change');

    // Setters
    nvSetCallsign = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_callsign');
    nvSetDmrid = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_dmrid');
    nvSetEssid = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_essid');
    nvSetBmPassword = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_bm_password');
    nvSetTgifPassword = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_tgif_password');
    nvSetAslPassword = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_asl_password');
    nvSetLatitude = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_latitude');
    nvSetLongitude = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_longitude');
    nvSetLocation = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_location');
    nvSetDescription = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_description');
    nvSetFreq = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_freq');
    nvSetUrl = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_url');
    nvSetSwid = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_swid');
    nvSetPkgid = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_pkgid');
    nvSetDmrOptions = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_dmr_options');
    nvSetDmrPc = _lib.lookupFunction<Void Function(Pointer<Void>, Int32), void Function(Pointer<Void>, int)>('nv_set_dmr_pc');
    nvSetModule = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_module');
    nvSetProtocol = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_protocol');
    nvSetInputVolume = _lib.lookupFunction<Void Function(Pointer<Void>, Double), void Function(Pointer<Void>, double)>('nv_set_input_volume');
    nvSetOutputVolume = _lib.lookupFunction<Void Function(Pointer<Void>, Double), void Function(Pointer<Void>, double)>('nv_set_output_volume');
    nvSetMycall = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_mycall');
    nvSetUrcall = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_urcall');
    nvSetRptr1 = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_rptr1');
    nvSetRptr2 = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_rptr2');
    nvSetUsrtxt = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_usrtxt');
    nvSetTxtimeout = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_txtimeout');
    nvSetToggletx = _lib.lookupFunction<Void Function(Pointer<Void>, Int32), void Function(Pointer<Void>, int)>('nv_set_toggletx');
    nvSetXrf2ref = _lib.lookupFunction<Void Function(Pointer<Void>, Int32), void Function(Pointer<Void>, int)>('nv_set_xrf2ref');
    nvSetIpv6 = _lib.lookupFunction<Void Function(Pointer<Void>, Int32), void Function(Pointer<Void>, int)>('nv_set_ipv6');
    nvSetVocoder = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_vocoder');
    nvSetModem = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_modem');
    nvSetPlayback = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_playback');
    nvSetCapture = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_capture');
    nvSetDmrtgid = _lib.lookupFunction<Void Function(Pointer<Void>, Pointer<Utf8>), void Function(Pointer<Void>, Pointer<Utf8>)>('nv_set_dmrtgid');
    nvSetSlot = _lib.lookupFunction<Void Function(Pointer<Void>, Int32), void Function(Pointer<Void>, int)>('nv_set_slot');
    nvSetCc = _lib.lookupFunction<Void Function(Pointer<Void>, Int32), void Function(Pointer<Void>, int)>('nv_set_cc');
    nvSetDebug = _lib.lookupFunction<Void Function(Pointer<Void>, Int32), void Function(Pointer<Void>, int)>('nv_set_debug');
    nvSetPttKey = _lib.lookupFunction<Void Function(Pointer<Void>, Int32), void Function(Pointer<Void>, int)>('nv_set_ptt_key');

    // Getters
    nvGetHosts = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_hosts');
    nvGetVocoders = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_vocoders');
    nvGetModems = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_modems');
    nvGetPlaybacks = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_playbacks');
    nvGetCaptures = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_captures');

    nvGetMode = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_mode');
    nvGetHost = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_host');
    nvGetModule = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_module');
    nvGetCallsign = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_callsign');
    nvGetDmrid = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_dmrid');
    nvGetEssid = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_essid');
    nvGetBmPassword = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_bm_password');
    nvGetTgifPassword = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_tgif_password');
    nvGetAslPassword = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_asl_password');
    nvGetAmbestatustxt = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_ambestatustxt');
    nvGetMmdvmstatustxt = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_mmdvmstatustxt');
    nvGetNetstatustxt = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_netstatustxt');
    nvGetErrorText = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_error_text');
    nvGetDmrtgid = _lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32), int Function(Pointer<Void>, Pointer<Utf8>, int)>('nv_get_dmrtgid');
    nvGetPttKey = _lib.lookupFunction<Int32 Function(Pointer<Void>), int Function(Pointer<Void>)>('nv_get_ptt_key');
    nvGetOutputLevel = _lib.lookupFunction<Int32 Function(Pointer<Void>), int Function(Pointer<Void>)>('nv_get_output_level');

    // Callback Setters
    nvSetStatusCb = _lib.lookupFunction<
        Void Function(Pointer<Void>, Pointer<NativeFunction<StatusCbNative>>, Pointer<Void>),
        void Function(Pointer<Void>, Pointer<NativeFunction<StatusCbNative>>, Pointer<Void>)
    >('nv_set_status_cb');

    nvSetDataCb = _lib.lookupFunction<
        Void Function(Pointer<Void>, Pointer<NativeFunction<DataCbNative>>, Pointer<Void>),
        void Function(Pointer<Void>, Pointer<NativeFunction<DataCbNative>>, Pointer<Void>)
    >('nv_set_data_cb');

    nvSetLogCb = _lib.lookupFunction<
        Void Function(Pointer<Void>, Pointer<NativeFunction<LogCbNative>>, Pointer<Void>),
        void Function(Pointer<Void>, Pointer<NativeFunction<LogCbNative>>, Pointer<Void>)
    >('nv_set_log_cb');

    nvSetFileDownloadedCb = _lib.lookupFunction<
        Void Function(Pointer<Void>, Pointer<NativeFunction<FileDownloadedCbNative>>, Pointer<Void>),
        void Function(Pointer<Void>, Pointer<NativeFunction<FileDownloadedCbNative>>, Pointer<Void>)
    >('nv_set_file_downloaded_cb');

    // Memory & Logs
    nvSaveMemory = _lib.lookupFunction<
        Void Function(Pointer<Void>, Int32, Pointer<Utf8>, Pointer<Utf8>, Int32, Int32, Pointer<Utf8>),
        void Function(Pointer<Void>, int, Pointer<Utf8>, Pointer<Utf8>, int, int, Pointer<Utf8>)
    >('nv_save_memory');

    nvGetMemory = _lib.lookupFunction<
        Int32 Function(Pointer<Void>, Int32, Pointer<Utf8>, Int32),
        int Function(Pointer<Void>, int, Pointer<Utf8>, int)
    >('nv_get_memory');

    nvReadStationLog = _lib.lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Utf8>, Int32),
        int Function(Pointer<Void>, Pointer<Utf8>, int)
    >('nv_read_station_log');

    nvClearStationLog = _lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('nv_clear_station_log');
  }
}
