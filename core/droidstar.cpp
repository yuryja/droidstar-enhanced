/*
	Copyright (C) 2019-2021 Doug McLain

	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#include "droidstar.h"
#include "httplib.h"

#ifdef Q_OS_ANDROID
#include <QCoreApplication>
#include <QJniObject>
#include <QtCore/private/qandroidextras_p.h>
#endif
#include <QStandardPaths>
#include <QKeySequence>
#include <QFont>
#include <QFontDatabase>
#include <filesystem>
#include <QSslSocket>
#include <cstring>
#include <fcntl.h>
#include <fstream>
namespace fs = std::filesystem;

static QStringList read_lines(const QString& path) {
    QStringList lines;
    std::ifstream f(path.toStdString());
    std::string line;
    while (std::getline(f, line))
        lines << QString::fromStdString(line);
    return lines;
}

static QString jstr(const nlohmann::json& j, const char* key, const char* def = "") {
    auto it = j.find(key);
    if (it != j.end() && it->is_string())
        return QString::fromStdString(*it);
    return QString::fromStdString(def);
}

DroidStar::DroidStar(QObject *parent) :
	QObject(parent),
	m_dmrid(0),
	m_essid(0),
	m_dmr_destid(0),
	m_outlevel(0),
    m_mdirect(false),
    m_tts(0)
{
	m_vocoder = "Software vocoder";
	qRegisterMetaType<Mode::MODEINFO>("Mode::MODEINFO");
	m_settings_processed = false;
	m_modelchange = false;
	connect_status = Mode::DISCONNECTED;
	config_path = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
#if !defined(Q_OS_ANDROID) && !defined(Q_OS_WIN)
	config_path += "/nexusvoice";
#endif
	m_settings_path = config_path + "/settings.json";
	load_settings_file();
#if defined(Q_OS_ANDROID)
	keepScreenOn();
    m_USBmonitor = &AndroidSerialPort::GetInstance();
    connect(m_USBmonitor, SIGNAL(devices_changed()), this, SLOT(discover_devices()));
#endif
	check_host_files();

	qDebug() << "CPU arch: " << QSysInfo::currentCpuArchitecture();
	qDebug() << "Build ABI: " << QSysInfo::buildAbi();
	qDebug() << "boot ID: " << QSysInfo::bootUniqueId();
	qDebug() << "Pretty name: " << QSysInfo::prettyProductName();
	qDebug() << "Type: " << QSysInfo::productType();
	qDebug() << "Version: " << QSysInfo::productVersion();
	qDebug() << "Kernel type: " << QSysInfo::kernelType();
	qDebug() << "Kernel version: " << QSysInfo::kernelVersion();
    qDebug() << "Software version: " << VERSION_NUMBER;
    qDebug() << "OpenSSL: " << QSslSocket::supportsSsl();

	// discover_devices() is deferred — miniaudio enumeration can block 1-2s on macOS.
	// process_settings() runs now since the Flutter UI reads settings immediately.
	process_settings();

	qDebug() << "CPU arch: " << QSysInfo::currentCpuArchitecture();
	qDebug() << "Build ABI: " << QSysInfo::buildAbi();
	qDebug() << "boot ID: " << QSysInfo::bootUniqueId();
	qDebug() << "Pretty name: " << QSysInfo::prettyProductName();
	qDebug() << "Type: " << QSysInfo::productType();
	qDebug() << "Version: " << QSysInfo::productVersion();
	qDebug() << "Kernel type: " << QSysInfo::kernelType();
	qDebug() << "Kernel version: " << QSysInfo::kernelVersion();
    qDebug() << "Software version: " << VERSION_NUMBER;
    qDebug() << "OpenSSL: " << QSslSocket::supportsSsl();

	// Discover audio devices in a background thread so nv_create() does not block
	// the Flutter UI. ma_context_init() can block 1-2 seconds on macOS CoreAudio.
	// Device list updates are dispatched to the Qt event loop thread.
	std::thread([this]() {
		auto playbacks = AudioEngine::discover_audio_devices(AUDIO_OUT);
		auto captures  = AudioEngine::discover_audio_devices(AUDIO_IN);
		if (auto* app = QCoreApplication::instance()) {
			QMetaObject::invokeMethod(app, [this, pb = std::move(playbacks), cap = std::move(captures)]() {
				m_playbacks.clear();
				m_captures.clear();
				m_vocoders.clear();
				m_modems.clear();
				m_playbacks.append("OS Default");
				m_captures.append("OS Default");
				m_vocoders.append("Software vocoder");
				m_vocoders.append("None");
				m_modems.append("None");
				for (const auto& d : pb) m_playbacks.append(QString::fromStdString(d));
				for (const auto& d : cap) m_captures.append(QString::fromStdString(d));
#if !defined(Q_OS_IOS)
				auto devs = SerialAMBE::discoverDevices();
				for (const auto& d : devs) {
					m_vocoders.append(QString::fromStdString(d.second));
					m_modems.append(QString::fromStdString(d.second));
				}
#endif
				emit update_devices();
				if (on_devices_changed) on_devices_changed();
			}, Qt::QueuedConnection);
		}
	}).detach();
}

DroidStar::~DroidStar()
{
	save_settings_file();
}

#include <QtQml>
void register_droidstar_qml_types() {
    qmlRegisterType<DroidStar>("org.dudetronics.droidstar", 1, 0, "DroidStar");
}

#ifdef Q_OS_ANDROID
using namespace Qt::StringLiterals;

void DroidStar::keepScreenOn()
{
    QMicrophonePermission microphonePermission;
    if (qApp->checkPermission(microphonePermission) != Qt::PermissionStatus::Granted) {
        qApp->requestPermission(microphonePermission, this, &DroidStar::keepScreenOn);
        return;
    }
	char const * const action = "addFlags";
	QNativeInterface::QAndroidApplication::runOnAndroidMainThread([action](){
	QJniObject activity = QNativeInterface::QAndroidApplication::context();
	if (activity.isValid()) {
		QJniObject window = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");

		if (window.isValid()) {
            const int FLAG_KEEP_SCREEN_ON = 0x00000080;
			window.callMethod<void>("addFlags", "(I)V", FLAG_KEEP_SCREEN_ON);
		}
	}});
/*
    QMicrophonePermission microphonePermission;
    if (qApp->checkPermission(microphonePermission) != Qt::PermissionStatus::Granted) {
        qApp->requestPermission(microphonePermission, this, &DroidStar::keepScreenOn);
    }
*/
    if (QNativeInterface::QAndroidApplication::sdkVersion() >= __ANDROID_API_T__) {
        const auto notificationPermission = "android.permission.POST_NOTIFICATIONS"_L1;
        auto requestResult = QtAndroidPrivate::requestPermission(notificationPermission);
        if (requestResult.result() != QtAndroidPrivate::Authorized) {
            qWarning() << "Failed to acquire permission to post notifications "
                          "(required for Android 13+)";
        }
    }
}
#endif

void DroidStar::discover_devices()
{
	m_playbacks.clear();
	m_captures.clear();
	m_vocoders.clear();
	m_modems.clear();
	m_playbacks.append("OS Default");
	m_captures.append("OS Default");
	m_vocoders.append("Software vocoder");
    m_vocoders.append("None");
	m_modems.append("None");
	for (const auto& d : AudioEngine::discover_audio_devices(AUDIO_OUT)) {
		m_playbacks.append(QString::fromStdString(d));
	}
	for (const auto& d : AudioEngine::discover_audio_devices(AUDIO_IN)) {
		m_captures.append(QString::fromStdString(d));
	}
#if !defined(Q_OS_IOS)
	auto devs = SerialAMBE::discoverDevices();
	for (const auto& d : devs) {
		m_vocoders.append(QString::fromStdString(d.second));
		m_modems.append(QString::fromStdString(d.second));
	}
    emit update_devices();
#endif
    if (on_devices_changed) on_devices_changed();
}

void DroidStar::log_msg(const QString& s)
{
	if (on_log) on_log(s);
	log_msg(s);
}

void DroidStar::download_file(const QString& url, const QString& dest_name)
{
	std::thread t([this, url, dest_name]() {
		try {
			QString dest_file = config_path + "/" + dest_name;

			// Strip scheme and split into host + path
			bool use_ssl = url.startsWith("https://");
			QString stripped = url;
			if (stripped.startsWith("https://")) stripped = stripped.mid(8);
			else if (stripped.startsWith("http://")) stripped = stripped.mid(7);

			int slash_pos = stripped.indexOf('/');
			QString host_part = (slash_pos >= 0) ? stripped.left(slash_pos) : stripped;
			QString path_part = (slash_pos >= 0) ? stripped.mid(slash_pos) : "/";

			std::string host = host_part.toStdString();
			std::string path = path_part.toStdString();

			std::string body;
			int status = -1;

#ifdef CPPHTTPLIB_OPENSSL_SUPPORT
			if (use_ssl) {
				httplib::SSLClient cli(host);
				cli.set_follow_location(true);
				cli.set_connection_timeout(15);
				cli.set_read_timeout(60);
				cli.enable_server_certificate_verification(false);
				auto res = cli.Get(path);
				if (res) { status = res->status; body = res->body; }
			} else
#endif
			{
				httplib::Client cli(host);
				cli.set_follow_location(true);
				cli.set_connection_timeout(15);
				cli.set_read_timeout(60);
				auto res = cli.Get(path);
				if (res) { status = res->status; body = res->body; }
			}

			if (status == 200 && !body.empty()) {
				std::ofstream out(dest_file.toStdString(), std::ios::binary);
				if (out.is_open()) {
					out.write(body.data(), (std::streamsize)body.size());
					out.close();
					qDebug() << "download_file: saved" << dest_file << "(" << body.size() << "bytes)";
					QMetaObject::invokeMethod(this, [this, dest_name]() {
						file_downloaded(dest_name);
					});
				}
			} else {
				qDebug() << "download_file: failed for" << url << "status:" << status;
			}
		} catch (const std::exception& e) {
			qDebug() << "download_file exception:" << e.what();
		} catch (...) {
			qDebug() << "download_file: unknown exception, thread exiting safely";
		}
	});
	t.detach();
}

void DroidStar::url_downloaded(QString url)
{
	log_msg("Downloaded " + url);
}

void DroidStar::file_downloaded(QString filename)
{
	log_msg("Updated " + filename);
	{
		if(filename == "dplus.txt" && m_protocol == "REF"){
            process_dstar_hosts(m_protocol);
		}
		else if(filename == "dextra.txt" && m_protocol == "XRF"){
            process_dstar_hosts(m_protocol);
		}
		else if(filename == "dcs.txt" && m_protocol == "DCS"){
            process_dstar_hosts(m_protocol);
		}
		else if(filename == "YSFHosts.txt" && m_protocol == "YSF"){
			process_ysf_hosts();
		}
		else if(filename == "FCSHosts.txt" && m_protocol == "FCS"){
			process_fcs_rooms();
		}
		else if(filename == "P25Hosts.txt" && m_protocol == "P25"){
			process_p25_hosts();
		}
		else if(filename == "DMRHosts.txt" && m_protocol == "DMR"){
			process_dmr_hosts();
		}
		else if(filename == "NXDNHosts.txt" && m_protocol == "NXDN"){
			process_nxdn_hosts();
		}
		else if(filename == "M17Hosts-full.csv" && m_protocol == "M17"){
			process_m17_hosts();
		}
		else if(filename == "ASLHosts.txt" && m_protocol == "IAX"){
			process_asl_hosts();
		}
		else if(filename == "DMRIDs.dat"){
			process_dmr_ids();
		}
		else if(filename == "NXDN.csv"){
			process_nxdn_ids();
		}
	}
}

void DroidStar::dtmf_send_clicked(QString dtmf)
{
	QByteArray tx(dtmf.simplified().toUtf8(), dtmf.simplified().size());
	emit send_dtmf(tx);
}

void DroidStar::tts_changed(QString tts)
{
	if(tts == "Mic"){
		m_tts = 0;
	}
	else if(tts == "TTS1"){
		m_tts = 1;
	}
	else if(tts == "TTS2"){
		m_tts = 2;
	}
	else if(tts == "TTS3"){
		m_tts = 3;
	}
	else{
		m_tts = 0;
	}
	emit input_source_changed(m_tts, m_ttstxt);
}

void DroidStar::tts_text_changed(QString ttstxt)
{
	m_ttstxt = ttstxt;
	emit input_source_changed(m_tts, m_ttstxt);
}

void DroidStar::obtain_asl_wt_creds()
{
	QNetworkAccessManager *manager = new QNetworkAccessManager(this);
	QUrl url("https://www.allstarlink.org/portal/login.php");
	QNetworkRequest request(url);
	request.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

	QByteArray postData;
	postData.append("user=" + QUrl::toPercentEncoding(m_callsign.toUtf8()));
	postData.append("&pass=" + QUrl::toPercentEncoding(m_asl_password.toUtf8()));

	connect(manager, &QNetworkAccessManager::finished, this, [=](QNetworkReply *reply) {
		if (reply->error() == QNetworkReply::NoError) {
			QUrl url("https://www.allstarlink.org/portal/webtransceiver.php?node=12345");
			QNetworkRequest request(url);
			
			connect(manager, &QNetworkAccessManager::finished, this, [=](QNetworkReply *reply) {
				if (reply->error() == QNetworkReply::NoError) {
					QString html = reply->readAll();
					QStringList l = html.split('\n');
					for (int i = 0; i < l.size(); i++) {
						if (l.at(i).contains("callingName")) {
							QStringList ll = l.at(i).split('"');
							m_wt_callingname = ll.at(3);
							m_wt_callingname_pass = m_asl_password;
                            manager->disconnect();
                            qDebug() << "ASL authentication complete";
                            process_connect();
							break;
						}
					}
				} else {
                    qDebug() << "Error: " << reply->errorString();
                    m_errortxt = "ASL WT authentication failed";
                    if (on_status_changed) on_status_changed(5); emit connect_status_changed(5);
				}
				reply->deleteLater();
			});

			manager->get(request);
		} else {
            qDebug() << "Error: " << reply->errorString();
            m_errortxt = "ASL WT login failed";
            if (on_status_changed) on_status_changed(5); emit connect_status_changed(5);
		}
		reply->deleteLater();
	});

	manager->post(request, postData);
}

void DroidStar::process_connect()
{
	if(connect_status != Mode::DISCONNECTED){
        if(connect_status == Mode::TIMEOUT){
            m_errortxt = "Connection timed out";
            if (on_status_changed) on_status_changed(5); emit connect_status_changed(5);
        }
		connect_status = Mode::DISCONNECTED;
		if (m_threadRunning) {
			m_threadRunning = false;
			if (m_mode) m_mode->stop_loop();
			if (m_modethread && m_modethread->joinable())
				m_modethread->join();
			delete m_modethread;
			m_modethread = nullptr;
			m_mode = nullptr;
			if (on_status_changed) on_status_changed(0);
			log_msg("Disconnected");
		}
		m_data1.clear();
		m_data2.clear();
		m_data3.clear();
		m_data4.clear();
		m_data5.clear();
		m_data6.clear();
#ifdef Q_OS_ANDROID
        QJniObject::callStaticMethod<void>(
            "org/dudetronics/droidstar/NotificationClient",
            "denotify",
            "(Landroid/content/Context;)V",
            QNativeInterface::QAndroidApplication::context());
#endif
	}
	else{
		if(m_protocol == "REF"){
			m_refname = m_saved_refhost;
		}
		else if(m_protocol == "DCS"){
			m_refname = m_saved_dcshost;
		}
		else if(m_protocol == "XRF"){
			m_refname = m_saved_xrfhost;
		}
		else if(m_protocol == "YSF"){
			m_refname = m_saved_ysfhost;
		}
		else if(m_protocol == "FCS"){
			m_refname = m_saved_fcshost;
		}
		else if(m_protocol == "DMR"){
			m_refname = m_saved_dmrhost;
		}
		else if(m_protocol == "P25"){
			m_refname = m_saved_p25host;
		}
		else if(m_protocol == "NXDN"){
			m_refname = m_saved_nxdnhost;
		}
		else if(m_protocol == "M17"){
			m_refname = m_saved_m17host;
        }
        else if(m_protocol == "IAX"){
            m_refname = m_saved_iaxhost;
            if ((m_hostmap[m_refname].contains(".nodes.allstarlink.org")) && (m_wt_callingname.isEmpty() || (m_asl_password != m_wt_callingname_pass))) {
                obtain_asl_wt_creds();
                return;
            }
        }

		connect_status = Mode::CONNECTING;
		QStringList sl;

        m_host = m_hostmap[m_refname];
        sl = m_host.split(',');

        if( (m_protocol == "M17") && !m_mdirect && (m_ipv6) && (sl.size() > 2) && (sl.at(2) != "none") ){
            m_host = sl.at(2).simplified();
            m_port = sl.at(1).toInt();
        }
        else if(sl.size() > 1){
            m_host = sl.at(0).simplified();
            m_port = sl.at(1).toInt();
        }
        else if( (m_protocol == "M17") && m_mdirect ){
            qDebug() << "Going MMDVM_DIRECT";
        }
        else{
            m_errortxt = "Invalid host selection";
            connect_status = Mode::DISCONNECTED;
            if (on_status_changed) on_status_changed(5); emit connect_status_changed(5);
            return;
        }

		QString vocoder = m_vocoder;
		if( (m_vocoder != "None") && (m_vocoder != "Software vocoder") && (m_vocoder.contains(':') ) ){
			QStringList vl = m_vocoder.split(':');
			vocoder = vl.at(1);
		}
		QString modem = "";
		if( (m_modem != "None") && (m_modem.contains(':')) ){
			QStringList ml = m_modem.split(':');
			modem = ml.at(1);
		}

		const bool txInvert = true;
		const bool rxInvert = false;
		const bool pttInvert = false;
		const bool useCOSAsLockout = 0;
		const uint32_t ysfTXHang = 4;
		const float pocsagTXLevel = 50;
		const float m17TXLevel = 50;
		const bool duplex = m_modemRxFreq.toUInt() != m_modemTxFreq.toUInt();
		const int rxfreq = m_modemRxFreq.toInt() + m_modemRxOffset.toInt();
		const int txfreq = m_modemTxFreq.toInt() + m_modemTxOffset.toInt();

		log_msg("Connecting to " + m_host + ":" + QString::number(m_port) + "...");

		uint16_t nxdnid = m_nxdnids.key(m_callsign);

		m_mode = Mode::create_mode(m_protocol.toStdString());

        if(m_protocol == "IAX"){
            QString iaxuser = sl.at(2).simplified();
            QString iaxpass = sl.at(3).simplified();
            m_mode->set_iax_params(iaxuser, iaxpass, m_wt_callingname, m_refname, m_host, m_port);
            connect(this, &DroidStar::send_dtmf, this, [this](QByteArray d) {
                if (m_mode) m_mode->post_cmd([this, d]() { m_mode->send_dtmf(d); });
            });
        }

        m_mode->init(m_callsign, m_dmrid, nxdnid, m_module, m_refname.toStdString(), m_host.toStdString(), m_port, m_ipv6, vocoder.toStdString(), modem.toStdString(), m_capture.toStdString(), m_playback.toStdString(), m_mdirect);
		m_mode->set_modem_flags(rxInvert, txInvert, pttInvert, useCOSAsLockout, duplex);
		m_mode->set_modem_params(m_modemBaud.toUInt(), rxfreq, txfreq, m_modemTxDelay.toInt(), m_modemRxLevel.toFloat(), m_modemRFLevel.toFloat(), ysfTXHang, m_modemCWIdTxLevel.toFloat(), m_modemDstarTxLevel.toFloat(), m_modemDMRTxLevel.toFloat(), m_modemYSFTxLevel.toFloat(), m_modemP25TxLevel.toFloat(), m_modemNXDNTxLevel.toFloat(), pocsagTXLevel, m17TXLevel);

        m_mode->m_cb_update = [this](Mode::MODEINFO info) {
            QMetaObject::invokeMethod(this, [this, info]() { update_data(info); });
        };
        m_mode->m_cb_log = [this](const std::string& msg) {
            QMetaObject::invokeMethod(this, [this, msg]() { updatelog(QString::fromStdString(msg)); });
        };
		m_mode->m_cb_output_level = [this](unsigned short lvl) {
            QMetaObject::invokeMethod(this, [this, lvl]() { update_output_level(lvl); });
        };
        connect(this, &DroidStar::module_changed, this, [this](char m) {
            if (m_mode) m_mode->post_cmd([this, m]() { m_mode->module_changed(m); });
        });
        connect(this, &DroidStar::input_source_changed, this, [this](int id, QString t) {
            if (m_mode) m_mode->post_cmd([this, id, t]() { m_mode->input_src_changed(id, t.toStdString()); });
        });
        connect(this, &DroidStar::swrx_state_changed, this, [this](int s) {
            if (m_mode) m_mode->post_cmd([this, s]() { m_mode->swrx_state_changed(s); });
        });
        connect(this, &DroidStar::swtx_state_changed, this, [this](int s) {
            if (m_mode) m_mode->post_cmd([this, s]() { m_mode->swtx_state_changed(s); });
        });
        connect(this, &DroidStar::agc_state_changed, this, [this](int s) {
            if (m_mode) m_mode->post_cmd([this, s]() { m_mode->agc_state_changed(s); });
        });
        connect(this, &DroidStar::tx_clicked, this, [this](bool x) {
            if (m_mode) m_mode->post_cmd([this, x]() { m_mode->toggle_tx(x); });
        });
        connect(this, &DroidStar::tx_pressed, this, [this]() {
            if (m_mode) m_mode->post_cmd([this]() { m_mode->start_tx(); });
        });
        connect(this, &DroidStar::tx_released, this, [this]() {
            if (m_mode) m_mode->post_cmd([this]() { m_mode->stop_tx(); });
        });
        connect(this, &DroidStar::in_audio_vol_changed, this, [this](qreal v) {
            if (m_mode) m_mode->post_cmd([this, v]() { m_mode->in_audio_vol_changed(v); });
        });
        connect(this, &DroidStar::out_audio_vol_changed, this, [this](qreal v) {
            if (m_mode) m_mode->post_cmd([this, v]() { m_mode->out_audio_vol_changed(v); });
        });
        connect(this, &DroidStar::mycall_changed, this, [this](QString mc) {
            if (m_mode) m_mode->post_cmd([this, mc]() { m_mode->mycall_changed(mc.toStdString()); });
        });
        connect(this, &DroidStar::urcall_changed, this, [this](QString uc) {
            if (m_mode) m_mode->post_cmd([this, uc]() { m_mode->urcall_changed(uc.toStdString()); });
        });
        connect(this, &DroidStar::rptr1_changed, this, [this](QString r1) {
            if (m_mode) m_mode->post_cmd([this, r1]() { m_mode->rptr1_changed(r1.toStdString()); });
        });
        connect(this, &DroidStar::rptr2_changed, this, [this](QString r2) {
            if (m_mode) m_mode->post_cmd([this, r2]() { m_mode->rptr2_changed(r2.toStdString()); });
        });
        connect(this, &DroidStar::usrtxt_changed, this, [this](QString t) {
            if (m_mode) m_mode->post_cmd([this, t]() { m_mode->usrtxt_changed(t.toStdString()); });
        });
        connect(this, &DroidStar::debug_changed, this, [this](bool debug) {
            if (m_mode) m_mode->post_cmd([this, debug]() { m_mode->debug_changed(debug); });
        });
		// Allow modes to request the main app to toggle the connect button (simulate user)
		m_mode->m_cb_connect_toggle = [this]() {
            QMetaObject::invokeMethod(this, [this]() { process_connect(); });
        };
		m_mode->m_cb_reconnect = [this](int ms) {
            QMetaObject::invokeMethod(this, [this, ms]() { schedule_reconnect(ms); });
        };
        if (on_status_changed) on_status_changed(1); emit connect_status_changed(1);
		m_mode->post_cmd([this]() { m_mode->module_changed(m_module); });
        m_mode->post_cmd([this]() { m_mode->mycall_changed(m_mycall.toStdString()); });
        m_mode->post_cmd([this]() { m_mode->urcall_changed(m_urcall.toStdString()); });
        m_mode->post_cmd([this]() { m_mode->rptr1_changed(m_rptr1.toStdString()); });
        m_mode->post_cmd([this]() { m_mode->rptr2_changed(m_rptr2.toStdString()); });
        m_mode->post_cmd([this]() { m_mode->usrtxt_changed(m_dstarusertxt.toStdString()); });

		if(m_protocol == "DMR"){
			QString dmrpass = sl.at(2).simplified();

			if((m_refname.size() > 2) && (m_refname.left(2) == "BM")){
				if(!m_bm_password.isEmpty()){
					dmrpass = m_bm_password;
				}
			}

			if((m_refname.size() > 4) && (m_refname.left(4) == "TGIF")){
				if(!m_tgif_password.isEmpty()){
					dmrpass = m_tgif_password;
				}
			}
			m_mode->set_dmr_params(m_essid, dmrpass, m_latitude, m_longitude, m_location, m_description, m_freq, m_url, m_swid, m_pkgid, m_dmropts);
			m_mode->set_dmr_cc(m_dmrColorCode);
            connect(this, &DroidStar::dmr_tgid_changed, this, [this](int id) {
                if (m_mode) m_mode->post_cmd([this, id]() { m_mode->dmr_tgid_changed(id); });
            });
            connect(this, &DroidStar::dmrpc_state_changed, this, [this](int p) {
                if (m_mode) m_mode->post_cmd([this, p]() { m_mode->dmrpc_state_changed(p); });
            });
            connect(this, &DroidStar::slot_changed, this, [this](int s) {
                if (m_mode) m_mode->post_cmd([this, s]() { m_mode->slot_changed(s); });
            });
            connect(this, &DroidStar::cc_changed, this, [this](int cc) {
                if (m_mode) m_mode->post_cmd([this, cc]() { m_mode->cc_changed(cc); });
            });
			m_mode->post_cmd([this]() { m_mode->dmr_tgid_changed((int)m_dmr_destid); });
            m_mode->post_cmd([this]() { m_mode->dmrpc_state_changed(m_pc); });
		}

		if(m_protocol == "M17"){
            connect(this, QOverload<int>::of(&DroidStar::m17_rate_changed), this, [this](int r) {
                if (m_mode) m_mode->post_cmd([this, r]() { m_mode->rate_changed(r); });
            });
            connect(this, &DroidStar::m17_can_changed, this, [this](int c) {
                if (m_mode) m_mode->post_cmd([this, c]() { m_mode->can_changed(c); });
            });
            connect(this, &DroidStar::m17_send_sms, this, [this](QString s) {
                if (m_mode) m_mode->post_cmd([this, s]() { m_mode->tx_packet(s.toStdString()); });
            });
            if(m_mdirect){
                connect(this, &DroidStar::dst_changed, this, [this](QString dst) {
                    if (m_mode) m_mode->post_cmd([this, dst]() { m_mode->dst_changed(dst.toStdString()); });
                });
            }
		}

		m_threadRunning = true;
		Mode* captured_mode = m_mode;
		m_modethread = new std::thread([captured_mode]() {
			captured_mode->run_loop();
			captured_mode->disconnect_core();
			delete captured_mode;
		});

	}
/*
	qDebug() << "process_connect called m_callsign == " << m_callsign;
	qDebug() << "process_connect called m_dmrid == " << m_dmrid;
	qDebug() << "process_connect called m_bm_password == " << m_bm_password;
	qDebug() << "process_connect called m_tgif_password == " << m_tgif_password;
	qDebug() << "process_connect called m_dmropts == " << m_dmropts;
	qDebug() << "process_connect called m_refname == " << m_refname;
	qDebug() << "process_connect called m_host == " << m_host;
	qDebug() << "process_connect called m_module == " << m_module;
	qDebug() << "process_connect called m_protocol == " << m_protocol;
	qDebug() << "process_connect called m_port == " << m_port;
*/
}

void DroidStar::schedule_reconnect(int ms)
{
	qDebug() << "schedule_reconnect called, reconnecting in" << ms << "ms";
	QTimer::singleShot(ms, this, SLOT(process_connect()));
}

void DroidStar::process_host_change(const QString &h)
{
	if(m_protocol == "REF"){
		m_saved_refhost = h.simplified();
	}
	if(m_protocol == "DCS"){
		m_saved_dcshost = h.simplified();
	}
	if(m_protocol == "XRF"){
		m_saved_xrfhost = h.simplified();
	}
	if(m_protocol == "YSF"){
		m_saved_ysfhost = h.simplified();
	}
	if(m_protocol == "FCS"){
		m_saved_fcshost = h.simplified();
	}
	if(m_protocol == "DMR"){
		m_saved_dmrhost = h.simplified();
	}
	if(m_protocol == "P25"){
		m_saved_p25host = h.simplified();
	}
	if(m_protocol == "NXDN"){
		m_saved_nxdnhost = h.simplified();
	}
	if(m_protocol == "M17"){
		m_saved_m17host = h.simplified();
	}
	if(m_protocol == "IAX"){
		m_saved_iaxhost = h.simplified();
	}
	save_settings();
}

void DroidStar::process_mode_change(const QString &m)
{
    m_protocol = m;
    if((m == "REF") || (m == "DCS") || (m == "XRF")){
        process_dstar_hosts(m);
        m_label1 = "MYCALL";
        m_label2 = "URCALL";
        m_label3 = "RPTR1";
        m_label4 = "RPTR2";
        m_label5 = "Stream ID";
        m_label6 = "User txt";
    }
	if(m == "YSF"){
		process_ysf_hosts();
		m_label1 = "Gateway";
		m_label2 = "Callsign";
		m_label3 = "Dest";
		m_label4 = "Type";
		m_label5 = "Path";
		m_label6 = "Frame#";
	}
	if(m == "FCS"){
		process_fcs_rooms();
		m_label1 = "Gateway";
		m_label2 = "Callsign";
		m_label3 = "Dest";
		m_label4 = "Type";
		m_label5 = "Path";
		m_label6 = "Frame#";
	}
	if(m == "DMR"){
		process_dmr_hosts();
		//process_dmr_ids();
		m_label1 = "Callsign";
		m_label2 = "SrcID";
		m_label3 = "DestID";
		m_label4 = "GWID";
		m_label5 = "Info";
		m_label6 = "";
	}
	if(m == "P25"){
		process_p25_hosts();
		m_label1 = "Callsign";
		m_label2 = "SrcID";
		m_label3 = "DestID";
		m_label4 = "GWID";
		m_label5 = "Seq#";
		m_label6 = "";
	}
	if(m == "NXDN"){
		process_nxdn_hosts();
		m_label1 = "Callsign";
		m_label2 = "SrcID";
		m_label3 = "DestID";
		m_label4 = "GWID";
		m_label5 = "Seq#";
		m_label6 = "";
	}
	if(m == "M17"){
		process_m17_hosts();
		m_label1 = "SrcID";
		m_label2 = "DstID";
		m_label3 = "Type";
		m_label4 = "Frame#";
		m_label5 = "StreamID";
		m_label6 = "";
	}
	if(m == "IAX"){
        process_iax_hosts();
		m_label1 = "";
		m_label2 = "";
		m_label3 = "";
		m_label4 = "";
		m_label5 = "";
		m_label6 = "";
	}
	emit mode_changed();
}

void DroidStar::load_settings_file()
{
	std::ifstream f(m_settings_path.toStdString());
	if (f.is_open()) {
		try {
			f >> m_json_settings;
		} catch (...) {
			m_json_settings = nlohmann::json::object();
		}
	} else {
		m_json_settings = nlohmann::json::object();
	}
}

void DroidStar::save_settings_file()
{
	// Ensure directory exists
	fs::create_directories(config_path.toStdString());
	std::ofstream f(m_settings_path.toStdString());
	if (f.is_open()) {
		f << m_json_settings.dump(4) << std::endl;
	}
}

void DroidStar::save_settings()
{
	m_json_settings["PLAYBACK"] = m_playback.toStdString();
	m_json_settings["CAPTURE"] = m_capture.toStdString();
	m_json_settings["VOCODER"] = m_vocoder.toStdString();
	m_json_settings["IPV6"] = m_ipv6 ? "true" : "false";
	m_json_settings["MODE"] = m_protocol.toStdString();
	m_json_settings["REFHOST"] = m_saved_refhost.toStdString();
	m_json_settings["DCSHOST"] = m_saved_dcshost.toStdString();
	m_json_settings["XRFHOST"] = m_saved_xrfhost.toStdString();
	m_json_settings["YSFHOST"] = m_saved_ysfhost.toStdString();
	m_json_settings["FCSHOST"] = m_saved_fcshost.toStdString();
	m_json_settings["DMRHOST"] = m_saved_dmrhost.toStdString();
	m_json_settings["P25HOST"] = m_saved_p25host.toStdString();
	m_json_settings["NXDNHOST"] = m_saved_nxdnhost.toStdString();
	m_json_settings["M17HOST"] = m_saved_m17host.toStdString();
	m_json_settings["IAXHOST"] = m_saved_iaxhost.toStdString();
	m_json_settings["MODULE"] = std::string(1, m_module);
	m_json_settings["CALLSIGN"] = m_callsign.toStdString();
	m_json_settings["DMRID"] = QString::number(m_dmrid).toStdString();
	m_json_settings["ESSID"] = QString::number(m_essid).toStdString();
	m_json_settings["BMPASSWORD"] = m_bm_password.toStdString();
	m_json_settings["TGIFPASSWORD"] = m_tgif_password.toStdString();
	m_json_settings["ASLPASSWORD"] = m_asl_password.toStdString();
	m_json_settings["DMRTGID"] = QString::number(m_dmr_destid).toStdString();
	m_json_settings["DMRLAT"] = m_latitude.toStdString();
	m_json_settings["DMRLONG"] = m_longitude.toStdString();
	m_json_settings["DMRLOC"] = m_location.toStdString();
	m_json_settings["DMRDESC"] = m_description.toStdString();
	m_json_settings["DMRFREQ"] = m_freq.toStdString();
	m_json_settings["DMRURL"] = m_url.toStdString();
	m_json_settings["DMRSWID"] = m_swid.toStdString();
	m_json_settings["DMRPKGID"] = m_pkgid.toStdString();
	m_json_settings["DMROPTS"] = m_dmropts.toStdString();
	m_json_settings["MYCALL"] = m_mycall.toStdString();
	m_json_settings["URCALL"] = m_urcall.toStdString();
	m_json_settings["RPTR1"] = m_rptr1.toStdString();
	m_json_settings["RPTR2"] = m_rptr2.toStdString();
	m_json_settings["TXTIMEOUT"] = QString::number(m_txtimeout).toStdString();
	m_json_settings["TXTOGGLE"] = m_toggletx ? "true" : "false";
	m_json_settings["XRF2REF"] = m_xrf2ref ? "true" : "false";
	m_json_settings["USRTXT"] = m_dstarusertxt.toStdString();

	m_json_settings["ModemRxFreq"] = m_modemRxFreq.toStdString();
	m_json_settings["ModemTxFreq"] = m_modemTxFreq.toStdString();
	m_json_settings["ModemRxOffset"] = m_modemRxOffset.toStdString();
	m_json_settings["ModemTxOffset"] = m_modemTxOffset.toStdString();
	m_json_settings["ModemRxDCOffset"] = m_modemRxDCOffset.toStdString();
	m_json_settings["ModemTxDCOffset"] = m_modemTxDCOffset.toStdString();
	m_json_settings["ModemRxLevel"] = m_modemRxLevel.toStdString();
	m_json_settings["ModemTxLevel"] = m_modemTxLevel.toStdString();
	m_json_settings["ModemRFLevel"] = m_modemRFLevel.toStdString();
	m_json_settings["ModemTxDelay"] = m_modemTxDelay.toStdString();
	m_json_settings["ModemCWIdTxLevel"] = m_modemCWIdTxLevel.toStdString();
	m_json_settings["ModemDstarTxLevel"] = m_modemDstarTxLevel.toStdString();
	m_json_settings["ModemDMRTxLevel"] = m_modemDMRTxLevel.toStdString();
	m_json_settings["ModemYSFTxLevel"] = m_modemYSFTxLevel.toStdString();
	m_json_settings["ModemP25TxLevel"] = m_modemP25TxLevel.toStdString();
	m_json_settings["ModemNXDNTxLevel"] = m_modemNXDNTxLevel.toStdString();
	m_json_settings["ModemBaud"] = m_modemBaud.toStdString();
	m_json_settings["ModemM17CAN"] = m_modemM17CAN.toStdString();
	m_json_settings["ModemTxInvert"] = m_modemTxInvert ? "true" : "false";
	m_json_settings["ModemRxInvert"] = m_modemRxInvert ? "true" : "false";
	m_json_settings["ModemPTTInvert"] = m_modemPTTInvert ? "true" : "false";
	m_json_settings["PTT_KEY"] = m_pttKey;
	save_settings_file();
}

void DroidStar::process_settings()
{
	m_playback = jstr(m_json_settings, "PLAYBACK");
	m_capture = jstr(m_json_settings, "CAPTURE");
	m_vocoder = jstr(m_json_settings, "VOCODER", "Software vocoder");
	m_ipv6 = jstr(m_json_settings, "IPV6") == "true";
	process_mode_change(jstr(m_json_settings, "MODE"));
	m_saved_refhost = jstr(m_json_settings, "REFHOST");
	m_saved_dcshost = jstr(m_json_settings, "DCSHOST");
	m_saved_xrfhost = jstr(m_json_settings, "XRFHOST");
	m_saved_ysfhost = jstr(m_json_settings, "YSFHOST");
	m_saved_fcshost = jstr(m_json_settings, "FCSHOST");
	m_saved_dmrhost = jstr(m_json_settings, "DMRHOST");
	m_saved_p25host = jstr(m_json_settings, "P25HOST");
	m_saved_nxdnhost = jstr(m_json_settings, "NXDNHOST");
	m_saved_m17host = jstr(m_json_settings, "M17HOST");
	m_saved_iaxhost = jstr(m_json_settings, "IAXHOST");
	{
		QString mod = jstr(m_json_settings, "MODULE");
		if (!mod.isEmpty()) m_module = mod.toStdString()[0];
	}
	m_callsign = jstr(m_json_settings, "CALLSIGN");
	m_dmrid = jstr(m_json_settings, "DMRID").toUInt();
	m_essid = jstr(m_json_settings, "ESSID").toUInt();
	m_bm_password = jstr(m_json_settings, "BMPASSWORD");
	m_tgif_password = jstr(m_json_settings, "TGIFPASSWORD");
	m_asl_password = jstr(m_json_settings, "ASLPASSWORD");
	m_latitude = jstr(m_json_settings, "DMRLAT", "0");
	m_longitude = jstr(m_json_settings, "DMRLONG", "0");
	m_location = jstr(m_json_settings, "DMRLOC");
	m_description = jstr(m_json_settings, "DMRDESC", "");
	m_freq = jstr(m_json_settings, "DMRFREQ", "438800000");
	m_url = jstr(m_json_settings, "DMRURL", "www.qrz.com");
	m_swid = jstr(m_json_settings, "DMRSWID", "20200922");
	m_pkgid = jstr(m_json_settings, "DMRPKGID", "MMDVM_MMDVM_HS_Hat");
	m_dmropts = jstr(m_json_settings, "DMROPTS");
	m_dmr_destid = jstr(m_json_settings, "DMRTGID", "4000").toUInt();
	m_mycall = jstr(m_json_settings, "MYCALL");
	m_urcall = jstr(m_json_settings, "URCALL", "CQCQCQ");
	m_rptr1 = jstr(m_json_settings, "RPTR1");
	m_rptr2 = jstr(m_json_settings, "RPTR2");
	m_txtimeout = jstr(m_json_settings, "TXTIMEOUT", "300").toUInt();
	m_toggletx = jstr(m_json_settings, "TXTOGGLE", "true") == "true";
	m_dstarusertxt = jstr(m_json_settings, "USRTXT");
	m_xrf2ref = jstr(m_json_settings, "XRF2REF") == "true";
	m_localhosts = jstr(m_json_settings, "LOCALHOSTS");
	{
		auto it = m_json_settings.find("PTT_KEY");
		m_pttKey = (it != m_json_settings.end() && it->is_number()) ? it->get<int>() : 0;
	}

	m_modemRxFreq = jstr(m_json_settings, "ModemRxFreq", "438800000");
	m_modemTxFreq = jstr(m_json_settings, "ModemTxFreq", "438800000");
	m_modemRxOffset = jstr(m_json_settings, "ModemRxOffset", "0");
	m_modemTxOffset = jstr(m_json_settings, "ModemTxOffset", "0");
	m_modemRxDCOffset = jstr(m_json_settings, "ModemRxDCOffset", "0");
	m_modemTxDCOffset = jstr(m_json_settings, "ModemTxDCOffset", "0");
	m_modemRxLevel = jstr(m_json_settings, "ModemRxLevel", "50");
	m_modemTxLevel = jstr(m_json_settings, "ModemTxLevel", "50");
	m_modemRFLevel = jstr(m_json_settings, "ModemRFLevel", "100");
	m_modemTxDelay = jstr(m_json_settings, "ModemTxDelay", "100");
	m_modemCWIdTxLevel = jstr(m_json_settings, "ModemCWIdTxLevel", "50");
	m_modemDstarTxLevel = jstr(m_json_settings, "ModemDstarTxLevel", "50");
	m_modemDMRTxLevel = jstr(m_json_settings, "ModemDMRTxLevel", "50");
	m_modemYSFTxLevel = jstr(m_json_settings, "ModemYSFTxLevel", "50");
	m_modemP25TxLevel = jstr(m_json_settings, "ModemP25TxLevel", "50");
	m_modemNXDNTxLevel = jstr(m_json_settings, "ModemNXDNTxLevel", "50");
	m_modemBaud = jstr(m_json_settings, "ModemBaud", "115200");
	m_modemM17CAN = jstr(m_json_settings, "ModemM17CAN", "0");
	m_modemTxInvert = jstr(m_json_settings, "ModemTxInvert", "true") == "true";
	m_modemRxInvert = jstr(m_json_settings, "ModemRxInvert", "false") == "true";
	m_modemPTTInvert = jstr(m_json_settings, "ModemPTTInvert", "false") == "true";
	emit update_settings();
}

void DroidStar::update_custom_hosts(QString h)
{
	m_json_settings["LOCALHOSTS"] = h.toStdString();
	m_localhosts = h;
	save_settings_file();
}

void DroidStar::process_dstar_hosts(QString m)
{
    m_hostmap.clear();
    m_hostsmodel.clear();
    QString filename, port;
    if(m == "REF"){
        filename = "dplus.txt";
        port = "20001";
    }
    else if(m == "DCS"){
        filename = "dcs.txt";
        port = "30051";
    }
    else if(m == "XRF"){
        filename = "dextra.txt";
        port = "30001";
    }

    QString fpath = config_path + "/" + filename;
    if(fs::exists(fpath.toStdString()) && fs::is_regular_file(fpath.toStdString())){
        for(QString l : read_lines(fpath)){
            if(l.at(0) == '#'){
                continue;
            }
            QStringList ll = l.split('\t');
            if(ll.size() > 1){
                m_hostmap[ll.at(0).simplified()] = ll.at(1).simplified() + "," + port;
            }
        }

        m_customhosts = m_localhosts.split('\n');
        for (const auto& i : std::as_const(m_customhosts)){
            QStringList line = i.simplified().split(' ');

            if(line.at(0) == m){
                m_hostmap[line.at(1).simplified()] = line.at(2).simplified() + "," + line.at(3).simplified();
            }
        }

        QMap<QString, QString>::const_iterator i = m_hostmap.constBegin();
        while (i != m_hostmap.constEnd()) {
            m_hostsmodel.append(i.key());
            ++i;
        }
    }
    else{
        // D-STAR host files from dstarinfo.com
        if (filename == "dplus.txt")
            download_file("https://www.dstarinfo.com/downloads/dplus.txt", "dplus.txt");
        else if (filename == "dcs.txt")
            download_file("https://www.dstarinfo.com/downloads/dcs.txt", "dcs.txt");
        else if (filename == "dextra.txt")
            download_file("https://www.dstarinfo.com/downloads/dextra.txt", "dextra.txt");
    }
}

void DroidStar::process_ysf_hosts()
{
	m_hostmap.clear();
	m_hostsmodel.clear();
	QString fpath = config_path + "/YSFHosts.txt";
	if(fs::exists(fpath.toStdString()) && fs::is_regular_file(fpath.toStdString())){
		for(QString l : read_lines(fpath)){
			if(l.at(0) == '#'){
				continue;
			}
			QStringList ll = l.split(';');
			if(ll.size() > 4){
				m_hostmap[ll.at(1).simplified()] = ll.at(3) + "," + ll.at(4);
			}
		}

		m_customhosts = m_localhosts.split('\n');
        for (const auto& i : std::as_const(m_customhosts)){
			QStringList line = i.simplified().split(' ');

			if(line.at(0) == "YSF"){
				m_hostmap[line.at(1).simplified()] = line.at(2).simplified() + "," + line.at(3).simplified();
			}
		}

		QMap<QString, QString>::const_iterator i = m_hostmap.constBegin();
		while (i != m_hostmap.constEnd()) {
			m_hostsmodel.append(i.key());
			++i;
		}
	}
	else{
		download_file("https://www.ysfreflector.de/hostsfiles/YSFHosts.txt", "YSFHosts.txt");
	}
}

void DroidStar::process_fcs_rooms()
{
	m_hostmap.clear();
	m_hostsmodel.clear();
	QString fpath = config_path + "/FCSHosts.txt";
	if(fs::exists(fpath.toStdString()) && fs::is_regular_file(fpath.toStdString())){
		for(QString l : read_lines(fpath)){
			if(l.at(0) == '#'){
				continue;
			}
			QStringList ll = l.split(';');
			if(ll.size() > 4){
				if(ll.at(1).simplified() != "nn"){
					m_hostmap[ll.at(0).simplified() + " - " + ll.at(1).simplified()] = ll.at(2).left(6).toLower() + ".xreflector.net,62500";
				}
			}
		}

		m_customhosts = m_localhosts.split('\n');
        for (const auto& i : std::as_const(m_customhosts)){
			QStringList line = i.simplified().split(' ');

			if(line.at(0) == "FCS"){
				m_hostmap[line.at(1).simplified()] = line.at(2).simplified() + "," + line.at(3).simplified();
			}
		}

		QMap<QString, QString>::const_iterator i = m_hostmap.constBegin();
		while (i != m_hostmap.constEnd()) {
			m_hostsmodel.append(i.key());
			++i;
		}
	}
	else{
		download_file("https://www.ysfreflector.de/hostsfiles/FCSHosts.txt", "FCSHosts.txt");
	}
}

void DroidStar::process_dmr_hosts()
{
	m_hostmap.clear();
	m_hostsmodel.clear();
	QString fpath = config_path + "/DMRHosts.txt";
	if(fs::exists(fpath.toStdString()) && fs::is_regular_file(fpath.toStdString())){
		for(QString l : read_lines(fpath)){
			if(l.at(0) == '#'){
				continue;
			}
			QStringList ll = l.simplified().split(' ');
			if(ll.size() > 4){
				if( (ll.at(0).simplified() != "DMRGateway")
				 && (ll.at(0).simplified() != "DMR2YSF")
				 && (ll.at(0).simplified() != "DMR2NXDN"))
				{
					m_hostmap[ll.at(0).simplified()] = ll.at(2) + "," + ll.at(4) + "," + ll.at(3);
				}
			}
		}

		m_customhosts = m_localhosts.split('\n');
        for (const auto& i : std::as_const(m_customhosts)){
			QStringList line = i.simplified().split(' ');

			if(line.at(0) == "DMR"){
				m_hostmap[line.at(1).simplified()] = line.at(2).simplified() + "," + line.at(3).simplified() + "," + line.at(4).simplified();
			}
		}

		QMap<QString, QString>::const_iterator i = m_hostmap.constBegin();
		while (i != m_hostmap.constEnd()) {
			m_hostsmodel.append(i.key());
			++i;
		}
	}
	else{
		download_file("https://www.pistar.uk/downloads/DMR_Hosts.txt", "DMRHosts.txt");
	}
}

void DroidStar::process_p25_hosts()
{
	m_hostmap.clear();
	m_hostsmodel.clear();
	QString fpath = config_path + "/P25Hosts.txt";
	if(fs::exists(fpath.toStdString()) && fs::is_regular_file(fpath.toStdString())){
		for(QString l : read_lines(fpath)){
			if(l.at(0) == '#'){
				continue;
			}
			QStringList ll = l.simplified().split(' ');
			if(ll.size() > 2){
				m_hostmap[ll.at(0).simplified()] = ll.at(1) + "," + ll.at(2);
			}
		}

		m_customhosts = m_localhosts.split('\n');
        for (const auto& i : std::as_const(m_customhosts)){
			QStringList line = i.simplified().split(' ');

			if(line.at(0) == "P25"){
				m_hostmap[line.at(1).simplified()] = line.at(2).simplified() + "," + line.at(3).simplified();
			}
		}

		QMap<QString, QString>::const_iterator i = m_hostmap.constBegin();
		while (i != m_hostmap.constEnd()) {
			m_hostsmodel.append(i.key());
			++i;
        }
        QMap<int, QString> m;
        for (auto s : m_hostsmodel) m[s.toInt()] = s;
        m_hostsmodel = QStringList(m.values());
	}
	else{
		download_file("https://www.pistar.uk/downloads/P25_Hosts.txt", "P25Hosts.txt");
	}
}

void DroidStar::process_nxdn_hosts()
{
	m_hostmap.clear();
	m_hostsmodel.clear();
	QString fpath = config_path + "/NXDNHosts.txt";
	if(fs::exists(fpath.toStdString()) && fs::is_regular_file(fpath.toStdString())){
		for(QString l : read_lines(fpath)){
			if(l.at(0) == '#'){
				continue;
			}
			QStringList ll = l.simplified().split(' ');
			if(ll.size() > 2){
				m_hostmap[ll.at(0).simplified()] = ll.at(1) + "," + ll.at(2);
			}
		}

		m_customhosts = m_localhosts.split('\n');
        for (const auto& i : std::as_const(m_customhosts)){
			QStringList line = i.simplified().split(' ');

			if(line.at(0) == "NXDN"){
				m_hostmap[line.at(1).simplified()] = line.at(2).simplified() + "," + line.at(3).simplified();
			}
		}

		QMap<QString, QString>::const_iterator i = m_hostmap.constBegin();
		while (i != m_hostmap.constEnd()) {
			m_hostsmodel.append(i.key());
			++i;
        }
        QMap<int, QString> m;
        for (auto s : m_hostsmodel) m[s.toInt()] = s;
        m_hostsmodel = QStringList(m.values());
	}
	else{
		download_file("https://www.pistar.uk/downloads/NXDN_Hosts.txt", "NXDNHosts.txt");
	}
}

void DroidStar::process_m17_hosts()
{
	m_hostmap.clear();
	m_hostsmodel.clear();

	QString fpath = config_path + "/M17Hosts-full.csv";
	if(fs::exists(fpath.toStdString()) && fs::is_regular_file(fpath.toStdString())){
		for(QString l : read_lines(fpath)){
			if(l.at(0) == '#'){
				continue;
			}
			QStringList ll = l.simplified().split(',');
			if(ll.size() > 3){
				m_hostmap[ll.at(0).simplified()] = ll.at(2) + "," + ll.at(4) + "," + ll.at(3);
			}
		}

		m_customhosts = m_localhosts.split('\n');
        for (const auto& i : std::as_const(m_customhosts)){
			QStringList line = i.simplified().split(' ');

			if(line.at(0) == "M17"){
				m_hostmap[line.at(1).simplified()] = line.at(2).simplified() + "," + line.at(3).simplified();
			}
		}
        if(m_mdirect){
            m_hostmap["ALL"] = "ALL";
            m_hostmap["UNLINK"] = "UNLINK";
            m_hostmap["ECHO"] = "ECHO";
            m_hostmap["INFO"] = "INFO";
        }
		QMap<QString, QString>::const_iterator i = m_hostmap.constBegin();
		while (i != m_hostmap.constEnd()) {
			m_hostsmodel.append(i.key());
			++i;
		}
	}
	else{
		download_file("https://www.m17project.org/reflectors/M17Hosts-full.csv", "M17Hosts-full.csv");
	}
}

void DroidStar::process_iax_hosts()
{
    m_hostmap.clear();
    m_hostsmodel.clear();
    m_customhosts = m_localhosts.split('\n');
    for (const auto& i : std::as_const(m_customhosts)){
        QStringList line = i.simplified().split(' ');
        if(line.at(0) == "IAX"){
            if(line.at(2).simplified() == "wt"){
               m_hostmap[line.at(1).simplified()] = line.at(1).simplified() + ".nodes.allstarlink.org," + line.at(3).simplified() + "," + line.at(4).simplified() + "," + line.at(5).simplified();
            }
            else{
                m_hostmap[line.at(1).simplified()] = line.at(2).simplified() + "," + line.at(3).simplified() + "," + line.at(4).simplified() + "," + line.at(5).simplified();
            }
        }
    }

    QMap<QString, QString>::const_iterator i = m_hostmap.constBegin();
    while (i != m_hostmap.constEnd()) {
        m_hostsmodel.append(i.key());
        ++i;
    }
}

void DroidStar::process_asl_hosts() {
	// TODO - implement ASL hosts
}

void DroidStar::process_dmr_ids()
{
	QString fpath = config_path + "/DMRIDs.dat";
	if(fs::exists(fpath.toStdString()) && fs::is_regular_file(fpath.toStdString())){
		for(QString lids : read_lines(fpath)){
			if(lids.at(0) == '#'){
				continue;
			}
			QStringList llids = lids.simplified().split(' ');

			if(llids.size() >= 2){
                if(llids.size() == 3){
                     m_dmrids[llids.at(0).toUInt()] = llids.at(1) + " " + llids.at(2);
                }
                else{
                    m_dmrids[llids.at(0).toUInt()] = llids.at(1);
                }
			}
		}
	}
	else{
		download_file("https://database.radioid.net/static/users.dat", "DMRIDs.dat");
	}
}

void DroidStar::update_dmr_ids()
{
	QString fpath = config_path + "/DMRIDs.dat";
	if(fs::exists(fpath.toStdString()) && fs::is_regular_file(fpath.toStdString())){
		fs::remove(fpath.toStdString());
	}
	process_dmr_ids();
	update_nxdn_ids();
}

void DroidStar::process_nxdn_ids()
{
	QString fpath = config_path + "/NXDN.csv";
	if(fs::exists(fpath.toStdString()) && fs::is_regular_file(fpath.toStdString())){
		for(QString lids : read_lines(fpath)){
			if(lids.at(0) == '#'){
				continue;
			}
			QStringList llids = lids.simplified().split(',');

			if(llids.size() > 1){
				m_nxdnids[llids.at(0).toUInt()] = llids.at(1);
			}
		}
	}
	else{
		download_file("https://www.pistar.uk/downloads/NXDN.csv", "NXDN.csv");
	}
}

void DroidStar::update_nxdn_ids()
{
	QString fpath = config_path + "/NXDN.csv";
	if(fs::exists(fpath.toStdString()) && fs::is_regular_file(fpath.toStdString())){
		fs::remove(fpath.toStdString());
	}
	process_nxdn_ids();
}

void DroidStar::update_host_files()
{
	m_update_host_files = true;
	check_host_files();
}

void DroidStar::check_host_files()
{
	if(!fs::exists(config_path.toStdString())){
		fs::create_directories(config_path.toStdString());
	}

	auto host_needed = [&](const char* name) {
		QString fpath = config_path + "/" + name;
		return (!fs::exists(fpath.toStdString()) || !fs::is_regular_file(fpath.toStdString())) || m_update_host_files;
	};

	if(host_needed("dplus.txt"))         download_file("https://www.dstarinfo.com/downloads/dplus.txt",                    "dplus.txt");
	if(host_needed("dextra.txt"))        download_file("https://www.dstarinfo.com/downloads/dextra.txt",                   "dextra.txt");
	if(host_needed("dcs.txt"))           download_file("https://www.dstarinfo.com/downloads/dcs.txt",                      "dcs.txt");
	if(host_needed("YSFHosts.txt"))      download_file("https://www.ysfreflector.de/hostsfiles/YSFHosts.txt",              "YSFHosts.txt");
	if(host_needed("FCSHosts.txt"))      download_file("https://www.ysfreflector.de/hostsfiles/FCSHosts.txt",              "FCSHosts.txt");
	if(host_needed("DMRHosts.txt"))      download_file("https://www.pistar.uk/downloads/DMR_Hosts.txt",                    "DMRHosts.txt");
	if(host_needed("P25Hosts.txt"))      download_file("https://www.pistar.uk/downloads/P25_Hosts.txt",                    "P25Hosts.txt");
	if(host_needed("NXDNHosts.txt"))     download_file("https://www.pistar.uk/downloads/NXDN_Hosts.txt",                   "NXDNHosts.txt");
	if(host_needed("M17Hosts-full.csv")) download_file("https://www.m17project.org/reflectors/M17Hosts-full.csv",          "M17Hosts-full.csv");
	if(host_needed("ASLHosts.txt"))      {} // AllStar: no public host list available

	{
		QString fpath = config_path + "/DMRIDs.dat";
		if(!fs::exists(fpath.toStdString()) || !fs::is_regular_file(fpath.toStdString())){
			// DMR user database from RadioID.net
			download_file("https://database.radioid.net/static/users.dat", "DMRIDs.dat");
		}
		else {
			QMetaObject::invokeMethod(this, [this]() { process_dmr_ids(); }, Qt::QueuedConnection);
		}
	}

	{
		QString fpath = config_path + "/NXDN.csv";
		if(!fs::exists(fpath.toStdString()) || !fs::is_regular_file(fpath.toStdString())){
			// NXDN ID database from PiStar.uk
			download_file("https://www.pistar.uk/downloads/NXDN.csv", "NXDN.csv");
		}
		else{
			QMetaObject::invokeMethod(this, [this]() { process_nxdn_ids(); }, Qt::QueuedConnection);
		}
	}
	m_update_host_files = false;

	//process_mode_change(ui->modeCombo->currentText().simplified());
/*
#if defined(Q_OS_ANDROID)
	QString vocname = "/vocoder_plugin." + QSysInfo::productType() + "." + QSysInfo::currentCpuArchitecture();
#else
	QString vocname = "/vocoder_plugin." + QSysInfo::kernelType() + "." + QSysInfo::currentCpuArchitecture();
#endif
	QString newvoc = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation) + vocname;
	QString voc = config_path + vocname;
	qDebug() << "newvoc == " << newvoc;
	qDebug() << "voc == " << voc;
	if(fs::exists(newvoc.toStdString()) && fs::is_regular_file(newvoc.toStdString())){
		qDebug() << newvoc << " found";
		if(fs::exists(voc.toStdString())){
			qDebug() << voc << " found";
			if(fs::remove(voc.toStdString())){
				qDebug() << voc << " deleted";
			}
			else{
				qDebug() << voc << " not deleted";
			}
		}
		fs::copy_file(newvoc.toStdString(), voc.toStdString(), fs::copy_options::overwrite_existing);
		qDebug() << newvoc << " copied";
	}
	else{
		qDebug() << newvoc << " not found";
	}
*/
}

void DroidStar::update_data(Mode::MODEINFO info)
{
	if((connect_status == Mode::CONNECTING) && (info.status == Mode::DISCONNECTED)){
		process_connect();
		return;
	}

    if((connect_status == Mode::CONNECTED_RW) && (info.status == Mode::TIMEOUT)){
        connect_status = Mode::TIMEOUT;
        process_connect();
        return;
    }

	if( (connect_status == Mode::CONNECTING) && ( info.status == Mode::CONNECTED_RW)){
		connect_status = Mode::CONNECTED_RW;
		if (on_status_changed) on_status_changed(2); emit connect_status_changed(2);
		emit in_audio_vol_changed(0.5);
		emit swtx_state(!m_mode->get_hwtx());
		emit swrx_state(!m_mode->get_hwrx());
		emit rptr2_changed(m_refname + " " + m_module);
		if(m_mycall.isEmpty()) set_mycall(m_callsign);
		if(m_urcall.isEmpty()) set_urcall("CQCQCQ");
		if(m_rptr1.isEmpty()) set_rptr1(m_callsign + " " + m_module);
        QString s = "Connected to " + m_protocol + " " + m_refname + " " + m_host + ":" + QString::number(m_port);
        log_msg(s);

		if(info.sw_vocoder_loaded){
			log_msg("Vocoder plugin loaded");
		}
		else{
			log_msg("Vocoder plugin not loaded");
			emit open_vocoder_dialog();
		}
#ifdef Q_OS_ANDROID
        QJniObject javaNotification = QJniObject::fromString(s);
        QJniObject::callStaticMethod<void>(
            "org/dudetronics/droidstar/NotificationClient",
            "notify",
            "(Landroid/content/Context;Ljava/lang/String;)V",
            QNativeInterface::QAndroidApplication::context(),
            javaNotification.object<jstring>());
#endif
	}

	m_netstatustxt = "Connected ping cnt: " + QString::number(info.count);
	m_ambestatustxt = "AMBE: " + (info.ambeprodid.empty() ? "No device" : QString::fromStdString(info.ambeprodid));
	m_mmdvmstatustxt = "MMDVM: ";

	if(info.mmdvm.empty()){
		m_mmdvmstatustxt += "No device";
	}

	std::vector<std::string> verparts;
	{
		size_t pos = 0;
		while(pos < info.ambeverstr.size()){
			size_t dot = info.ambeverstr.find('.', pos);
			if(dot == std::string::npos){
				verparts.push_back(info.ambeverstr.substr(pos));
				break;
			}
			verparts.push_back(info.ambeverstr.substr(pos, dot - pos));
			pos = dot + 1;
		}
	}
	if(verparts.size() > 7){
		m_ambestatustxt += " " + QString::fromStdString(verparts[0]) + " " + QString::fromStdString(verparts[5]) + " " + QString::fromStdString(verparts[6]);
	}

	std::vector<std::string> mmdvmparts;
	{
		size_t pos = 0;
		while(pos < info.mmdvm.size()){
			size_t sp = info.mmdvm.find(' ', pos);
			if(sp == std::string::npos){
				mmdvmparts.push_back(info.mmdvm.substr(pos));
				break;
			}
			mmdvmparts.push_back(info.mmdvm.substr(pos, sp - pos));
			pos = sp + 1;
		}
	}
	if(mmdvmparts.size() > 3){
		m_mmdvmstatustxt += QString::fromStdString(mmdvmparts[0]) + " " + QString::fromStdString(mmdvmparts[1]);
	}

	if(info.stream_state == Mode::STREAM_IDLE){
		m_data1.clear();
		m_data2.clear();
		m_data3.clear();
		m_data4.clear();
		m_data5.clear();
		m_data6.clear();
	}
	else if (m_protocol == "REF" || m_protocol == "XRF" || m_protocol == "DCS"){
		m_data1 = QString::fromStdString(info.src);
		m_data2 = QString::fromStdString(info.dst);
		m_data3 = QString::fromStdString(info.gw);
		m_data4 = QString::fromStdString(info.gw2);
		m_data5 = QString::number(info.streamid, 16) + " " + QString("%1").arg(info.frame_number, 2, 16, QChar('0'));
		m_data6 = QString::fromStdString(info.usertxt);
	}
	else if (m_protocol == "YSF" || m_protocol == "FCS"){
		m_data1 = QString::fromStdString(info.gw);
		m_data2 = QString::fromStdString(info.src);
		m_data3 = QString::fromStdString(info.dst);

		if(info.type == 0){
			m_data4 = "V/D mode 1";
		}
		else if(info.type == 1){
			m_data4 = "Data Full Rate";
		}
		else if(info.type == 2){
			m_data4 = "V/D mode 2";
		}
		else if(info.type == 3){
			m_data4 = "Voice Full Rate";
		}
		else{
			m_data4 = "";
		}
		if(info.type >= 0){
			m_data5 = info.path  ? "Internet" : "Local";
			m_data6 = QString::number(info.frame_number) + "/" + QString::number(info.frame_total);
		}
		else{
			m_data5 = m_data6 = "";
		}
	}
	else if(m_protocol == "DMR"){
		m_data1 = m_dmrids[info.srcid];
		m_data2 = info.srcid ? QString::number(info.srcid) : "";
		m_data3 = info.dstid ? QString::number(info.dstid) : "";
		m_data4 = info.gwid ? QString::number(info.gwid) : "";
		QString s = "Slot" + QString::number(info.slot);
		QString flco;

		switch( (info.slot & 0x40) >> 6){
		case 0:
			flco = "Group";
			break;
		case 3:
			flco = "Private";
			break;
		case 8:
			flco = "GPS";
			break;
		default:
			flco = "Unknown";
			break;
		}

		if(info.frame_number){
			QString n = s + " " + flco + " " + QString("%1").arg(info.frame_number, 2, 16, QChar('0'));
			m_data5 = n;
		}
	}
	else if(m_protocol == "P25"){
		m_data1 = m_dmrids[info.srcid];
		m_data2 = info.srcid ? QString::number(info.srcid) : "";
		m_data3 = info.dstid ? QString::number(info.dstid) : "";
		m_data4 = info.srcid ? QString::number(info.srcid) : "";
		if(info.frame_number){
			QString n = QString("%1").arg(info.frame_number, 2, 16, QChar('0'));
			m_data5 = n;
		}
	}
	else if(m_protocol == "NXDN"){
		if(info.srcid){
			m_data1 = m_nxdnids[info.srcid];
			m_data2 = QString::number(info.srcid);
		}
		m_data3 = QString::number(info.dstid);

		if(info.frame_number){
			QString n = QString("%1").arg(info.frame_number, 4, 16, QChar('0'));
			m_data5 = n;
		}
	}
	else if(m_protocol == "M17"){
		m_data1 = QString::fromStdString(info.src);
        m_data2 = QString::fromStdString(info.dst) + " " + QString::fromStdString(info.module);

        switch(info.type){
        case 0:
           m_data3 =  "1600 V/D";
            m_data5 = QString::number(info.streamid, 16);
            break;
        case 1:
            m_data3 = "3200 Voice";
            m_data5 = QString::number(info.streamid, 16);
            break;
        case 2:
            m_data3 = "Packet";
            m_data5 = QString::fromStdString(info.usertxt.substr(0, 20));
            update_log(QString::fromStdString(info.src.substr(0, info.src.find(' '))) + ": " + QString::fromStdString(info.usertxt));
            break;
        }

		if(info.frame_number){
			QString n = QString("%1").arg(info.frame_number, 4, 16, QChar('0'));
			m_data4 = n;
		}

	}
	else if(m_protocol == "IAX"){

	}
	QString t = QDateTime::fromMSecsSinceEpoch(info.ts).toString("yyyy.MM.dd hh:mm:ss.zzz");
	if((m_protocol == "DMR") || (m_protocol == "P25") || (m_protocol == "NXDN")){
		QString namecall;
		if(m_protocol == "NXDN"){
			namecall = m_nxdnids[info.srcid];
		}
		else{
			namecall = m_dmrids[info.srcid];
		}

		QString logDetails;
		if(!namecall.isEmpty()){
			logDetails = namecall + " (" + QString::number(info.srcid) + ")";
		}
		else{
			logDetails = QString::number(info.srcid);
		}

		if(info.stream_state == Mode::STREAM_NEW){
			log_msg(t + " " + m_protocol + " RX started from: " + logDetails + " to: " + QString::number(info.dstid));
		}
		if(info.stream_state == Mode::STREAM_END){
			log_msg(t + " " + m_protocol + " RX ended from: " + logDetails + " to: " + QString::number(info.dstid));
		}
		if(info.stream_state == Mode::STREAM_LOST){
			log_msg(t + " " + m_protocol + " RX lost from: " + logDetails + " to: " + QString::number(info.dstid));
		}
	}
	else{
		if(info.stream_state == Mode::STREAM_NEW){
			log_msg(t + " " + m_protocol + " RX started id: " + QString::number(info.streamid, 16) + " src: " + QString::fromStdString(info.src) + " dst: " + QString::fromStdString(info.gw2));
		}
		if(info.stream_state == Mode::STREAM_END){
			log_msg(t + " " + m_protocol + " RX ended id: " + QString::number(info.streamid, 16) + " src: " + QString::fromStdString(info.src) + " dst: " + QString::fromStdString(info.gw2));
		}
		if(info.stream_state == Mode::STREAM_LOST){
			log_msg(t + " " + m_protocol + " RX lost id: " + QString::number(info.streamid, 16) + " src: " + QString::fromStdString(info.src) + " dst: " + QString::fromStdString(info.gw2));
		}
	}
    if (on_data) on_data();
    emit update_data();
}

void DroidStar::updatelog(QString s)
{
    if (on_log) on_log(s);
    emit update_log(s);
}

void DroidStar::set_input_volume(qreal v)
{
	emit in_audio_vol_changed(v);
	//audioin->setVolume(v * 0.01);
}

void DroidStar::set_output_volume(qreal v)
{
	emit out_audio_vol_changed(v);
}

void DroidStar::press_tx()
{
	emit tx_pressed();
}

void DroidStar::release_tx()
{
	emit tx_released();
}

void DroidStar::click_tx(bool tx)
{
	emit tx_clicked(tx);
}

void DroidStar::appendToStationLog(const QString &tgStr, const QString &dateStr, const QString &timeStr, const QString &callsign, const QString &name, const QString &country)
{
    m_lastLogDate = dateStr;
    m_lastLogTime = timeStr;
    m_lastLogCallsign = callsign;
    m_lastLogName = name;
    m_lastLogCountry = country;

    QString fpath = config_path + "/station_log.csv";
    std::ofstream f(fpath.toStdString(), std::ios::app);
    if (f.is_open()) {
        // Escape commas and quotes for CSV compliance
        QString escTg = tgStr;
        escTg.replace("\"", "\"\"");
        if (escTg.contains(",")) escTg = "\"" + escTg + "\"";

        QString escName = name;
        escName.replace("\"", "\"\"");
        if (escName.contains(",")) escName = "\"" + escName + "\"";

        // Fallback to Country text escaping
        QString escCountry = country;
        escCountry.replace("\"", "\"\"");
        if (escCountry.contains(",")) escCountry = "\"" + escCountry + "\"";

        f << escTg.toStdString() << "," << dateStr.toStdString() << "," << timeStr.toStdString() << "," << callsign.toStdString() << "," << escName.toStdString() << "," << escCountry.toStdString() << std::endl;
    }
}

void DroidStar::updateLastStationLogTG(const QString &tgStr)
{
    if (m_lastLogCallsign.isEmpty()) return;
    
    QString fpath = config_path + "/station_log.csv";
    if (!fs::exists(fpath.toStdString())) return;
    
    QStringList lines = read_lines(fpath);
    
    if (!lines.isEmpty()) {
        // Rewrite the last line with the new tgStr
        QString escTg = tgStr;
        escTg.replace("\"", "\"\"");
        if (escTg.contains(",")) escTg = "\"" + escTg + "\"";

        QString escName = m_lastLogName;
        escName.replace("\"", "\"\"");
        if (escName.contains(",")) escName = "\"" + escName + "\"";

        QString escCountry = m_lastLogCountry;
        escCountry.replace("\"", "\"\"");
        if (escCountry.contains(",")) escCountry = "\"" + escCountry + "\"";

        QString newLastLine = escTg + "," + m_lastLogDate + "," + m_lastLogTime + "," + m_lastLogCallsign + "," + escName + "," + escCountry;
        lines.last() = newLastLine;
        
        std::ofstream f(fpath.toStdString(), std::ios::trunc);
        if (f.is_open()) {
            for (const QString &line : lines) {
                f << line.toStdString() << "\n";
            }
        }
    }
}

QString DroidStar::readStationLog()
{
    QString fpath = config_path + "/station_log.csv";
    if (fs::exists(fpath.toStdString())) {
        std::ifstream f(fpath.toStdString());
        if (f.is_open()) {
            std::string content((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
            return QString::fromStdString(content);
        }
    }
    return "";
}

QString DroidStar::exportStationLog()
{
    QString srcPath = config_path + "/station_log.csv";
    if (!fs::exists(srcPath.toStdString())) {
        return "EMPTY";
    }

    QString destDir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    fs::create_directories(destDir.toStdString());
    QString destPath = destDir + "/station_log.csv";

    if (fs::exists(destPath.toStdString())) {
        fs::remove(destPath.toStdString());
    }

    if (fs::copy_file(srcPath.toStdString(), destPath.toStdString(), fs::copy_options::overwrite_existing)) {
        return destPath;
    }
    return "ERROR";
}

void DroidStar::clearStationLog()
{
    fs::remove((config_path + "/station_log.csv").toStdString());
}

void DroidStar::save_memory(int index, const QString &mode, const QString &host, int slot, int cc, const QString &tgid)
{
	nlohmann::json mem;
	mem["Mode"] = mode.toStdString();
	mem["Host"] = host.toStdString();
	mem["Slot"] = slot;
	mem["CC"] = cc;
	mem["TGID"] = tgid.toStdString();
	if (!m_json_settings.contains("Memory") || !m_json_settings["Memory"].is_array()) {
		m_json_settings["Memory"] = nlohmann::json::array();
	}
	auto& arr = m_json_settings["Memory"];
	while (index >= (int)arr.size()) {
		arr.push_back(nullptr);
	}
	arr[index] = mem;
	save_settings_file();
}

QVariantMap DroidStar::get_memory(int index)
{
	QVariantMap map;
	if (m_json_settings.contains("Memory") && m_json_settings["Memory"].is_array()) {
		auto& arr = m_json_settings["Memory"];
		if (index < (int)arr.size() && !arr[index].is_null()) {
			auto& mem = arr[index];
			map["Mode"] = QString::fromStdString(mem.value("Mode", ""));
			map["Host"] = QString::fromStdString(mem.value("Host", ""));
			map["Slot"] = mem.value("Slot", 0);
			map["CC"] = mem.value("CC", 0);
			map["TGID"] = QString::fromStdString(mem.value("TGID", ""));
		}
	}
	return map;
}

QString DroidStar::get_key_name(int key)
{
    if (key <= 0) return "None";
    return QKeySequence(Qt::Key(key)).toString();
}


