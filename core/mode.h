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

#ifndef MODE_H
#define MODE_H

#include <string>
#include <functional>
#include <atomic>
#include <chrono>
#include <mutex>
#include <queue>
#include <QtCore>
#ifdef USE_FLITE
#include <flite/flite.h>
#endif
#include "imbe_vocoder/imbe_vocoder_api.h"
#include "mbe/mbevocoder_api.h"
#include "audioengine.h"
#include "udp_socket.h"
#if !defined(Q_OS_IOS)
#include "serialambe.h"
#include "serialmodem.h"
#endif

class Mode
{
public:
	Mode();
	~Mode();
	static Mode* create_mode(const std::string& m);
    void init(QString callsign, uint32_t dmrid, uint16_t nxdnid, char module, std::string refname, std::string host, int port, bool ipv6, std::string vocoder, std::string modem, std::string audioin, std::string audioout, bool mdirect);
	void set_modem_flags(bool rxInvert, bool txInvert, bool pttInvert, bool useCOSAsLockout, bool duplex)
	{
		m_rxInvert = rxInvert;
		m_txInvert = txInvert;
		m_pttInvert = pttInvert;
		m_useCOSAsLockout = useCOSAsLockout;
		m_duplex = duplex;
	}
	void set_modem_params(uint32_t baud, uint32_t rxfreq, uint32_t txfreq, uint32_t txDelay, float rxLevel, float rfLevel, uint32_t ysfTXHang, float cwIdTXLevel, float dstarTXLevel, float dmrTXLevel, float ysfTXLevel, float p25TXLevel, float nxdnTXLevel, float pocsagTXLevel, float m17TXLevel)
	{
		m_baud = baud;
		m_rxfreq = rxfreq;
		m_txfreq = txfreq;
		m_txDelay = txDelay;
		m_rxLevel = rxLevel;
		m_rfLevel = rfLevel;
		m_ysfTXHang = ysfTXHang;
		m_cwIdTXLevel = cwIdTXLevel;
		m_dstarTXLevel = dstarTXLevel;
		m_dmrTXLevel = dmrTXLevel;
		m_ysfTXLevel = ysfTXLevel;
		m_p25TXLevel = p25TXLevel;
		m_nxdnTXLevel = nxdnTXLevel;
		m_pocsagTXLevel = pocsagTXLevel;
		m_m17TXLevel = m17TXLevel;
	}
	virtual void set_dmr_params(uint8_t, QString, QString, QString, QString, QString, QString, QString, QString, QString, QString) {}
	virtual void set_iax_params(QString, QString, QString, QString, QString, int) {}
	void set_dmr_cc(uint32_t cc) { m_dmrColorCode = cc; }
	bool get_hwrx() const { return m_hwrx; }
	bool get_hwtx() const { return m_hwtx; }
	void set_hostname(std::string);
	void set_callsign(std::string);
	struct MODEINFO {
		qint64 ts;
		int status;
		int stream_state;
		std::string callsign;
		std::string gw;
		std::string gw2;
		std::string src;
		std::string dst;
		std::string usertxt;
		std::string netmsg;
		uint32_t gwid;
		uint32_t srcid;
		uint32_t dstid;
		uint8_t slot;
		uint8_t cc;
		std::string ambedesc;
		std::string ambeprodid;
		std::string ambeverstr;
		std::string mmdvmdesc;
		std::string mmdvm;
		std::string host;
        std::string module;
        std::string gps;
		int port;
		bool path;
		char type;
		uint16_t frame_number;
		uint8_t frame_total;
		int count;
		uint32_t streamid;
		bool mode;
		bool sw_vocoder_loaded;
		bool hw_vocoder_loaded;
	} m_modeinfo;
	enum{
		DISCONNECTED,
        TIMEOUT,
		CLOSED,
		CONNECTING,
		DMR_AUTH,
		DMR_CONF,
		DMR_OPTS,
		CONNECTED_RW,
		CONNECTED_RO
	};
	enum{
		STREAM_NEW,
		STREAMING,
		STREAM_END,
		STREAM_LOST,
		STREAM_IDLE,
		TRANSMITTING,
		TRANSMITTING_MODEM,
        STREAM_UNKNOWN,
        PACKET_RECEIVED,
        PACKET_SENT
	};
    // Callbacks (replacing Qt signals for thread-safe dispatch)
    using on_update_cb = std::function<void(MODEINFO)>;
    using on_log_cb = std::function<void(std::string)>;
    using on_output_level_cb = std::function<void(unsigned short)>;
    using on_update_mode_cb = std::function<void(uint8_t)>;
    using on_connect_toggle_cb = std::function<void()>;
    using on_reconnect_cb = std::function<void(int)>;

    on_update_cb m_cb_update;
    on_log_cb m_cb_log;
    on_output_level_cb m_cb_output_level;
    on_update_mode_cb m_cb_update_mode;
    on_connect_toggle_cb m_cb_connect_toggle;
    on_reconnect_cb m_cb_reconnect;

    void notify_update(MODEINFO info) { if(m_cb_update) m_cb_update(info); }
    void notify_log(const std::string& msg) { if(m_cb_log) m_cb_log(msg); }
    void notify_output_level(unsigned short lvl) { if(m_cb_output_level) m_cb_output_level(lvl); }
    void notify_update_mode(uint8_t mode) { if(m_cb_update_mode) m_cb_update_mode(mode); }
    void notify_connect_toggle() { if(m_cb_connect_toggle) m_cb_connect_toggle(); }
    void notify_reconnect(int ms) { if(m_cb_reconnect) m_cb_reconnect(ms); }

    void disconnect_core();

    virtual void on_network_connected() {}
    virtual void on_network_read(const uint8_t* data, int len) { (void)data; (void)len; }
    void poll_network();

    virtual void transmit() {}
    virtual void process_rx_data() {}
    virtual void send_ping() {}

    void run_loop();
    void stop_loop();
    void start_tx_timer(int interval_ms);
    void start_rx_timer(int interval_ms);
    void start_ping_timer(int interval_ms);
    void stop_timers();
    std::atomic<bool> m_loop_running{false};

    // Command queue for thread-safe dispatch from DroidStar (main thread)
    void post_cmd(std::function<void()> cmd);

    // Serial modem dispatch (called from run_loop)
    void poll_modem();

    // Public serial reads for protocol subclasses
    virtual void get_ambe() {}
    virtual void process_modem_data(QByteArray) {}
    // Protocol-specific dispatch (called via command queue from DroidStar)
    virtual void dmr_tgid_changed(int) {}
    virtual void dmrpc_state_changed(int) {}
    virtual void slot_changed(int) {}
    virtual void cc_changed(int) {}
    virtual void rate_changed(int) {}
    virtual void can_changed(int) {}
    virtual void tx_packet(std::string) {}
    virtual void send_dtmf(QByteArray) {}

    // Methods callable from DroidStar via command queue (were protected slots)
    void deleteLater();
    virtual void send_disconnect(){}
    virtual void mmdvm_direct_connect(){}
    void ambe_connect_status(bool);
    void mmdvm_connect_status(bool);
    void begin_connect();
    void input_src_changed(int id, std::string t) { m_ttsid = id; m_ttstext = t; }
    void start_tx();
    void stop_tx();
    void toggle_tx(bool);
    void in_audio_vol_changed(qreal);
    void out_audio_vol_changed(qreal);
    bool load_vocoder_plugin();
    void swrx_state_changed(int s) {m_hwrx = !s; }
    void swtx_state_changed(int s) {m_hwtx = !s; }
    void agc_state_changed(int s);
    void mycall_changed(std::string mc) { m_txmycall = mc; }
    void urcall_changed(std::string uc) { m_txurcall = uc; }
    void rptr1_changed(std::string r1) { m_txrptr1 = r1; }
    void rptr2_changed(std::string r2) { m_txrptr2 = r2; }
    void usrtxt_changed(std::string t) { m_txusrtxt = t; }
    void module_changed(char m) { m_module = m; m_modeinfo.streamid = 0; }
    void dst_changed(std::string dst){ m_refname = dst; }
    void host_lookup();
    void debug_changed(bool debug){ m_debug = debug; }
protected:
    std::string m_mode;
	UdpSocket *m_udp = nullptr;
	char m_module;
    uint8_t m_watchdog;
	uint32_t m_dmrid;
	uint16_t m_nxdnid;
	std::string m_refname;
	bool m_tx;
	uint16_t m_txcnt = 0;
	uint16_t m_ttscnt = 0;
	uint8_t m_ttsid;
	std::string m_ttstext;
	std::string m_txmycall;
	std::string m_txurcall;
	std::string m_txrptr1;
	std::string m_txrptr2;
	std::string m_txusrtxt;
#ifdef USE_FLITE
	cst_voice *voice_slt;
	cst_voice *voice_kal;
	cst_voice *voice_awb;
	cst_wave *tts_audio = nullptr;
#endif
	AudioEngine *m_audio = nullptr;
	std::string m_audioin;
	std::string m_audioout;
    bool m_mdirect;
	uint32_t m_rxwatchdog;
	uint8_t m_attenuation = 0;

	std::chrono::steady_clock::time_point m_last_tx_time;
	std::chrono::steady_clock::time_point m_last_rx_time;
	std::chrono::steady_clock::time_point m_last_ping_time;
	int m_tx_interval_ms = 0;
	int m_rx_interval_ms = 0;
	int m_ping_interval_ms = 0;
	QQueue<uint8_t> m_rxcodecq;
	QQueue<uint8_t> m_txcodecq;
	QQueue<uint8_t> m_rxmodemq;
    imbe_vocoder m_imbevocoder;
    MBEVocoder *m_mbevocoder;
	std::string m_vocoder;
	std::string m_modemport;
#if defined(Q_OS_IOS)
	void *m_modem;
	void *m_ambedev;
#else
	SerialModem *m_modem;
	SerialAMBE *m_ambedev;
#endif
	bool m_hwrx;
	bool m_hwtx;
	bool m_ipv6;

	uint32_t m_baud;
	uint32_t m_rxfreq;
	uint32_t m_txfreq;
	uint32_t m_dmrColorCode;
	bool m_ysfLoDev;
	uint32_t m_ysfTXHang;
	uint32_t m_p25TXHang;
	uint32_t m_nxdnTXHang;
	bool m_duplex;
	bool m_rxInvert;
	bool m_txInvert;
	bool m_pttInvert;
	uint32_t m_txDelay;
	uint32_t m_dmrDelay;
	float m_rxLevel;
	float m_rfLevel;
	float m_cwIdTXLevel;
	float m_dstarTXLevel;
	float m_dmrTXLevel;
	float m_ysfTXLevel;
	float m_p25TXLevel;
	float m_nxdnTXLevel;
	float m_pocsagTXLevel;
	float m_fmTXLevel;
	float m_m17TXLevel;
	bool m_debug;
	bool m_useCOSAsLockout;
	bool m_dstarEnabled;
	bool m_dmrEnabled;
	bool m_ysfEnabled;
	bool m_p25Enabled;
	bool m_nxdnEnabled;
	bool m_pocsagEnabled;
	bool m_fmEnabled;
	int m_rxDCOffset;
	int m_txDCOffset;

    // Command queue
    std::mutex m_cmd_mutex;
    std::queue<std::function<void()>> m_cmd_queue;
};

#endif // MODE_H
