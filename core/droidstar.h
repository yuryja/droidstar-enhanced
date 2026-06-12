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

#ifndef DROIDSTAR_H
#define DROIDSTAR_H

#include <QObject>
#include "mode.h"
#include "json.hpp"
#include <functional>
#include <thread>
#include <atomic>

class DroidStar : public QObject
{
	Q_OBJECT
	//Q_PROPERTY(QString mode READ mode WRITE set_mode NOTIFY mode_changed)
public:
	explicit DroidStar(QObject *parent = nullptr);
	~DroidStar();

signals:
	void input_source_changed(int, QString);
	void mode_changed();
	void module_changed(char);
	void slot_changed(int);
	void cc_changed(int);
	void update_data();
	void update_log(QString);
	void open_vocoder_dialog();
	void update_settings();
	void connect_status_changed(int c);
	void in_audio_vol_changed(qreal);
	void out_audio_vol_changed(qreal);
	void tx_pressed();
	void tx_released();
    void tx_clicked(bool);
    void m17_send_sms(QString);
	void dmrpc_state_changed(int);
	void dmr_tgid_changed(int);
	void m17_rate_changed(int);
	void m17_can_changed(int);
	void send_dtmf(QByteArray);
	void swtx_state_changed(int);
	void swrx_state_changed(int);
	void swtx_state(int);
	void swrx_state(int);
	void agc_state(int);
	void agc_state_changed(int);
	void rptr1_changed(QString);
	void rptr2_changed(QString);
	void mycall_changed(QString);
	void urcall_changed(QString);
	void usrtxt_changed(QString);
    void dst_changed(QString);
    void debug_changed(bool);
    void update_devices();
	void ptt_key_changed(int key);
public slots:
	void set_callsign(const QString &callsign) {  m_callsign = callsign.simplified(); save_settings(); }
	void set_dmrtgid(const QString &dmrtgid) { m_dmr_destid = dmrtgid.simplified().toUInt(); save_settings(); }
	void set_slot(const int slot) {emit slot_changed(slot); }
	void set_cc(const int cc) {emit cc_changed(cc); m_dmrColorCode = cc; }
	void tgid_text_changed(QString s){emit dmr_tgid_changed(s.toUInt());}
	void set_dmrid(const QString &dmrid) { m_dmrid = dmrid.simplified().toUInt(); save_settings(); }
	void set_essid(const QString &essid)
	{
		if (essid != "None") {
			m_essid = essid.simplified().toUInt() + 1;
			save_settings();
		}
		else{
			m_essid = 0;
		}
	}
	void set_bm_password(const QString &bmpwd) { m_bm_password = bmpwd; save_settings(); }
	void set_tgif_password(const QString &tgifpwd) { m_tgif_password = tgifpwd; save_settings(); }
	void set_asl_password(const QString &aslpwd) { m_asl_password = aslpwd; save_settings(); }
	void set_latitude(const QString &lat){ m_latitude = lat; save_settings(); }
	void set_longitude(const QString &lon){ m_longitude = lon; save_settings(); }
	void set_location(const QString &loc){ m_location = loc; save_settings(); }
	void set_description(const QString &desc){ m_description = desc; save_settings(); }
	void set_freq(const QString &freq){ m_freq = freq; save_settings(); }
	void set_url(const QString &url){ m_url = url; save_settings(); }
	void set_swid(const QString &swid){ m_swid = swid; save_settings(); }
	void set_pkgid(const QString &pkgid){ m_pkgid = pkgid; save_settings(); }
    void set_dmr_options(const QString &dmropts) { m_dmropts = dmropts; save_settings(); }
    void set_dmr_pc(int pc) { m_pc = pc; emit dmrpc_state_changed(m_pc); }
	void set_module(const QString &module) { m_module = module.toStdString()[0]; save_settings(); emit module_changed(m_module);}
	void set_protocol(const QString &protocol) { m_protocol = protocol; save_settings(); }
	void set_input_volume(qreal v);
	void set_output_volume(qreal v);
	void set_modelchange(bool t){ m_modelchange = t; }
	void set_mycall(const QString &mycall) { m_mycall = mycall; save_settings(); emit mycall_changed(mycall); }
    void set_urcall(const QString &urcall) { m_urcall = urcall; save_settings(); emit urcall_changed(urcall); }
    void set_rptr1(const QString &rptr1) { m_rptr1 = rptr1; save_settings(); emit rptr1_changed(rptr1); qDebug() << "rpt1 == " << m_rptr1; }
    void set_rptr2(const QString &rptr2) { m_rptr2 = rptr2; save_settings(); emit rptr2_changed(rptr2); qDebug() << "rpt2 == " << m_rptr2; }
	void set_usrtxt(const QString &usrtxt) { m_dstarusertxt = usrtxt; save_settings(); emit usrtxt_changed(usrtxt); }
	void set_txtimeout(const QString &t) { m_txtimeout = t.simplified().toUInt(); save_settings();}
	void set_toggletx(bool x) { m_toggletx = x; save_settings(); }
	void set_xrf2ref(bool x) { m_xrf2ref = x; save_settings(); }
	void set_ipv6(bool ipv6) { m_ipv6 = ipv6; save_settings(); }
	void set_vocoder(QString vocoder) { m_vocoder = vocoder; }
	void set_modem(QString modem) { m_modem = modem; }
	void set_playback(QString playback) { m_playback = playback; }
	void set_capture(QString capture) { m_capture = capture; }
	void set_swtx(bool swtx) { emit swtx_state_changed(swtx); }
	void set_swrx(bool swrx) { emit swrx_state_changed(swrx); }
	void set_agc(bool agc) { emit agc_state_changed(agc); }
    void set_mmdvm_direct(bool mmdvm) { m_mdirect = mmdvm; process_mode_change(m_protocol); }
	void set_iaxport(const QString &port){ m_iaxport = port.simplified().toUInt(); save_settings(); }
    void set_dst(QString dst){emit dst_changed(dst);}
	void set_debug(bool debug){emit debug_changed(debug);}

public:
	// Callbacks for C API (replace Qt signals/slots)
	std::function<void(const QString&)> on_log;
	std::function<void()> on_data;
	std::function<void()> on_devices_changed;
	std::function<void(int)> on_status_changed;
	void log_msg(const QString& s);

	void set_modemRxFreq(QString m) { m_modemRxFreq = m; save_settings(); }
	void set_modemTxFreq(QString m) { m_modemTxFreq = m; save_settings(); }
	void set_modemRxOffset(QString m) { m_modemRxOffset = m; save_settings(); }
	void set_modemTxOffset(QString m) { m_modemTxOffset = m; save_settings(); }
	void set_modemRxDCOffset(QString m) { m_modemRxDCOffset = m; save_settings(); }
	void set_modemTxDCOffset(QString m) { m_modemTxDCOffset = m; save_settings(); }
	void set_modemRxLevel(QString m) { m_modemRxLevel = m; save_settings(); }
	void set_modemTxLevel(QString m) { m_modemTxLevel = m; save_settings(); }
	void set_modemRFLevel(QString m) { m_modemRFLevel = m; save_settings(); }
	void set_modemTxDelay(QString m) { m_modemTxDelay = m; save_settings(); }
	void set_modemCWIdTxLevel(QString m) { m_modemCWIdTxLevel = m; save_settings(); }
	void set_modemDstarTxLevel(QString m) { m_modemDstarTxLevel = m; save_settings(); }
	void set_modemDMRTxLevel(QString m) { m_modemDMRTxLevel = m; save_settings(); }
	void set_modemYSFTxLevel(QString m) { m_modemYSFTxLevel = m; save_settings(); }
	void set_modemP25TxLevel(QString m) { m_modemP25TxLevel = m; save_settings(); }
	void set_modemNXDNTxLevel(QString m) { m_modemNXDNTxLevel = m; save_settings(); }
	void set_modemBaud(QString m) { m_modemBaud = m; save_settings(); }
	void set_modemM17CAN(QString m) { emit m17_can_changed(m.toInt()); }

	void m17_rate_changed(bool r) { emit m17_rate_changed((int)r); }
	void process_connect();
	void schedule_reconnect(int ms);
	void press_tx();
	void release_tx();
	void click_tx(bool);
    void m17_sms_pressed(QString sms) { emit m17_send_sms(sms.left(822)); }
	void process_settings();
	void check_host_files();
	void update_host_files();
	void update_custom_hosts(QString);
	void update_dmr_ids();
	void update_nxdn_ids();
	void process_mode_change(const QString &m);
	void process_host_change(const QString &h);
	void dtmf_send_clicked(QString);
	bool get_modelchange() const { return m_modelchange; }
	QString get_label1() const { return m_label1; }
	QString get_label2() const { return m_label2; }
	QString get_label3() const { return m_label3; }
	QString get_label4() const { return m_label4; }
	QString get_label5() const { return m_label5; }
	QString get_label6() const { return m_label6; }
	QString get_data1() const { return m_data1; }
	QString get_data2() const { return m_data2; }
	QString get_data3() const { return m_data3; }
	QString get_data4() const { return m_data4; }
	QString get_data5() const { return m_data5; }
	QString get_data6() const { return m_data6; }
	QString get_ambestatustxt() const { return m_ambestatustxt; }
	QString get_mmdvmstatustxt() const { return m_mmdvmstatustxt; }
	QString get_netstatustxt() const { return m_netstatustxt; }
	QString get_mode() const { return m_protocol; }
	QString get_host() const { return m_host; }
	QString get_module() const { return QString(m_module); }
	QString get_callsign() const { return m_callsign; }
	QString get_dmrid() const { return m_dmrid ? QString::number(m_dmrid) : ""; }
	QString get_essid() const { return m_essid ? QString("%1").arg(m_essid - 1, 2, 10, QChar('0')) : "None"; }
	QString get_bm_password() const { return m_bm_password; }
	QString get_tgif_password() const { return m_tgif_password; }
	QString get_asl_password() const { return m_asl_password; }
	QString get_latitude() const { return m_latitude; }
	QString get_longitude() const { return m_longitude; }
	QString get_location() const { return m_location; }
	QString get_description() const { return m_description; }
	QString get_freq() const { return m_freq; }
	QString get_url() const { return m_url; }
	QString get_swid() const { return m_swid; }
	QString get_pkgid() const { return m_pkgid; }
	QString get_dmr_options() const { return m_dmropts; }
	QString get_dmrtgid() const { return m_dmr_destid ? QString::number(m_dmr_destid) : ""; }
	QStringList get_hosts() const { return m_hostsmodel; }
	QString get_ref_host() const { return m_saved_refhost; }
	QString get_dcs_host() const { return m_saved_dcshost; }
	QString get_xrf_host() const { return m_saved_xrfhost; }
	QString get_ysf_host() const { return m_saved_ysfhost; }
	QString get_fcs_host() const { return m_saved_fcshost; }
	QString get_dmr_host() const { return m_saved_dmrhost; }
	QString get_p25_host() const { return m_saved_p25host; }
	QString get_nxdn_host() const { return m_saved_nxdnhost; }
	QString get_m17_host() const { return m_saved_m17host; }
	QString get_iax_host() const { return m_saved_iaxhost; }
	QString get_mycall() const { return m_mycall; }
	QString get_urcall() const { return m_urcall; }
	QString get_rptr1() const { return m_rptr1; }
	QString get_rptr2() const { return m_rptr2; }
	QString get_txtimeout() const { return QString::number(m_txtimeout); }
	QString get_error_text() const { return m_errortxt; }
	bool get_toggletx() const { return m_toggletx; }
	bool get_ipv6() const { return m_ipv6; }
	bool get_xrf2ref() const { return m_xrf2ref; }
	QString get_local_hosts() const { return m_localhosts; }
	QStringList get_vocoders() const { return m_vocoders; }
	QStringList get_modems() const { return m_modems; }
	QStringList get_playbacks() const { return m_playbacks; }
	QStringList get_captures() const { return m_captures; }
	QString get_vocoder() const { return m_vocoder; }
	QString get_playback() const { return m_playback; }
	QString get_capture() const { return m_capture; }
	QString get_modemRxFreq() const { return m_modemRxFreq; }
	QString get_modemTxFreq() const { return m_modemTxFreq; }
	QString get_modemRxOffset() const { return m_modemRxOffset; }
	QString get_modemTxOffset() const { return m_modemTxOffset; }
	QString get_modemRxDCOffset() const { return m_modemRxDCOffset; }
	QString get_modemTxDCOffset() const { return m_modemTxDCOffset; }
	QString get_modemRxLevel() const { return m_modemRxLevel; }
	QString get_modemTxLevel() const { return m_modemTxLevel; }
	QString get_modemRFLevel() const { return m_modemRFLevel; }
	QString get_modemTxDelay() const { return m_modemTxDelay; }
	QString get_modemCWIdTxLevel() const { return m_modemCWIdTxLevel; }
	QString get_modemDstarTxLevel() const { return m_modemDstarTxLevel; }
	QString get_modemDMRTxLevel() const { return m_modemDMRTxLevel; }
	QString get_modemYSFTxLevel() const { return m_modemYSFTxLevel; }
	QString get_modemP25TxLevel() const { return m_modemP25TxLevel; }
	QString get_modemNXDNTxLevel() const { return m_modemNXDNTxLevel; }
	QString get_modemBaud() const { return m_modemBaud; }
	QString get_modemM17CAN() const { return m_modemM17CAN; }
#if defined(Q_OS_ANDROID)
	QString get_platform() const { return QSysInfo::productType(); }
	QString get_monofont() const { return "Droid Sans Mono"; }
#elif defined(Q_OS_WIN)
	QString get_platform() const { return QSysInfo::kernelType(); }
	void reset_connect_status() {}
	QString get_monofont() const { return "Courier"; }
#else
	QString get_platform() const { return QSysInfo::kernelType(); }
	void reset_connect_status() {}
	QString get_monofont() const { return "monospace"; }
#endif
	QString get_arch() const { return QSysInfo::currentCpuArchitecture(); }
	QString get_build_abi() const { return QSysInfo::buildAbi(); }
    QString get_software_build() const { return VERSION_NUMBER; }

	void download_file(const QString& url, const QString& dest_name);
	void file_downloaded(QString);
	void url_downloaded(QString);
	unsigned short get_output_level() const { return m_outlevel; }
	void set_output_level(unsigned short l){ m_outlevel = l; }
	void tts_changed(QString);
	void tts_text_changed(QString);
	void obtain_asl_wt_creds();
	void appendToStationLog(const QString &tgStr, const QString &dateStr, const QString &timeStr, const QString &callsign, const QString &name, const QString &country);
	void updateLastStationLogTG(const QString &tgStr);
	QString readStationLog();
	QString exportStationLog();
	void clearStationLog();
	void save_memory(int index, const QString &mode, const QString &host, int slot, int cc, const QString &tgid);
	QVariantMap get_memory(int index);
	int get_ptt_key() const { return m_pttKey; }
	void set_ptt_key(int key) { m_pttKey = key; save_settings(); emit ptt_key_changed(key); }
	QString get_key_name(int key);
private:
	int connect_status;
	bool m_update_host_files;
	nlohmann::json m_json_settings;
	QString m_settings_path;
	QString config_path;
	void load_settings_file();
	void save_settings_file();
	QString hosts_filename;
	QString m_callsign;
	QString m_host;
	QString m_refname;
	QString m_protocol;
	QString m_bm_password;
	QString m_tgif_password;
	QString m_asl_password;
	QString m_latitude;
	QString m_longitude;
	QString m_location;
	QString m_description;
	QString m_freq;
	QString m_url;
	QString m_swid;
	QString m_pkgid;
	QString m_dmropts;
    int m_pc;
	QString m_saved_refhost;
	QString m_saved_dcshost;
	QString m_saved_xrfhost;
	QString m_saved_ysfhost;
	QString m_saved_fcshost;
	QString m_saved_dmrhost;
	QString m_saved_p25host;
	QString m_saved_nxdnhost;
	QString m_saved_m17host;
	QString m_saved_iaxhost;
	uint32_t m_dmrid;
	uint8_t m_essid;
	uint32_t m_dmr_srcid;
	uint32_t m_dmr_destid;
	QMap<uint32_t, QString> m_dmrids;
	QMap<uint16_t, QString> m_nxdnids;
	char m_module;
	int m_port;
	QString m_label1;
	QString m_label2;
	QString m_label3;
	QString m_label4;
	QString m_label5;
	QString m_label6;
	QString m_data1;
	QString m_data2;
	QString m_data3;
	QString m_data4;
	QString m_data5;
	QString m_data6;
	QString m_ambestatustxt;
	QString m_mmdvmstatustxt;
	QString m_netstatustxt;
	QString m_mycall;
	QString m_urcall;
	QString m_rptr1;
	QString m_rptr2;
	int m_txtimeout;
	bool m_toggletx;
	QString m_dstarusertxt;
	QStringList m_hostsmodel;
	QMap<QString, QString> m_hostmap;
	QStringList m_customhosts;
	std::thread *m_modethread = nullptr;
	std::atomic<bool> m_threadRunning{false};
	Mode *m_mode;
	QByteArray user_data;
	QString m_localhosts;
	int m_iaxport;
	bool m_settings_processed;
	bool m_modelchange;
	const uint8_t header[5] = {0x80,0x44,0x53,0x56,0x54}; //DVSI packet header
	uint16_t m_outlevel;
	QString m_errortxt;
	bool m_xrf2ref;
	bool m_ipv6;
	QString m_vocoder;
	QString m_modem;
	QString m_playback;
	QString m_capture;
	QStringList m_vocoders;
	QStringList m_modems;
	QStringList m_playbacks;
	QStringList m_captures;
    bool m_mdirect;
	QString m_wt_callingname;
	QString m_wt_callingname_pass;

	int m_tts;
	QString m_ttstxt;

	QString m_modemRxFreq;
	QString m_modemTxFreq;
	QString m_modemRxOffset;
	QString m_modemTxOffset;
	QString m_modemRxDCOffset;
	QString m_modemTxDCOffset;
	QString m_modemRxLevel;
	QString m_modemTxLevel;
	QString m_modemRFLevel;
	QString m_modemTxDelay;
	QString m_modemCWIdTxLevel;
	QString m_modemDstarTxLevel;
	QString m_modemDMRTxLevel;
	QString m_modemYSFTxLevel;
	QString m_modemP25TxLevel;
	QString m_modemNXDNTxLevel;
	QString m_modemBaud;
	QString m_modemM17CAN;
	bool m_modemTxInvert;
	bool m_modemRxInvert;
	bool m_modemPTTInvert;
	uint32_t m_dmrColorCode;
#ifdef Q_OS_ANDROID
    AndroidSerialPort *m_USBmonitor;
#endif
	QString m_lastLogDate;
	QString m_lastLogTime;
	QString m_lastLogCallsign;
	QString m_lastLogName;
	QString m_lastLogCountry;
	int m_pttKey;

private slots:
#ifdef Q_OS_ANDROID
	void keepScreenOn();
#endif
	void discover_devices();
    void process_dstar_hosts(QString);
	void process_ysf_hosts();
	void process_fcs_rooms();
	void process_dmr_hosts();
	void process_p25_hosts();
	void process_nxdn_hosts();
	void process_m17_hosts();
    void process_iax_hosts();
    void process_asl_hosts();
	void process_dmr_ids();
	void process_nxdn_ids();
	void update_data(Mode::MODEINFO);
    void updatelog(QString);
	void save_settings();
	void update_output_level(unsigned short l){ m_outlevel = l;}
	//void load_md380_fw();
};

#endif // DROIDSTAR_H
