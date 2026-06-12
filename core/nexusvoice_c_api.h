#ifndef NEXUSVOICE_C_API_H
#define NEXUSVOICE_C_API_H

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32)
#  define NV_EXPORT __declspec(dllexport)
#else
#  define NV_EXPORT __attribute__((visibility("default")))
#endif

typedef void* nv_handle;

// Callbacks
typedef void (*nv_status_cb)(int status_code, const char* msg, void* userdata);
typedef void (*nv_data_cb)(const char* label, const char* value, void* userdata);
typedef void (*nv_log_cb)(const char* line, void* userdata);
typedef void (*nv_file_downloaded_cb)(const char* filename, void* userdata);

// Lifecycle
NV_EXPORT nv_handle nv_create(void);
NV_EXPORT void      nv_destroy(nv_handle h);

// PTT & Connection
NV_EXPORT void nv_ptt_start(nv_handle h);
NV_EXPORT void nv_ptt_stop(nv_handle h);
NV_EXPORT void nv_ptt_click(nv_handle h, int pressed);
NV_EXPORT void nv_process_connect(nv_handle h);
NV_EXPORT void nv_process_settings(nv_handle h);
NV_EXPORT void nv_check_host_files(nv_handle h);
NV_EXPORT void nv_update_host_files(nv_handle h);
NV_EXPORT void nv_update_dmr_ids(nv_handle h);
NV_EXPORT void nv_process_mode_change(nv_handle h, const char* mode);
NV_EXPORT void nv_process_host_change(nv_handle h, const char* host);

// Settings setters
NV_EXPORT void nv_set_callsign(nv_handle h, const char* callsign);
NV_EXPORT void nv_set_dmrid(nv_handle h, const char* dmrid);
NV_EXPORT void nv_set_essid(nv_handle h, const char* essid);
NV_EXPORT void nv_set_bm_password(nv_handle h, const char* pwd);
NV_EXPORT void nv_set_tgif_password(nv_handle h, const char* pwd);
NV_EXPORT void nv_set_asl_password(nv_handle h, const char* pwd);
NV_EXPORT void nv_set_latitude(nv_handle h, const char* lat);
NV_EXPORT void nv_set_longitude(nv_handle h, const char* lon);
NV_EXPORT void nv_set_location(nv_handle h, const char* loc);
NV_EXPORT void nv_set_description(nv_handle h, const char* desc);
NV_EXPORT void nv_set_freq(nv_handle h, const char* freq);
NV_EXPORT void nv_set_url(nv_handle h, const char* url);
NV_EXPORT void nv_set_swid(nv_handle h, const char* swid);
NV_EXPORT void nv_set_pkgid(nv_handle h, const char* pkgid);
NV_EXPORT void nv_set_dmr_options(nv_handle h, const char* opts);
NV_EXPORT void nv_set_dmr_pc(nv_handle h, int pc);
NV_EXPORT void nv_set_module(nv_handle h, const char* module);
NV_EXPORT void nv_set_protocol(nv_handle h, const char* protocol);
NV_EXPORT void nv_set_input_volume(nv_handle h, double v);
NV_EXPORT void nv_set_output_volume(nv_handle h, double v);
NV_EXPORT void nv_set_mycall(nv_handle h, const char* call);
NV_EXPORT void nv_set_urcall(nv_handle h, const char* call);
NV_EXPORT void nv_set_rptr1(nv_handle h, const char* rptr);
NV_EXPORT void nv_set_rptr2(nv_handle h, const char* rptr);
NV_EXPORT void nv_set_usrtxt(nv_handle h, const char* txt);
NV_EXPORT void nv_set_txtimeout(nv_handle h, const char* t);
NV_EXPORT void nv_set_toggletx(nv_handle h, int x);
NV_EXPORT void nv_set_xrf2ref(nv_handle h, int x);
NV_EXPORT void nv_set_ipv6(nv_handle h, int x);
NV_EXPORT void nv_set_vocoder(nv_handle h, const char* vocoder);
NV_EXPORT void nv_set_modem(nv_handle h, const char* modem);
NV_EXPORT void nv_set_playback(nv_handle h, const char* device);
NV_EXPORT void nv_set_capture(nv_handle h, const char* device);
NV_EXPORT void nv_set_dmrtgid(nv_handle h, const char* tgid);
NV_EXPORT void nv_set_slot(nv_handle h, int slot);
NV_EXPORT void nv_set_cc(nv_handle h, int cc);
NV_EXPORT void nv_set_debug(nv_handle h, int debug);
NV_EXPORT void nv_set_ptt_key(nv_handle h, int key);

// Getters (JSON formatted lists)
NV_EXPORT int nv_get_hosts(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_vocoders(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_modems(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_playbacks(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_captures(nv_handle h, char* out_buf, int buf_size);

// Getters (individual strings/values)
NV_EXPORT int nv_get_mode(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_host(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_module(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_callsign(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_dmrid(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_essid(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_bm_password(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_tgif_password(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_asl_password(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_ambestatustxt(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_mmdvmstatustxt(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_netstatustxt(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_error_text(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_dmrtgid(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT int nv_get_ptt_key(nv_handle h);

NV_EXPORT int nv_get_output_level(nv_handle h);

// Registering Callbacks
NV_EXPORT void nv_set_status_cb(nv_handle h, nv_status_cb cb, void* userdata);
NV_EXPORT void nv_set_data_cb(nv_handle h, nv_data_cb cb, void* userdata);
NV_EXPORT void nv_set_log_cb(nv_handle h, nv_log_cb cb, void* userdata);
NV_EXPORT void nv_set_file_downloaded_cb(nv_handle h, nv_file_downloaded_cb cb, void* userdata);

// Memory / Station Log
NV_EXPORT void nv_save_memory(nv_handle h, int index, const char* mode, const char* host, int slot, int cc, const char* tgid);
NV_EXPORT int  nv_get_memory(nv_handle h, int index, char* out_buf, int buf_size);
NV_EXPORT int  nv_read_station_log(nv_handle h, char* out_buf, int buf_size);
NV_EXPORT void nv_clear_station_log(nv_handle h);

#ifdef __cplusplus
}
#endif

#endif // NEXUSVOICE_C_API_H
