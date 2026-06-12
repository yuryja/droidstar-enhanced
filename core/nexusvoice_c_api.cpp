#include "nexusvoice_c_api.h"
#include "droidstar.h"
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QByteArray>
#include <QStringList>
#include <QObject>
#include <QCoreApplication>

static QCoreApplication* qt_app = nullptr;

// Context structure holding the DroidStar instance and callback bindings
struct nv_context {
    DroidStar* instance;
    nv_status_cb status_cb = nullptr;
    void* status_cb_userdata = nullptr;
    nv_data_cb data_cb = nullptr;
    void* data_cb_userdata = nullptr;
    nv_log_cb log_cb = nullptr;
    void* log_cb_userdata = nullptr;
    nv_file_downloaded_cb file_downloaded_cb = nullptr;
    void* file_downloaded_cb_userdata = nullptr;

    nv_context() {
        instance = new DroidStar();
        setup_connections();
    }

    ~nv_context() {
        delete instance;
    }

    void setup_connections() {
        QObject::connect(instance, &DroidStar::connect_status_changed, [this](int c) {
            if (status_cb) {
                QString msg = "";
                if (c == 0) msg = "Disconnected";
                else if (c == 1) msg = "Connecting";
                else if (c == 2) msg = "Connected";
                else if (c == 4) msg = "Authentication Failed";
                else if (c == 5) msg = "Connection Error";
                status_cb(c, msg.toUtf8().constData(), status_cb_userdata);
            }
        });

        QObject::connect(instance, &DroidStar::update_log, [this](QString s) {
            if (log_cb) {
                log_cb(s.toUtf8().constData(), log_cb_userdata);
            }
        });

        QObject::connect(instance, static_cast<void (DroidStar::*)()>(&DroidStar::update_data), [this]() {
            if (data_cb) {
                data_cb("label1", instance->get_label1().toUtf8().constData(), data_cb_userdata);
                data_cb("label2", instance->get_label2().toUtf8().constData(), data_cb_userdata);
                data_cb("label3", instance->get_label3().toUtf8().constData(), data_cb_userdata);
                data_cb("label4", instance->get_label4().toUtf8().constData(), data_cb_userdata);
                data_cb("label5", instance->get_label5().toUtf8().constData(), data_cb_userdata);
                data_cb("label6", instance->get_label6().toUtf8().constData(), data_cb_userdata);
                data_cb("data1", instance->get_data1().toUtf8().constData(), data_cb_userdata);
                data_cb("data2", instance->get_data2().toUtf8().constData(), data_cb_userdata);
                data_cb("data3", instance->get_data3().toUtf8().constData(), data_cb_userdata);
                data_cb("data4", instance->get_data4().toUtf8().constData(), data_cb_userdata);
                data_cb("data5", instance->get_data5().toUtf8().constData(), data_cb_userdata);
                data_cb("data6", instance->get_data6().toUtf8().constData(), data_cb_userdata);
                data_cb("ambestatustxt", instance->get_ambestatustxt().toUtf8().constData(), data_cb_userdata);
                data_cb("mmdvmstatustxt", instance->get_mmdvmstatustxt().toUtf8().constData(), data_cb_userdata);
                data_cb("netstatustxt", instance->get_netstatustxt().toUtf8().constData(), data_cb_userdata);
            }
        });
    }
};

// Helper to copy QString to out_buf safely
static int copy_to_buf(const QString& s, char* out_buf, int buf_size) {
    QByteArray ba = s.toUtf8();
    if (ba.size() >= buf_size) {
        if (buf_size > 0) {
            strncpy(out_buf, ba.constData(), buf_size - 1);
            out_buf[buf_size - 1] = '\0';
        }
        return -1;
    }
    strcpy(out_buf, ba.constData());
    return ba.size();
}

// Helper to copy QJsonDocument to out_buf safely
static int copy_json_to_buf(const QJsonDocument& doc, char* out_buf, int buf_size) {
    QByteArray ba = doc.toJson(QJsonDocument::Compact);
    if (ba.size() >= buf_size) {
        if (buf_size > 0) {
            strncpy(out_buf, ba.constData(), buf_size - 1);
            out_buf[buf_size - 1] = '\0';
        }
        return -1;
    }
    strcpy(out_buf, ba.constData());
    return ba.size();
}

extern "C" {

NV_EXPORT nv_handle nv_create(void) {
    if (!QCoreApplication::instance()) {
        static int argc = 1;
        static char* argv[] = { (char*)"nexusvoice_core", nullptr };
        qt_app = new QCoreApplication(argc, argv);
    }
    return new nv_context();
}

NV_EXPORT void nv_destroy(nv_handle h) {
    if (h) {
        delete static_cast<nv_context*>(h);
    }
}

NV_EXPORT void nv_ptt_start(nv_handle h) {
    if (h) static_cast<nv_context*>(h)->instance->press_tx();
}

NV_EXPORT void nv_ptt_stop(nv_handle h) {
    if (h) static_cast<nv_context*>(h)->instance->release_tx();
}

NV_EXPORT void nv_ptt_click(nv_handle h, int pressed) {
    if (h) static_cast<nv_context*>(h)->instance->click_tx(pressed != 0);
}

NV_EXPORT void nv_process_connect(nv_handle h) {
    if (h) static_cast<nv_context*>(h)->instance->process_connect();
}

NV_EXPORT void nv_process_settings(nv_handle h) {
    if (h) static_cast<nv_context*>(h)->instance->process_settings();
}

NV_EXPORT void nv_check_host_files(nv_handle h) {
    if (h) static_cast<nv_context*>(h)->instance->check_host_files();
}

NV_EXPORT void nv_update_host_files(nv_handle h) {
    if (h) static_cast<nv_context*>(h)->instance->update_host_files();
}

NV_EXPORT void nv_update_dmr_ids(nv_handle h) {
    if (h) static_cast<nv_context*>(h)->instance->update_dmr_ids();
}

NV_EXPORT void nv_process_mode_change(nv_handle h, const char* mode) {
    if (h) static_cast<nv_context*>(h)->instance->process_mode_change(QString::fromUtf8(mode));
}

NV_EXPORT void nv_process_host_change(nv_handle h, const char* host) {
    if (h) static_cast<nv_context*>(h)->instance->process_host_change(QString::fromUtf8(host));
}

// Setters
NV_EXPORT void nv_set_callsign(nv_handle h, const char* callsign) {
    if (h) static_cast<nv_context*>(h)->instance->set_callsign(QString::fromUtf8(callsign));
}

NV_EXPORT void nv_set_dmrid(nv_handle h, const char* dmrid) {
    if (h) static_cast<nv_context*>(h)->instance->set_dmrid(QString::fromUtf8(dmrid));
}

NV_EXPORT void nv_set_essid(nv_handle h, const char* essid) {
    if (h) static_cast<nv_context*>(h)->instance->set_essid(QString::fromUtf8(essid));
}

NV_EXPORT void nv_set_bm_password(nv_handle h, const char* pwd) {
    if (h) static_cast<nv_context*>(h)->instance->set_bm_password(QString::fromUtf8(pwd));
}

NV_EXPORT void nv_set_tgif_password(nv_handle h, const char* pwd) {
    if (h) static_cast<nv_context*>(h)->instance->set_tgif_password(QString::fromUtf8(pwd));
}

NV_EXPORT void nv_set_asl_password(nv_handle h, const char* pwd) {
    if (h) static_cast<nv_context*>(h)->instance->set_asl_password(QString::fromUtf8(pwd));
}

NV_EXPORT void nv_set_latitude(nv_handle h, const char* lat) {
    if (h) static_cast<nv_context*>(h)->instance->set_latitude(QString::fromUtf8(lat));
}

NV_EXPORT void nv_set_longitude(nv_handle h, const char* lon) {
    if (h) static_cast<nv_context*>(h)->instance->set_longitude(QString::fromUtf8(lon));
}

NV_EXPORT void nv_set_location(nv_handle h, const char* loc) {
    if (h) static_cast<nv_context*>(h)->instance->set_location(QString::fromUtf8(loc));
}

NV_EXPORT void nv_set_description(nv_handle h, const char* desc) {
    if (h) static_cast<nv_context*>(h)->instance->set_description(QString::fromUtf8(desc));
}

NV_EXPORT void nv_set_freq(nv_handle h, const char* freq) {
    if (h) static_cast<nv_context*>(h)->instance->set_freq(QString::fromUtf8(freq));
}

NV_EXPORT void nv_set_url(nv_handle h, const char* url) {
    if (h) static_cast<nv_context*>(h)->instance->set_url(QString::fromUtf8(url));
}

NV_EXPORT void nv_set_swid(nv_handle h, const char* swid) {
    if (h) static_cast<nv_context*>(h)->instance->set_swid(QString::fromUtf8(swid));
}

NV_EXPORT void nv_set_pkgid(nv_handle h, const char* pkgid) {
    if (h) static_cast<nv_context*>(h)->instance->set_pkgid(QString::fromUtf8(pkgid));
}

NV_EXPORT void nv_set_dmr_options(nv_handle h, const char* opts) {
    if (h) static_cast<nv_context*>(h)->instance->set_dmr_options(QString::fromUtf8(opts));
}

NV_EXPORT void nv_set_dmr_pc(nv_handle h, int pc) {
    if (h) static_cast<nv_context*>(h)->instance->set_dmr_pc(pc);
}

NV_EXPORT void nv_set_module(nv_handle h, const char* module) {
    if (h) static_cast<nv_context*>(h)->instance->set_module(QString::fromUtf8(module));
}

NV_EXPORT void nv_set_protocol(nv_handle h, const char* protocol) {
    if (h) static_cast<nv_context*>(h)->instance->set_protocol(QString::fromUtf8(protocol));
}

NV_EXPORT void nv_set_input_volume(nv_handle h, double v) {
    if (h) static_cast<nv_context*>(h)->instance->set_input_volume(v);
}

NV_EXPORT void nv_set_output_volume(nv_handle h, double v) {
    if (h) static_cast<nv_context*>(h)->instance->set_output_volume(v);
}

NV_EXPORT void nv_set_mycall(nv_handle h, const char* call) {
    if (h) static_cast<nv_context*>(h)->instance->set_mycall(QString::fromUtf8(call));
}

NV_EXPORT void nv_set_urcall(nv_handle h, const char* call) {
    if (h) static_cast<nv_context*>(h)->instance->set_urcall(QString::fromUtf8(call));
}

NV_EXPORT void nv_set_rptr1(nv_handle h, const char* rptr) {
    if (h) static_cast<nv_context*>(h)->instance->set_rptr1(QString::fromUtf8(rptr));
}

NV_EXPORT void nv_set_rptr2(nv_handle h, const char* rptr) {
    if (h) static_cast<nv_context*>(h)->instance->set_rptr2(QString::fromUtf8(rptr));
}

NV_EXPORT void nv_set_usrtxt(nv_handle h, const char* txt) {
    if (h) static_cast<nv_context*>(h)->instance->set_usrtxt(QString::fromUtf8(txt));
}

NV_EXPORT void nv_set_txtimeout(nv_handle h, const char* t) {
    if (h) static_cast<nv_context*>(h)->instance->set_txtimeout(QString::fromUtf8(t));
}

NV_EXPORT void nv_set_toggletx(nv_handle h, int x) {
    if (h) static_cast<nv_context*>(h)->instance->set_toggletx(x != 0);
}

NV_EXPORT void nv_set_xrf2ref(nv_handle h, int x) {
    if (h) static_cast<nv_context*>(h)->instance->set_xrf2ref(x != 0);
}

NV_EXPORT void nv_set_ipv6(nv_handle h, int x) {
    if (h) static_cast<nv_context*>(h)->instance->set_ipv6(x != 0);
}

NV_EXPORT void nv_set_vocoder(nv_handle h, const char* vocoder) {
    if (h) static_cast<nv_context*>(h)->instance->set_vocoder(QString::fromUtf8(vocoder));
}

NV_EXPORT void nv_set_modem(nv_handle h, const char* modem) {
    if (h) static_cast<nv_context*>(h)->instance->set_modem(QString::fromUtf8(modem));
}

NV_EXPORT void nv_set_playback(nv_handle h, const char* device) {
    if (h) static_cast<nv_context*>(h)->instance->set_playback(QString::fromUtf8(device));
}

NV_EXPORT void nv_set_capture(nv_handle h, const char* device) {
    if (h) static_cast<nv_context*>(h)->instance->set_capture(QString::fromUtf8(device));
}

NV_EXPORT void nv_set_dmrtgid(nv_handle h, const char* tgid) {
    if (h) static_cast<nv_context*>(h)->instance->set_dmrtgid(QString::fromUtf8(tgid));
}

NV_EXPORT void nv_set_slot(nv_handle h, int slot) {
    if (h) static_cast<nv_context*>(h)->instance->set_slot(slot);
}

NV_EXPORT void nv_set_cc(nv_handle h, int cc) {
    if (h) static_cast<nv_context*>(h)->instance->set_cc(cc);
}

NV_EXPORT void nv_set_debug(nv_handle h, int debug) {
    if (h) static_cast<nv_context*>(h)->instance->set_debug(debug != 0);
}

NV_EXPORT void nv_set_ptt_key(nv_handle h, int key) {
    if (h) static_cast<nv_context*>(h)->instance->set_ptt_key(key);
}

// Getters (JSON formatted lists)
NV_EXPORT int nv_get_hosts(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    QStringList list = static_cast<nv_context*>(h)->instance->get_hosts();
    QJsonArray arr;
    for (const QString& s : list) arr.append(s);
    return copy_json_to_buf(QJsonDocument(arr), out_buf, buf_size);
}

NV_EXPORT int nv_get_vocoders(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    QStringList list = static_cast<nv_context*>(h)->instance->get_vocoders();
    QJsonArray arr;
    for (const QString& s : list) arr.append(s);
    return copy_json_to_buf(QJsonDocument(arr), out_buf, buf_size);
}

NV_EXPORT int nv_get_modems(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    QStringList list = static_cast<nv_context*>(h)->instance->get_modems();
    QJsonArray arr;
    for (const QString& s : list) arr.append(s);
    return copy_json_to_buf(QJsonDocument(arr), out_buf, buf_size);
}

NV_EXPORT int nv_get_playbacks(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    QStringList list = static_cast<nv_context*>(h)->instance->get_playbacks();
    QJsonArray arr;
    for (const QString& s : list) arr.append(s);
    return copy_json_to_buf(QJsonDocument(arr), out_buf, buf_size);
}

NV_EXPORT int nv_get_captures(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    QStringList list = static_cast<nv_context*>(h)->instance->get_captures();
    QJsonArray arr;
    for (const QString& s : list) arr.append(s);
    return copy_json_to_buf(QJsonDocument(arr), out_buf, buf_size);
}

// Getters (individual strings/values)
NV_EXPORT int nv_get_mode(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    return copy_to_buf(static_cast<nv_context*>(h)->instance->get_mode(), out_buf, buf_size);
}

NV_EXPORT int nv_get_host(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    return copy_to_buf(static_cast<nv_context*>(h)->instance->get_host(), out_buf, buf_size);
}

NV_EXPORT int nv_get_module(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    return copy_to_buf(static_cast<nv_context*>(h)->instance->get_module(), out_buf, buf_size);
}

NV_EXPORT int nv_get_callsign(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    return copy_to_buf(static_cast<nv_context*>(h)->instance->get_callsign(), out_buf, buf_size);
}

NV_EXPORT int nv_get_dmrid(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    return copy_to_buf(static_cast<nv_context*>(h)->instance->get_dmrid(), out_buf, buf_size);
}

NV_EXPORT int nv_get_essid(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    return copy_to_buf(static_cast<nv_context*>(h)->instance->get_essid(), out_buf, buf_size);
}

NV_EXPORT int nv_get_ambestatustxt(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    return copy_to_buf(static_cast<nv_context*>(h)->instance->get_ambestatustxt(), out_buf, buf_size);
}

NV_EXPORT int nv_get_mmdvmstatustxt(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    return copy_to_buf(static_cast<nv_context*>(h)->instance->get_mmdvmstatustxt(), out_buf, buf_size);
}

NV_EXPORT int nv_get_netstatustxt(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    return copy_to_buf(static_cast<nv_context*>(h)->instance->get_netstatustxt(), out_buf, buf_size);
}

NV_EXPORT int nv_get_error_text(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    return copy_to_buf(static_cast<nv_context*>(h)->instance->get_error_text(), out_buf, buf_size);
}

NV_EXPORT int nv_get_dmrtgid(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    return copy_to_buf(static_cast<nv_context*>(h)->instance->get_dmrtgid(), out_buf, buf_size);
}

NV_EXPORT int nv_get_ptt_key(nv_handle h) {
    if (!h) return 0;
    return static_cast<nv_context*>(h)->instance->get_ptt_key();
}

NV_EXPORT int nv_get_output_level(nv_handle h) {
    if (QCoreApplication::instance()) {
        QCoreApplication::processEvents();
    }
    if (!h) return 0;
    return static_cast<nv_context*>(h)->instance->get_output_level();
}

// Registering Callbacks
NV_EXPORT void nv_set_status_cb(nv_handle h, nv_status_cb cb, void* userdata) {
    if (h) {
        nv_context* ctx = static_cast<nv_context*>(h);
        ctx->status_cb = cb;
        ctx->status_cb_userdata = userdata;
    }
}

NV_EXPORT void nv_set_data_cb(nv_handle h, nv_data_cb cb, void* userdata) {
    if (h) {
        nv_context* ctx = static_cast<nv_context*>(h);
        ctx->data_cb = cb;
        ctx->data_cb_userdata = userdata;
    }
}

NV_EXPORT void nv_set_log_cb(nv_handle h, nv_log_cb cb, void* userdata) {
    if (h) {
        nv_context* ctx = static_cast<nv_context*>(h);
        ctx->log_cb = cb;
        ctx->log_cb_userdata = userdata;
    }
}

NV_EXPORT void nv_set_file_downloaded_cb(nv_handle h, nv_file_downloaded_cb cb, void* userdata) {
    if (h) {
        nv_context* ctx = static_cast<nv_context*>(h);
        ctx->file_downloaded_cb = cb;
        ctx->file_downloaded_cb_userdata = userdata;
    }
}

// Memory / Station Log
NV_EXPORT void nv_save_memory(nv_handle h, int index, const char* mode, const char* host, int slot, int cc, const char* tgid) {
    if (h) {
        static_cast<nv_context*>(h)->instance->save_memory(index, QString::fromUtf8(mode), QString::fromUtf8(host), slot, cc, QString::fromUtf8(tgid));
    }
}

NV_EXPORT int nv_get_memory(nv_handle h, int index, char* out_buf, int buf_size) {
    if (!h) return -1;
    QVariantMap map = static_cast<nv_context*>(h)->instance->get_memory(index);
    QJsonObject obj = QJsonObject::fromVariantMap(map);
    return copy_json_to_buf(QJsonDocument(obj), out_buf, buf_size);
}

NV_EXPORT int nv_read_station_log(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    return copy_to_buf(static_cast<nv_context*>(h)->instance->readStationLog(), out_buf, buf_size);
}

NV_EXPORT void nv_clear_station_log(nv_handle h) {
    if (h) static_cast<nv_context*>(h)->instance->clearStationLog();
}

}
