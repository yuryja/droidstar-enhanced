import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'nv_bindings.dart';

// Top-level callbacks that forward data to the singleton instance
void _onStatusChanged(int statusCode, Pointer<Utf8> msgPtr, Pointer<Void> userdata) {
  final msg = msgPtr.toDartString();
  NvController.instance._handleStatusChanged(statusCode, msg);
}

void _onDataChanged(Pointer<Utf8> labelPtr, Pointer<Utf8> valuePtr, Pointer<Void> userdata) {
  final label = labelPtr.toDartString();
  final value = valuePtr.toDartString();
  NvController.instance._handleDataChanged(label, value);
}

void _onLogReceived(Pointer<Utf8> linePtr, Pointer<Void> userdata) {
  final line = linePtr.toDartString();
  NvController.instance._handleLogReceived(line);
}

void _onFileDownloaded(Pointer<Utf8> filenamePtr, Pointer<Void> userdata) {
  final filename = filenamePtr.toDartString();
  NvController.instance._handleFileDownloaded(filename);
}

class NvController extends ChangeNotifier {
  static final NvController instance = NvController._internal();

  late final NexusVoiceBindings _bindings;
  Pointer<Void>? _handle;

  // Connection and logging state
  int _connectionStatus = 0;
  String _statusMessage = 'Disconnected';
  final List<String> _logs = [];
  
  // Dynamic labels and data mapped from the core
  final Map<String, String> _coreData = {};

  // Getters for UI
  int get connectionStatus => _connectionStatus;
  String get statusMessage => _statusMessage;
  List<String> get logs => List.unmodifiable(_logs);
  Map<String, String> get coreData => Map.unmodifiable(_coreData);

  NvController._internal() {
    _bindings = NexusVoiceBindings();
    _handle = _bindings.nvCreate();
    _setupCallbacks();
    
    // Continuously pump the Qt event loop in the C++ library
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_handle != null) {
        _bindings.nvGetOutputLevel(_handle!);
      }
    });
  }

  void _setupCallbacks() {
    if (_handle == null) return;
    
    // Register status callback
    final statusCbPtr = Pointer.fromFunction<StatusCbNative>(_onStatusChanged);
    _bindings.nvSetStatusCb(_handle!, statusCbPtr, nullptr);

    // Register data callback
    final dataCbPtr = Pointer.fromFunction<DataCbNative>(_onDataChanged);
    _bindings.nvSetDataCb(_handle!, dataCbPtr, nullptr);

    // Register log callback
    final logCbPtr = Pointer.fromFunction<LogCbNative>(_onLogReceived);
    _bindings.nvSetLogCb(_handle!, logCbPtr, nullptr);

    // Register file downloaded callback
    final fileDownloadedCbPtr = Pointer.fromFunction<FileDownloadedCbNative>(_onFileDownloaded);
    _bindings.nvSetFileDownloadedCb(_handle!, fileDownloadedCbPtr, nullptr);
  }

  // Handle incoming status callbacks
  void _handleStatusChanged(int status, String message) {
    _connectionStatus = status;
    _statusMessage = message;
    notifyListeners();
  }

  // Handle incoming data/label changes
  void _handleDataChanged(String label, String value) {
    _coreData[label] = value;
    notifyListeners();
  }

  // Handle incoming logs
  void _handleLogReceived(String line) {
    // Clean up carriage returns/newlines if any
    final cleanLine = line.replaceAll('\r', '').replaceAll('\n', '').trim();
    if (cleanLine.isNotEmpty) {
      _logs.add(cleanLine);
      if (_logs.length > 500) {
        _logs.removeAt(0); // Keep logs bounded
      }
      notifyListeners();
    }
  }

  // Handle file download notification
  void _handleFileDownloaded(String filename) {
    _handleLogReceived('System downloaded file: $filename');
  }

  // Dispose and cleanup
  @override
  void dispose() {
    if (_handle != null) {
      _bindings.nvDestroy(_handle!);
      _handle = null;
    }
    super.dispose();
  }

  // API Call wraps
  void connect() {
    if (_handle == null) return;
    _bindings.nvProcessConnect(_handle!);
  }

  void disconnect() {
    // DroidStar uses process_connect to toggle connect/disconnect
    if (_handle == null) return;
    _bindings.nvProcessConnect(_handle!);
  }

  void saveSettings() {
    if (_handle == null) return;
    _bindings.nvProcessSettings(_handle!);
  }

  void checkHostFiles() {
    if (_handle == null) return;
    _bindings.nvCheckHostFiles(_handle!);
  }

  void updateHostFiles() {
    if (_handle == null) return;
    _bindings.nvUpdateHostFiles(_handle!);
  }

  void updateDmrIds() {
    if (_handle == null) return;
    _bindings.nvUpdateDmrIds(_handle!);
  }

  void processModeChange(String mode) {
    if (_handle == null) return;
    final ptr = mode.toNativeUtf8();
    _bindings.nvProcessModeChange(_handle!, ptr);
    malloc.free(ptr);
  }

  void processHostChange(String host) {
    if (_handle == null) return;
    final ptr = host.toNativeUtf8();
    _bindings.nvProcessHostChange(_handle!, ptr);
    malloc.free(ptr);
  }

  // PTT Actions
  void startPtt() {
    if (_handle == null) return;
    _bindings.nvPttStart(_handle!);
  }

  void stopPtt() {
    if (_handle == null) return;
    _bindings.nvPttStop(_handle!);
  }

  void clickPtt(bool pressed) {
    if (_handle == null) return;
    _bindings.nvPttClick(_handle!, pressed ? 1 : 0);
  }

  // Setters wrapper
  void setCallsign(String callsign) {
    if (_handle == null) return;
    final ptr = callsign.toNativeUtf8();
    _bindings.nvSetCallsign(_handle!, ptr);
    malloc.free(ptr);
  }

  void setDmrId(String id) {
    if (_handle == null) return;
    final ptr = id.toNativeUtf8();
    _bindings.nvSetDmrid(_handle!, ptr);
    malloc.free(ptr);
  }

  void setEssid(String essid) {
    if (_handle == null) return;
    final ptr = essid.toNativeUtf8();
    _bindings.nvSetEssid(_handle!, ptr);
    malloc.free(ptr);
  }

  void setBmPassword(String pwd) {
    if (_handle == null) return;
    final ptr = pwd.toNativeUtf8();
    _bindings.nvSetBmPassword(_handle!, ptr);
    malloc.free(ptr);
  }

  void setTgifPassword(String pwd) {
    if (_handle == null) return;
    final ptr = pwd.toNativeUtf8();
    _bindings.nvSetTgifPassword(_handle!, ptr);
    malloc.free(ptr);
  }

  void setAslPassword(String pwd) {
    if (_handle == null) return;
    final ptr = pwd.toNativeUtf8();
    _bindings.nvSetAslPassword(_handle!, ptr);
    malloc.free(ptr);
  }

  void setLatitude(String lat) {
    if (_handle == null) return;
    final ptr = lat.toNativeUtf8();
    _bindings.nvSetLatitude(_handle!, ptr);
    malloc.free(ptr);
  }

  void setLongitude(String lon) {
    if (_handle == null) return;
    final ptr = lon.toNativeUtf8();
    _bindings.nvSetLongitude(_handle!, ptr);
    malloc.free(ptr);
  }

  void setLocation(String loc) {
    if (_handle == null) return;
    final ptr = loc.toNativeUtf8();
    _bindings.nvSetLocation(_handle!, ptr);
    malloc.free(ptr);
  }

  void setDescription(String desc) {
    if (_handle == null) return;
    final ptr = desc.toNativeUtf8();
    _bindings.nvSetDescription(_handle!, ptr);
    malloc.free(ptr);
  }

  void setFreq(String freq) {
    if (_handle == null) return;
    final ptr = freq.toNativeUtf8();
    _bindings.nvSetFreq(_handle!, ptr);
    malloc.free(ptr);
  }

  void setUrl(String url) {
    if (_handle == null) return;
    final ptr = url.toNativeUtf8();
    _bindings.nvSetUrl(_handle!, ptr);
    malloc.free(ptr);
  }

  void setSwid(String swid) {
    if (_handle == null) return;
    final ptr = swid.toNativeUtf8();
    _bindings.nvSetSwid(_handle!, ptr);
    malloc.free(ptr);
  }

  void setPkgid(String pkgid) {
    if (_handle == null) return;
    final ptr = pkgid.toNativeUtf8();
    _bindings.nvSetPkgid(_handle!, ptr);
    malloc.free(ptr);
  }

  void setDmrOptions(String opts) {
    if (_handle == null) return;
    final ptr = opts.toNativeUtf8();
    _bindings.nvSetDmrOptions(_handle!, ptr);
    malloc.free(ptr);
  }

  void setDmrPc(int pc) {
    if (_handle == null) return;
    _bindings.nvSetDmrPc(_handle!, pc);
  }

  void setModule(String module) {
    if (_handle == null) return;
    final ptr = module.toNativeUtf8();
    _bindings.nvSetModule(_handle!, ptr);
    malloc.free(ptr);
  }

  void setProtocol(String protocol) {
    if (_handle == null) return;
    final ptr = protocol.toNativeUtf8();
    _bindings.nvSetProtocol(_handle!, ptr);
    malloc.free(ptr);
  }

  void setInputVolume(double vol) {
    if (_handle == null) return;
    _bindings.nvSetInputVolume(_handle!, vol);
  }

  void setOutputVolume(double vol) {
    if (_handle == null) return;
    _bindings.nvSetOutputVolume(_handle!, vol);
  }

  void setMyCall(String call) {
    if (_handle == null) return;
    final ptr = call.toNativeUtf8();
    _bindings.nvSetMycall(_handle!, ptr);
    malloc.free(ptr);
  }

  void setUrCall(String call) {
    if (_handle == null) return;
    final ptr = call.toNativeUtf8();
    _bindings.nvSetUrcall(_handle!, ptr);
    malloc.free(ptr);
  }

  void setRptr1(String rptr) {
    if (_handle == null) return;
    final ptr = rptr.toNativeUtf8();
    _bindings.nvSetRptr1(_handle!, ptr);
    malloc.free(ptr);
  }

  void setRptr2(String rptr) {
    if (_handle == null) return;
    final ptr = rptr.toNativeUtf8();
    _bindings.nvSetRptr2(_handle!, ptr);
    malloc.free(ptr);
  }

  void setUsrTxt(String txt) {
    if (_handle == null) return;
    final ptr = txt.toNativeUtf8();
    _bindings.nvSetUsrtxt(_handle!, ptr);
    malloc.free(ptr);
  }

  void setTxTimeout(String t) {
    if (_handle == null) return;
    final ptr = t.toNativeUtf8();
    _bindings.nvSetTxtimeout(_handle!, ptr);
    malloc.free(ptr);
  }

  void setToggleTx(bool enabled) {
    if (_handle == null) return;
    _bindings.nvSetToggletx(_handle!, enabled ? 1 : 0);
  }

  void setXrf2Ref(bool enabled) {
    if (_handle == null) return;
    _bindings.nvSetXrf2ref(_handle!, enabled ? 1 : 0);
  }

  void setIpv6(bool enabled) {
    if (_handle == null) return;
    _bindings.nvSetIpv6(_handle!, enabled ? 1 : 0);
  }

  void setVocoder(String vocoder) {
    if (_handle == null) return;
    final ptr = vocoder.toNativeUtf8();
    _bindings.nvSetVocoder(_handle!, ptr);
    malloc.free(ptr);
  }

  void setModem(String modem) {
    if (_handle == null) return;
    final ptr = modem.toNativeUtf8();
    _bindings.nvSetModem(_handle!, ptr);
    malloc.free(ptr);
  }

  void setPlayback(String device) {
    if (_handle == null) return;
    final ptr = device.toNativeUtf8();
    _bindings.nvSetPlayback(_handle!, ptr);
    malloc.free(ptr);
  }

  void setCapture(String device) {
    if (_handle == null) return;
    final ptr = device.toNativeUtf8();
    _bindings.nvSetCapture(_handle!, ptr);
    malloc.free(ptr);
  }

  void setDmrTgid(String tgid) {
    if (_handle == null) return;
    final ptr = tgid.toNativeUtf8();
    _bindings.nvSetDmrtgid(_handle!, ptr);
    malloc.free(ptr);
  }

  void setSlot(int slot) {
    if (_handle == null) return;
    _bindings.nvSetSlot(_handle!, slot);
  }

  void setCc(int cc) {
    if (_handle == null) return;
    _bindings.nvSetCc(_handle!, cc);
  }

  void setDebug(bool enabled) {
    if (_handle == null) return;
    _bindings.nvSetDebug(_handle!, enabled ? 1 : 0);
  }

  void setPttKey(int key) {
    if (_handle == null) return;
    _bindings.nvSetPttKey(_handle!, key);
  }

  // Getters wrapper
  List<String> getHosts() {
    if (_handle == null) return [];
    const bufSize = 1048576; // 1 MB
    final buf = malloc<Char>(bufSize);
    final res = _bindings.nvGetHosts(_handle!, buf.cast<Utf8>(), bufSize);
    debugPrint('Dart getHosts: res = $res');
    if (res < 0) {
      malloc.free(buf);
      return [];
    }
    final jsonStr = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    try {
      final decoded = json.decode(jsonStr) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      debugPrint('Dart getHosts decode error: $e');
      return [];
    }
  }

  List<String> getVocoders() {
    if (_handle == null) return [];
    final buf = malloc<Char>(2048);
    final res = _bindings.nvGetVocoders(_handle!, buf.cast<Utf8>(), 2048);
    if (res < 0) {
      malloc.free(buf);
      return [];
    }
    final jsonStr = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    try {
      final decoded = json.decode(jsonStr) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  List<String> getModems() {
    if (_handle == null) return [];
    final buf = malloc<Char>(2048);
    final res = _bindings.nvGetModems(_handle!, buf.cast<Utf8>(), 2048);
    if (res < 0) {
      malloc.free(buf);
      return [];
    }
    final jsonStr = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    try {
      final decoded = json.decode(jsonStr) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  List<String> getPlaybacks() {
    if (_handle == null) return [];
    final buf = malloc<Char>(4096);
    final res = _bindings.nvGetPlaybacks(_handle!, buf.cast<Utf8>(), 4096);
    if (res < 0) {
      malloc.free(buf);
      return [];
    }
    final jsonStr = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    try {
      final decoded = json.decode(jsonStr) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  List<String> getCaptures() {
    if (_handle == null) return [];
    final buf = malloc<Char>(4096);
    final res = _bindings.nvGetCaptures(_handle!, buf.cast<Utf8>(), 4096);
    if (res < 0) {
      malloc.free(buf);
      return [];
    }
    final jsonStr = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    try {
      final decoded = json.decode(jsonStr) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  // Individual Value Getters
  String getMode() {
    if (_handle == null) return '';
    final buf = malloc<Char>(256);
    _bindings.nvGetMode(_handle!, buf.cast<Utf8>(), 256);
    final res = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    return res;
  }

  String getHost() {
    if (_handle == null) return '';
    final buf = malloc<Char>(512);
    _bindings.nvGetHost(_handle!, buf.cast<Utf8>(), 512);
    final res = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    return res;
  }

  String getModule() {
    if (_handle == null) return '';
    final buf = malloc<Char>(128);
    _bindings.nvGetModule(_handle!, buf.cast<Utf8>(), 128);
    final res = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    return res;
  }

  String getCallsign() {
    if (_handle == null) return '';
    final buf = malloc<Char>(256);
    _bindings.nvGetCallsign(_handle!, buf.cast<Utf8>(), 256);
    final res = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    return res;
  }

  String getDmrId() {
    if (_handle == null) return '';
    final buf = malloc<Char>(256);
    _bindings.nvGetDmrid(_handle!, buf.cast<Utf8>(), 256);
    final res = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    return res;
  }

  String getEssid() {
    if (_handle == null) return '';
    final buf = malloc<Char>(256);
    _bindings.nvGetEssid(_handle!, buf.cast<Utf8>(), 256);
    final res = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    return res;
  }

  String getBmPassword() {
    if (_handle == null) return '';
    final buf = malloc<Char>(256);
    _bindings.nvGetBmPassword(_handle!, buf.cast<Utf8>(), 256);
    final res = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    return res;
  }

  String getTgifPassword() {
    if (_handle == null) return '';
    final buf = malloc<Char>(256);
    _bindings.nvGetTgifPassword(_handle!, buf.cast<Utf8>(), 256);
    final res = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    return res;
  }

  String getAslPassword() {
    if (_handle == null) return '';
    final buf = malloc<Char>(256);
    _bindings.nvGetAslPassword(_handle!, buf.cast<Utf8>(), 256);
    final res = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    return res;
  }

  String getAmbeStatusTxt() {
    if (_handle == null) return '';
    final buf = malloc<Char>(512);
    _bindings.nvGetAmbestatustxt(_handle!, buf.cast<Utf8>(), 512);
    final res = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    return res;
  }

  String getMmdvmStatusTxt() {
    if (_handle == null) return '';
    final buf = malloc<Char>(512);
    _bindings.nvGetMmdvmstatustxt(_handle!, buf.cast<Utf8>(), 512);
    final res = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    return res;
  }

  String getNetStatusTxt() {
    if (_handle == null) return '';
    final buf = malloc<Char>(512);
    _bindings.nvGetNetstatustxt(_handle!, buf.cast<Utf8>(), 512);
    final res = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    return res;
  }

  String getErrorText() {
    if (_handle == null) return '';
    final buf = malloc<Char>(1024);
    _bindings.nvGetErrorText(_handle!, buf.cast<Utf8>(), 1024);
    final res = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    return res;
  }

  String getDmrTgid() {
    if (_handle == null) return '';
    final buf = malloc<Char>(256);
    _bindings.nvGetDmrtgid(_handle!, buf.cast<Utf8>(), 256);
    final res = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    return res;
  }

  int getPttKey() {
    if (_handle == null) return 0;
    return _bindings.nvGetPttKey(_handle!);
  }

  int getOutputLevel() {
    if (_handle == null) return 0;
    return _bindings.nvGetOutputLevel(_handle!);
  }

  // Memory & Stations
  void saveMemory(int index, String mode, String host, int slot, int cc, String tgid) {
    if (_handle == null) return;
    final modePtr = mode.toNativeUtf8();
    final hostPtr = host.toNativeUtf8();
    final tgidPtr = tgid.toNativeUtf8();
    _bindings.nvSaveMemory(_handle!, index, modePtr, hostPtr, slot, cc, tgidPtr);
    malloc.free(modePtr);
    malloc.free(hostPtr);
    malloc.free(tgidPtr);
  }

  Map<String, dynamic> getMemory(int index) {
    if (_handle == null) return {};
    final buf = malloc<Char>(4096);
    final res = _bindings.nvGetMemory(_handle!, index, buf.cast<Utf8>(), 4096);
    if (res < 0) {
      malloc.free(buf);
      return {};
    }
    final jsonStr = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    try {
      return json.decode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  String readStationLog() {
    if (_handle == null) return '';
    final buf = malloc<Char>(16384);
    _bindings.nvReadStationLog(_handle!, buf.cast<Utf8>(), 16384);
    final res = buf.cast<Utf8>().toDartString();
    malloc.free(buf);
    return res;
  }

  void clearStationLog() {
    if (_handle == null) return;
    _bindings.nvClearStationLog(_handle!);
  }
}
