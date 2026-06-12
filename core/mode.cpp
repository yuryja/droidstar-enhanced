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
#include "mode.h"
#ifdef Q_OS_WIN
#include <windows.h>
#else
#include <dlfcn.h>
#endif

#include "m17.h"
#include "ysf.h"
#include "dmr.h"
#include "p25.h"
#include "nxdn.h"
#include "ref.h"
#include "xrf.h"
#include "dcs.h"
#include "iax.h"

#ifdef USE_FLITE
extern "C" {
extern cst_voice * register_cmu_us_slt(const char *);
extern cst_voice * register_cmu_us_kal16(const char *);
extern cst_voice * register_cmu_us_awb(const char *);
}
#endif

Mode* Mode::create_mode(const std::string& m)
{
	Mode *mode = nullptr;

	if(m == "M17"){
		mode = new M17();
	}
	else if(m == "YSF" || m == "FCS"){
		mode = new YSF();
	}
	else if(m == "DMR"){
		mode = new DMR();
	}
	else if(m == "P25"){
		mode = new P25();
	}
	else if(m == "NXDN"){
		mode = new NXDN();
	}
	else if(m == "REF"){
		mode = new REF();
	}
	else if(m == "XRF"){
		mode = new XRF();
	}
	else if(m == "DCS"){
		mode = new DCS();
	}
	else if(m == "IAX"){
		mode = new IAX();
	}
	return mode;
}

Mode::Mode()
{
}

Mode::~Mode()
{
    stop_timers();
    if (m_audio) {
        delete m_audio;
        m_audio = nullptr;
    }
    if (m_mbevocoder) {
        delete m_mbevocoder;
        m_mbevocoder = nullptr;
    }
#if !defined(Q_OS_IOS)
    if (m_modem) {
        delete m_modem;
        m_modem = nullptr;
    }
    if (m_ambedev) {
        delete m_ambedev;
        m_ambedev = nullptr;
    }
#endif
}

void Mode::init(QString callsign, uint32_t dmrid, uint16_t nxdnid, char module, std::string refname, std::string host, int port, bool ipv6, std::string vocoder, std::string modem, std::string audioin, std::string audioout, bool mdirect)
{
	m_dmrid = dmrid;
	m_nxdnid = nxdnid;
	m_module = module;
	m_refname = refname;
	m_ipv6 = ipv6;
	m_vocoder = vocoder;
	m_modemport = modem;
	m_audioin = audioin;
	m_audioout = audioout;
    m_mdirect = mdirect;

	m_modem = nullptr;
	m_ambedev = nullptr;
    m_mbevocoder = nullptr;
	m_hwrx = false;
	m_hwtx = false;
	m_tx = false;
	m_ttsid = 0;
    m_watchdog = 0;
	m_rxwatchdog = 0;

	m_modeinfo.callsign = callsign.toStdString();
	m_modeinfo.gwid = 0;
	m_modeinfo.srcid = dmrid;
	m_modeinfo.dstid = 0;
	m_modeinfo.host = host;
	m_modeinfo.port = port;
	m_modeinfo.count = 0;
	m_modeinfo.frame_number = 0;
	m_modeinfo.frame_total = 0;
	m_modeinfo.streamid = 0;
	m_modeinfo.stream_state = STREAM_IDLE;
	m_modeinfo.sw_vocoder_loaded = false;
	m_modeinfo.hw_vocoder_loaded = false;
#ifdef USE_FLITE
	flite_init();
	voice_slt = register_cmu_us_slt(nullptr);
	voice_kal = register_cmu_us_kal16(nullptr);
	voice_awb = register_cmu_us_awb(nullptr);
#endif
    m_debug = false;
}

void Mode::ambe_connect_status(bool s)
{
	if(s){
#if !defined(Q_OS_IOS)
		if (m_ambedev) {
			m_modeinfo.ambedesc = m_ambedev->getDescription();
			m_modeinfo.ambeprodid = m_ambedev->getProdId();
			m_modeinfo.ambeverstr = m_ambedev->getVerString();
		}
#endif
	}
	else{
		m_modeinfo.ambeprodid = "Connect failed";
		m_modeinfo.ambeverstr = "Connect failed";
	}
	notify_update(m_modeinfo);
}

void Mode::mmdvm_connect_status(bool s)
{
	if(s){
#if !defined(Q_OS_IOS)
		if (m_modem) m_modeinfo.mmdvm = m_modem->getVersion();
#endif
	}
	else{
		m_modeinfo.mmdvm = "Connect failed";
	}
	notify_update(m_modeinfo);
}

void Mode::in_audio_vol_changed(qreal v)
{
	if (m_audio) {
		m_audio->set_input_volume(v / m_attenuation);
	}
}

void Mode::out_audio_vol_changed(qreal v)
{
	m_audio->set_output_volume(v);
}

void Mode::agc_state_changed(int s)
{
	m_audio->set_agc(s);
}

void Mode::begin_connect()
{
	m_modeinfo.status = CONNECTING;

    if((m_vocoder != "None") && (m_vocoder != "Software vocoder") && (m_mode != "M17")){
        m_hwrx = true;
        m_hwtx = true;
        m_modeinfo.hw_vocoder_loaded = true;
#if !defined(Q_OS_IOS)
        m_ambedev = new SerialAMBE(m_mode);
        m_ambedev->on_connected = [this](bool s) { ambe_connect_status(s); };
        m_ambedev->on_data_ready = [this]() { get_ambe(); };
        m_ambedev->on_ambedev_ready = [this]() { host_lookup(); };
        if (m_ambedev) m_ambedev->connectToSerial(m_vocoder);
#endif
    }
    else{
        m_hwrx = false;
        m_hwtx = false;
        if(m_modemport.empty()){
            host_lookup();
        }
    }

    if(!m_modemport.empty()){
#if !defined(Q_OS_IOS)
        m_modem = new SerialModem(m_mode);
        m_modem->setModemFlags(m_rxInvert, m_txInvert, m_pttInvert, m_useCOSAsLockout, m_duplex);
        m_modem->setModemParams(m_baud, m_rxfreq, m_txfreq, m_txDelay, m_rxLevel, m_rfLevel, m_ysfTXHang, m_cwIdTXLevel, m_dstarTXLevel, m_dmrTXLevel, m_ysfTXLevel, m_p25TXLevel, m_nxdnTXLevel, m_pocsagTXLevel, m_m17TXLevel);
        m_modem->setCC(m_dmrColorCode);
        m_modem->on_connected = [this](bool s) { mmdvm_connect_status(s); };
        m_modem->on_modem_data_ready = [this](std::vector<uint8_t> d) {
            QByteArray qba(reinterpret_cast<const char*>(d.data()), (int)d.size());
            process_modem_data(qba);
        };
        m_modem->on_modem_ready = [this]() { host_lookup(); };
        m_cb_update_mode = [this](uint8_t m) { if (m_modem) m_modem->setMode(m); };
        m_modem->connectToSerial(m_modemport);
#endif
    }
}

void Mode::host_lookup()
{
	qDebug() << "Mode::host_lookup() called for mode" << m_mode.c_str() << "host=" << QString::fromStdString(m_modeinfo.host) << "mdirect=" << m_mdirect << "ipv6=" << m_ipv6;
    if(m_mdirect && ((m_mode == "M17") || (m_mode == "DMR"))){
        mmdvm_direct_connect();
        return;
    }
    if (m_modeinfo.host == "none" || m_modeinfo.host.empty()) {
        qDebug() << "No host to resolve";
        return;
    }
    if (m_udp) { delete m_udp; m_udp = nullptr; }
    m_udp = new UdpSocket();
    if (!m_udp->create(m_ipv6)) {
        qDebug() << "Failed to create UDP socket:" << m_udp->lastError().c_str();
        delete m_udp; m_udp = nullptr;
        return;
    }
    m_udp->setNonBlocking(true);
    if (!m_udp->connectTo(m_modeinfo.host, m_modeinfo.port)) {
        qDebug() << "Failed to resolve/connect:" << m_udp->lastError().c_str();
        delete m_udp; m_udp = nullptr;
        return;
    }
    on_network_connected();
}

void Mode::poll_network()
{
    if (!m_udp || !m_udp->isValid()) return;
    uint8_t buf[2048];
    int n;
    while ((n = m_udp->read(buf, sizeof(buf))) > 0) {
        on_network_read(buf, n);
    }
}

void Mode::toggle_tx(bool tx)
{
	tx ? start_tx() : stop_tx();
}

void Mode::start_tx()
{
	if (m_tx_interval_ms <= 0) {
		return;
	}
#if !defined(Q_OS_IOS)
	if(m_hwtx){
		if (m_ambedev) m_ambedev->clearQueue();
	}
#endif
	m_txcodecq.clear();
	m_tx = true;
	m_txcnt = 0;
	m_ttscnt = 0;
	m_modeinfo.streamid = 0;
	m_modeinfo.stream_state = TRANSMITTING;
#ifdef USE_FLITE

	if(m_ttsid == 1){
		tts_audio = flite_text_to_wave(m_ttstext.c_str(), voice_kal);
	}
	else if(m_ttsid == 2){
		tts_audio = flite_text_to_wave(m_ttstext.c_str(), voice_awb);
	}
	else if(m_ttsid == 3){
		tts_audio = flite_text_to_wave(m_ttstext.c_str(), voice_slt);
	}
#endif
	if(m_ttsid == 0 && m_audio){
		m_audio->set_input_buffer_size(640);
		m_audio->start_capture();
	}
}

void Mode::stop_tx()
{
	m_tx = false;
}

bool Mode::load_vocoder_plugin()
{
	if(m_vocoder == "None") {
		return false;
	}

    m_mbevocoder = new MBEVocoder();
    return true;
}

void Mode::deleteLater()
{
	if(m_modeinfo.status == CONNECTED_RW){
		send_disconnect();
		if (m_audio) {
			delete m_audio;
			m_audio = nullptr;
		}
#if !defined(Q_OS_IOS)
		if(m_ambedev){
			delete m_ambedev;
			m_ambedev = nullptr;
		}
		if(m_modem){
			delete m_modem;
			m_modem = nullptr;
		}
#endif
	}
	m_modeinfo.count = 0;
	delete this;
}

void Mode::disconnect_core()
{
	stop_timers();
	m_loop_running = false;
	if(m_modeinfo.status == CONNECTED_RW){
		send_disconnect();
		delete m_audio;  m_audio = nullptr;
#if !defined(Q_OS_IOS)
		delete m_ambedev; m_ambedev = nullptr;
		delete m_modem;   m_modem = nullptr;
#endif
	}
	m_modeinfo.count = 0;
}

void Mode::post_cmd(std::function<void()> cmd)
{
    std::lock_guard<std::mutex> lock(m_cmd_mutex);
    m_cmd_queue.push(std::move(cmd));
}

void Mode::run_loop()
{
	m_loop_running = true;
	begin_connect();
	while (m_loop_running) {

		// Drain command queue
		{
			std::lock_guard<std::mutex> lock(m_cmd_mutex);
			while (!m_cmd_queue.empty()) {
				auto cmd = std::move(m_cmd_queue.front());
				m_cmd_queue.pop();
				cmd();
			}
		}

		// Poll serial devices (replaces QSerialPort readyRead signal)
#if !defined(Q_OS_IOS)
		if (m_ambedev) m_ambedev->poll();
		if (m_modem) m_modem->poll();
#endif
		auto now = std::chrono::steady_clock::now();
		poll_network();
		if (m_rx_interval_ms > 0 &&
			now - m_last_rx_time >= std::chrono::milliseconds(m_rx_interval_ms)) {
			process_rx_data();
			m_last_rx_time = now;
		}
		if (m_tx_interval_ms > 0 &&
			now - m_last_tx_time >= std::chrono::milliseconds(m_tx_interval_ms)) {
			transmit();
			m_last_tx_time = now;
		}
		if (m_ping_interval_ms > 0 &&
			now - m_last_ping_time >= std::chrono::milliseconds(m_ping_interval_ms)) {
			send_ping();
			m_last_ping_time = now;
		}
		if (m_loop_running)
			std::this_thread::sleep_for(std::chrono::milliseconds(5));
	}
}

void Mode::stop_loop()   { m_loop_running = false; }
void Mode::stop_timers() { m_tx_interval_ms = 0; m_rx_interval_ms = 0; m_ping_interval_ms = 0; }
void Mode::start_tx_timer(int interval_ms)   { m_tx_interval_ms = interval_ms;   m_last_tx_time = std::chrono::steady_clock::now(); }
void Mode::start_rx_timer(int interval_ms)   { m_rx_interval_ms = interval_ms;   m_last_rx_time = std::chrono::steady_clock::now(); }
void Mode::start_ping_timer(int interval_ms) { m_ping_interval_ms = interval_ms; m_last_ping_time = std::chrono::steady_clock::now(); }


