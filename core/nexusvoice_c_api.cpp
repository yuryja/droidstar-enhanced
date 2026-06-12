#include "nexusvoice_c_api.h"
#include "droidstar.h"
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QByteArray>
#include <QStringList>
#include <QObject>
#include <QCoreApplication>
#include <QThread>
#include <functional>
#include <thread>
#include <chrono>
#include <atomic>

static QCoreApplication* qt_app = nullptr;

struct nv_context {
    DroidStar* instance;
    QThread* creator_thread;

    nv_status_cb status_cb = nullptr;
    void* status_cb_userdata = nullptr;
    nv_data_cb data_cb = nullptr;
    void* data_cb_userdata = nullptr;
    nv_log_cb log_cb = nullptr;
    void* log_cb_userdata = nullptr;
    nv_file_downloaded_cb file_downloaded_cb = nullptr;
    void* file_downloaded_cb_userdata = nullptr;
    nv_devices_changed_cb devices_cb = nullptr;
    void* devices_cb_userdata = nullptr;

    std::atomic<bool> _running{false};
    std::thread _event_thread;

    nv_context()
        : instance(new DroidStar())
        , creator_thread(QThread::currentThread())
    {
        setup_connections();
        _start_event_loop();
    }

    ~nv_context() {
        _stop_event_loop();
        if (QThread::currentThread() != creator_thread) {
            QMetaObject::invokeMethod(QCoreApplication::instance(), [this]() {
                delete instance;
            }, Qt::BlockingQueuedConnection);
        } else {
            delete instance;
        }
    }

    void _start_event_loop() {
        _running = true;
        _event_thread = std::thread([this]() {
            while (_running) {
                if (QCoreApplication::instance()) {
                    QCoreApplication::processEvents(QEventLoop::AllEvents, 15);
                }
                std::this_thread::sleep_for(std::chrono::milliseconds(20));
            }
        });
    }

    void _stop_event_loop() {
        _running = false;
        if (_event_thread.joinable()) {
            _event_thread.join();
        }
    }

    bool is_creator_thread() const {
        return QThread::currentThread() == creator_thread;
    }

    // Fire-and-forget dispatch to creator thread
    void async(std::function<void()> fn) {
        if (is_creator_thread()) {
            fn();
        } else {
            QMetaObject::invokeMethod(QCoreApplication::instance(), std::move(fn), Qt::QueuedConnection);
        }
    }

    // Blocking dispatch to creator thread (for getters that need return values)
    void sync(std::function<void()> fn) {
        if (is_creator_thread()) {
            fn();
        } else {
            QMetaObject::invokeMethod(QCoreApplication::instance(), std::move(fn), Qt::BlockingQueuedConnection);
        }
    }

    void setup_connections() {
        instance->on_status_changed = [this](int c) {
            if (status_cb) {
                const char* msg = "";
                if (c == 0) msg = "Disconnected";
                else if (c == 1) msg = "Connecting";
                else if (c == 2) msg = "Connected";
                else if (c == 4) msg = "Authentication Failed";
                else if (c == 5) msg = "Connection Error";
                status_cb(c, msg, status_cb_userdata);
            }
        };

        instance->on_log = [this](const QString& s) {
            if (log_cb) {
                QByteArray utf8 = s.toUtf8();
                log_cb(utf8.constData(), log_cb_userdata);
            }
        };

        instance->on_data = [this]() {
            if (data_cb) {
                auto send = [this](const char* label, const QString& val) {
                    QByteArray utf8 = val.toUtf8();
                    data_cb(label, utf8.constData(), data_cb_userdata);
                };
                send("label1", instance->get_label1());
                send("label2", instance->get_label2());
                send("label3", instance->get_label3());
                send("label4", instance->get_label4());
                send("label5", instance->get_label5());
                send("label6", instance->get_label6());
                send("data1", instance->get_data1());
                send("data2", instance->get_data2());
                send("data3", instance->get_data3());
                send("data4", instance->get_data4());
                send("data5", instance->get_data5());
                send("data6", instance->get_data6());
                send("ambestatustxt", instance->get_ambestatustxt());
                send("mmdvmstatustxt", instance->get_mmdvmstatustxt());
                send("netstatustxt", instance->get_netstatustxt());
            }
        };

        instance->on_devices_changed = [this]() {
            if (devices_cb) {
                devices_cb(devices_cb_userdata);
            }
        };
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

// Setters
template<typename Setter>
static void setter_str(nv_context* ctx, Setter setter, const char* val) {
    if (!ctx) return;
    QString v = QString::fromUtf8(val);
    ctx->async([ctx, setter, v = std::move(v)]() { (ctx->instance->*setter)(v); });
}
static void setter_int(nv_context* ctx, void (DroidStar::*setter)(int), int val) {
    if (!ctx) return;
    ctx->async([ctx, setter, val]() { (ctx->instance->*setter)(val); });
}
static void setter_dbl(nv_context* ctx, void (DroidStar::*setter)(double), double val) {
    if (!ctx) return;
    ctx->async([ctx, setter, val]() { (ctx->instance->*setter)(val); });
}
static void setter_bool(nv_context* ctx, void (DroidStar::*setter)(bool), int val) {
    if (!ctx) return;
    ctx->async([ctx, setter, b = val != 0]() { (ctx->instance->*setter)(b); });
}

#define NV_SETTER_STR(name, droid_method) \
    NV_EXPORT void nv_set_##name(nv_handle h, const char* val) { setter_str(static_cast<nv_context*>(h), &DroidStar::droid_method, val); }

#define NV_SETTER_INT(name, droid_method) \
    NV_EXPORT void nv_set_##name(nv_handle h, int val) { setter_int(static_cast<nv_context*>(h), &DroidStar::droid_method, val); }

#define NV_SETTER_DBL(name, droid_method) \
    NV_EXPORT void nv_set_##name(nv_handle h, double val) { setter_dbl(static_cast<nv_context*>(h), &DroidStar::droid_method, val); }

#define NV_SETTER_BOOL(name, droid_method) \
    NV_EXPORT void nv_set_##name(nv_handle h, int val) { setter_bool(static_cast<nv_context*>(h), &DroidStar::droid_method, val); }

// Getters (JSON formatted lists)
static int json_list_getter(nv_context* ctx, QStringList (DroidStar::*getter)() const, char* out_buf, int buf_size) {
    if (!ctx) return -1;
    QStringList list;
    ctx->sync([ctx, getter, &list]() { list = (ctx->instance->*getter)(); });
    QJsonArray arr;
    for (const QString& s : list) arr.append(s);
    return copy_json_to_buf(QJsonDocument(arr), out_buf, buf_size);
}

// Getters (individual strings/values)
static int str_getter(nv_context* ctx, QString (DroidStar::*getter)() const, char* out_buf, int buf_size) {
    if (!ctx) return -1;
    QString val;
    ctx->sync([ctx, getter, &val]() { val = (ctx->instance->*getter)(); });
    return copy_to_buf(val, out_buf, buf_size);
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
    if (h) delete static_cast<nv_context*>(h);
}

NV_EXPORT void nv_ptt_start(nv_handle h) {
    if (!h) return;
    auto* ctx = static_cast<nv_context*>(h);
    ctx->async([ctx]() { ctx->instance->press_tx(); });
}

NV_EXPORT void nv_ptt_stop(nv_handle h) {
    if (!h) return;
    auto* ctx = static_cast<nv_context*>(h);
    ctx->async([ctx]() { ctx->instance->release_tx(); });
}

NV_EXPORT void nv_ptt_click(nv_handle h, int pressed) {
    if (!h) return;
    auto* ctx = static_cast<nv_context*>(h);
    ctx->async([ctx, p = pressed != 0]() { ctx->instance->click_tx(p); });
}

NV_EXPORT void nv_process_connect(nv_handle h) {
    if (!h) return;
    auto* ctx = static_cast<nv_context*>(h);
    ctx->async([ctx]() { ctx->instance->process_connect(); });
}

NV_EXPORT void nv_process_settings(nv_handle h) {
    if (!h) return;
    auto* ctx = static_cast<nv_context*>(h);
    ctx->async([ctx]() { ctx->instance->process_settings(); });
}

NV_EXPORT void nv_check_host_files(nv_handle h) {
    if (!h) return;
    auto* ctx = static_cast<nv_context*>(h);
    ctx->async([ctx]() { ctx->instance->check_host_files(); });
}

NV_EXPORT void nv_update_host_files(nv_handle h) {
    if (!h) return;
    auto* ctx = static_cast<nv_context*>(h);
    ctx->async([ctx]() { ctx->instance->update_host_files(); });
}

NV_EXPORT void nv_update_dmr_ids(nv_handle h) {
    if (!h) return;
    auto* ctx = static_cast<nv_context*>(h);
    ctx->async([ctx]() { ctx->instance->update_dmr_ids(); });
}

NV_EXPORT void nv_process_mode_change(nv_handle h, const char* mode) {
    if (!h) return;
    auto* ctx = static_cast<nv_context*>(h);
    QString m = QString::fromUtf8(mode);
    ctx->async([ctx, m = std::move(m)]() { ctx->instance->process_mode_change(m); });
}

NV_EXPORT void nv_process_host_change(nv_handle h, const char* host) {
    if (!h) return;
    auto* ctx = static_cast<nv_context*>(h);
    QString hst = QString::fromUtf8(host);
    ctx->async([ctx, hst = std::move(hst)]() { ctx->instance->process_host_change(hst); });
}

NV_SETTER_STR(callsign, set_callsign)
NV_SETTER_STR(dmrid, set_dmrid)
NV_SETTER_STR(essid, set_essid)
NV_SETTER_STR(bm_password, set_bm_password)
NV_SETTER_STR(tgif_password, set_tgif_password)
NV_SETTER_STR(asl_password, set_asl_password)
NV_SETTER_STR(latitude, set_latitude)
NV_SETTER_STR(longitude, set_longitude)
NV_SETTER_STR(location, set_location)
NV_SETTER_STR(description, set_description)
NV_SETTER_STR(freq, set_freq)
NV_SETTER_STR(url, set_url)
NV_SETTER_STR(swid, set_swid)
NV_SETTER_STR(pkgid, set_pkgid)
NV_SETTER_STR(dmr_options, set_dmr_options)
NV_SETTER_INT(dmr_pc, set_dmr_pc)
NV_SETTER_STR(module, set_module)
NV_SETTER_STR(protocol, set_protocol)
NV_SETTER_DBL(input_volume, set_input_volume)
NV_SETTER_DBL(output_volume, set_output_volume)
NV_SETTER_STR(mycall, set_mycall)
NV_SETTER_STR(urcall, set_urcall)
NV_SETTER_STR(rptr1, set_rptr1)
NV_SETTER_STR(rptr2, set_rptr2)
NV_SETTER_STR(usrtxt, set_usrtxt)
NV_SETTER_STR(txtimeout, set_txtimeout)
NV_SETTER_BOOL(toggletx, set_toggletx)
NV_SETTER_BOOL(xrf2ref, set_xrf2ref)
NV_SETTER_BOOL(ipv6, set_ipv6)
NV_SETTER_STR(vocoder, set_vocoder)
NV_SETTER_STR(modem, set_modem)
NV_SETTER_STR(playback, set_playback)
NV_SETTER_STR(capture, set_capture)
NV_SETTER_STR(dmrtgid, set_dmrtgid)
NV_SETTER_INT(slot, set_slot)
NV_SETTER_INT(cc, set_cc)
NV_SETTER_BOOL(debug, set_debug)
NV_SETTER_INT(ptt_key, set_ptt_key)

NV_EXPORT int nv_get_hosts(nv_handle h, char* out_buf, int buf_size) {
    return json_list_getter(static_cast<nv_context*>(h), &DroidStar::get_hosts, out_buf, buf_size);
}

NV_EXPORT int nv_get_vocoders(nv_handle h, char* out_buf, int buf_size) {
    return json_list_getter(static_cast<nv_context*>(h), &DroidStar::get_vocoders, out_buf, buf_size);
}

NV_EXPORT int nv_get_modems(nv_handle h, char* out_buf, int buf_size) {
    return json_list_getter(static_cast<nv_context*>(h), &DroidStar::get_modems, out_buf, buf_size);
}

NV_EXPORT int nv_get_playbacks(nv_handle h, char* out_buf, int buf_size) {
    return json_list_getter(static_cast<nv_context*>(h), &DroidStar::get_playbacks, out_buf, buf_size);
}

NV_EXPORT int nv_get_captures(nv_handle h, char* out_buf, int buf_size) {
    return json_list_getter(static_cast<nv_context*>(h), &DroidStar::get_captures, out_buf, buf_size);
}

NV_EXPORT int nv_get_mode(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_mode, out_buf, buf_size);
}

NV_EXPORT int nv_get_host(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_host, out_buf, buf_size);
}

NV_EXPORT int nv_get_module(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_module, out_buf, buf_size);
}

NV_EXPORT int nv_get_callsign(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_callsign, out_buf, buf_size);
}

NV_EXPORT int nv_get_dmrid(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_dmrid, out_buf, buf_size);
}

NV_EXPORT int nv_get_essid(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_essid, out_buf, buf_size);
}

NV_EXPORT int nv_get_bm_password(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_bm_password, out_buf, buf_size);
}

NV_EXPORT int nv_get_tgif_password(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_tgif_password, out_buf, buf_size);
}

NV_EXPORT int nv_get_asl_password(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_asl_password, out_buf, buf_size);
}

NV_EXPORT int nv_get_ambestatustxt(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_ambestatustxt, out_buf, buf_size);
}

NV_EXPORT int nv_get_mmdvmstatustxt(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_mmdvmstatustxt, out_buf, buf_size);
}

NV_EXPORT int nv_get_netstatustxt(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_netstatustxt, out_buf, buf_size);
}

NV_EXPORT int nv_get_error_text(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_error_text, out_buf, buf_size);
}

NV_EXPORT int nv_get_dmrtgid(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_dmrtgid, out_buf, buf_size);
}

NV_EXPORT int nv_get_vocoder(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_vocoder, out_buf, buf_size);
}

NV_EXPORT int nv_get_playback(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_playback, out_buf, buf_size);
}

NV_EXPORT int nv_get_capture(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_capture, out_buf, buf_size);
}

NV_EXPORT int nv_get_latitude(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_latitude, out_buf, buf_size);
}

NV_EXPORT int nv_get_longitude(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_longitude, out_buf, buf_size);
}

NV_EXPORT int nv_get_location(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_location, out_buf, buf_size);
}

NV_EXPORT int nv_get_description(nv_handle h, char* out_buf, int buf_size) {
    return str_getter(static_cast<nv_context*>(h), &DroidStar::get_description, out_buf, buf_size);
}

NV_EXPORT int nv_get_ptt_key(nv_handle h) {
    if (!h) return 0;
    auto* ctx = static_cast<nv_context*>(h);
    int result = 0;
    ctx->sync([ctx, &result]() { result = ctx->instance->get_ptt_key(); });
    return result;
}

NV_EXPORT int nv_get_output_level(nv_handle h) {
    if (!h) return 0;
    auto* ctx = static_cast<nv_context*>(h);
    int result = 0;
    ctx->sync([ctx, &result]() { result = ctx->instance->get_output_level(); });
    return result;
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

NV_EXPORT void nv_set_devices_cb(nv_handle h, nv_devices_changed_cb cb, void* userdata) {
    if (h) {
        nv_context* ctx = static_cast<nv_context*>(h);
        ctx->devices_cb = cb;
        ctx->devices_cb_userdata = userdata;
    }
}

// Event loop
NV_EXPORT void nv_pump_events(nv_handle h) {
    (void)h;
    if (QCoreApplication::instance()) {
        QCoreApplication::processEvents();
    }
}

// Memory / Station Log
NV_EXPORT void nv_save_memory(nv_handle h, int index, const char* mode, const char* host, int slot, int cc, const char* tgid) {
    if (!h) return;
    auto* ctx = static_cast<nv_context*>(h);
    QString m = QString::fromUtf8(mode);
    QString hst = QString::fromUtf8(host);
    QString tg = QString::fromUtf8(tgid);
    ctx->async([ctx, index, m = std::move(m), hst = std::move(hst), slot, cc, tg = std::move(tg)]() {
        ctx->instance->save_memory(index, m, hst, slot, cc, tg);
    });
}

NV_EXPORT int nv_get_memory(nv_handle h, int index, char* out_buf, int buf_size) {
    if (!h) return -1;
    auto* ctx = static_cast<nv_context*>(h);
    QVariantMap map;
    ctx->sync([ctx, index, &map]() { map = ctx->instance->get_memory(index); });
    QJsonObject obj = QJsonObject::fromVariantMap(map);
    return copy_json_to_buf(QJsonDocument(obj), out_buf, buf_size);
}

NV_EXPORT int nv_read_station_log(nv_handle h, char* out_buf, int buf_size) {
    if (!h) return -1;
    auto* ctx = static_cast<nv_context*>(h);
    QString log;
    ctx->sync([ctx, &log]() { log = ctx->instance->readStationLog(); });
    return copy_to_buf(log, out_buf, buf_size);
}

NV_EXPORT void nv_clear_station_log(nv_handle h) {
    if (!h) return;
    auto* ctx = static_cast<nv_context*>(h);
    ctx->async([ctx]() { ctx->instance->clearStationLog(); });
}

}
