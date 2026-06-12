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

#include <cstring>
#include "xrf.h"
#include "CRCenc.h"
#include "MMDVMDefines.h"

XRF::XRF()
{
    m_mode = "XRF";
	m_attenuation = 5;
}

XRF::~XRF()
{
}

void XRF::on_network_read(const uint8_t* data, int len)
{
    QByteArray buf(reinterpret_cast<const char*>(data), len);

    if(m_debug){
        QDebug debug = qDebug();
        debug.noquote();
        QString s = "RECV:";
        for(int i = 0; i < buf.size(); ++i){
            s += " " + QString("%1").arg((uint8_t)buf.data()[i], 2, 16, QChar('0'));
        }
        debug << s;
    }

	if(buf.size() == 9){
		m_modeinfo.count++;
		if( (m_modeinfo.stream_state == STREAM_LOST) || (m_modeinfo.stream_state == STREAM_END) ){
			m_modeinfo.stream_state = STREAM_IDLE;
		}
	}

	if( (m_modeinfo.status == CONNECTING) && (buf.size() == 14) && (!memcmp(buf.data()+10, "ACK", 3)) ){
		m_modeinfo.status = CONNECTED_RW;
		m_modeinfo.sw_vocoder_loaded = load_vocoder_plugin();
		start_rx_timer(20);
		start_tx_timer(19);
		start_ping_timer(1000);
		m_audio = new AudioEngine(m_audioin, m_audioout);
		m_audio->init();
	}

	if((buf.size() == 56) && (!memcmp(buf.data(), "DSVT", 4)) ){
		uint16_t streamid = (buf.data()[12] << 8) | (buf.data()[13] & 0xff);
		if( (m_modeinfo.streamid != 0) && (streamid != m_modeinfo.streamid) ){
			qDebug() << "New header received before timeout";
			m_modeinfo.streamid = 0;
			if (m_audio) m_audio->stop_playback();
		}
		if(!m_tx && (m_modeinfo.streamid == 0)){
			char temp[9];
			memcpy(temp, buf.data() + 18, 8); temp[8] = '\0';
			m_modeinfo.gw2 = temp;
			memcpy(temp, buf.data() + 26, 8); temp[8] = '\0';
			m_modeinfo.gw = temp;
			memcpy(temp, buf.data() + 34, 8); temp[8] = '\0';
			m_modeinfo.dst = temp;
			memcpy(temp, buf.data() + 42, 8); temp[8] = '\0';
			m_modeinfo.src = temp;
			QString h = QString::fromStdString(m_refname) + " " + m_module;
			m_modeinfo.streamid = streamid;
			m_modeinfo.stream_state = STREAM_NEW;
			m_modeinfo.ts = QDateTime::currentMSecsSinceEpoch();

			if (m_audio) m_audio->start_playback();

			if(m_modem){
				uint8_t out[44];
				out[0] = MMDVM_FRAME_START;
				out[1] = 44;
				out[2] = MMDVM_DSTAR_HEADER;
				out[3] = 0x40;
				out[4] = 0;
				out[5] = 0;
				memcpy(out + 6, m_modeinfo.gw2.c_str(), 8);
				memcpy(out + 14, m_modeinfo.gw.c_str(), 8);
				memcpy(out + 22, m_modeinfo.dst.c_str(), 8);
				memcpy(out + 30, m_modeinfo.src.c_str(), 8);
				memcpy(out + 38, buf.data() + 50, 4);
				CCRC::addCCITT161((uint8_t *)out + 3, 41);
				for(int i = 0; i < 44; ++i){
					m_rxmodemq.append(out[i]);
				}
				//if (m_modem) m_modem->write(out);
			}

			qDebug() << "New stream from " << QString::fromStdString(m_modeinfo.src) << " to " << QString::fromStdString(m_modeinfo.dst) << " id == " << QString::number(m_modeinfo.streamid, 16);
			notify_update(m_modeinfo);
		}
		m_rxwatchdog = 0;
	}

	if((buf.size() == 27) && (!memcmp(buf.data(), "DSVT", 4))) {
		m_rxwatchdog = 0;
		uint16_t streamid = (buf.data()[12] << 8) | (buf.data()[13] & 0xff);
		if( (streamid != m_modeinfo.streamid) ){
			qDebug() << "New data packet received before timeout";
			m_modeinfo.streamid = streamid;
			if (m_audio) m_audio->start_playback();
		}
		if(!m_tx && ( (m_modeinfo.stream_state == STREAM_LOST) || (m_modeinfo.stream_state == STREAM_END) || (m_modeinfo.stream_state == STREAM_IDLE) )){
			if (m_audio) m_audio->start_playback();
			m_modeinfo.stream_state = STREAM_NEW;
		}
		else{
			m_modeinfo.stream_state = STREAMING;
		}
		m_modeinfo.streamid = streamid;
		m_modeinfo.frame_number = (uint8_t)buf.data()[14];

		if(m_modeinfo.frame_number & 0x40){
			qDebug() << "XRF RX stream ended ";
			m_rxwatchdog = 0;
			m_modeinfo.stream_state = STREAM_END;
			m_modeinfo.ts = QDateTime::currentMSecsSinceEpoch();
			notify_update(m_modeinfo);
			m_modeinfo.streamid = 0;
			if(m_modem){
				m_rxmodemq.append(0xe0);
				m_rxmodemq.append(3);
				m_rxmodemq.append(MMDVM_DSTAR_EOT);
			}
		}
		else if(m_modem){
			m_rxmodemq.append(MMDVM_FRAME_START);
			m_rxmodemq.append(15);
			m_rxmodemq.append(MMDVM_DSTAR_DATA);
			for(int i = 0; i < 12; ++i){
				m_rxmodemq.append(buf.data()[15+i]);
			}
		}

		if((buf.data()[14] == 0) && (buf.data()[24] == 0x55) && (buf.data()[25] == 0x2d) && (buf.data()[26] == 0x16)){
			m_sd_sync = 1;
			m_sd_seq = 1;
		}
		if(m_sd_sync && (m_sd_seq == 1) && (buf.data()[14] == 1) && (buf.data()[24] == 0x30)){
			m_user_data[0] = buf.data()[25] ^ 0x4f;
			m_user_data[1] = buf.data()[26] ^ 0x93;
			++m_sd_seq;
		}
		if(m_sd_sync && (m_sd_seq == 2) && (buf.data()[14] == 2)){
			m_user_data[2] = buf.data()[24] ^ 0x70;
			m_user_data[3] = buf.data()[25] ^ 0x4f;
			m_user_data[4] = buf.data()[26] ^ 0x93;
			++m_sd_seq;
		}
		if(m_sd_sync && (m_sd_seq == 3) && (buf.data()[14] == 3) && (buf.data()[24] == 0x31)){
			m_user_data[5] = buf.data()[25] ^ 0x4f;
			m_user_data[6] = buf.data()[26] ^ 0x93;
			++m_sd_seq;
		}
		if(m_sd_sync && (m_sd_seq == 4) && (buf.data()[14] == 4)){
			m_user_data[7] = buf.data()[24] ^ 0x70;
			m_user_data[8] = buf.data()[25] ^ 0x4f;
			m_user_data[9] = buf.data()[26] ^ 0x93;
			++m_sd_seq;
		}
		if(m_sd_sync && (m_sd_seq == 5) && (buf.data()[14] == 5) && (buf.data()[24] == 0x32)){
			m_user_data[10] = buf.data()[25] ^ 0x4f;
			m_user_data[11] = buf.data()[26] ^ 0x93;
			++m_sd_seq;
		}
		if(m_sd_sync && (m_sd_seq == 6) && (buf.data()[14] == 6)){
			m_user_data[12] = buf.data()[24] ^ 0x70;
			m_user_data[13] = buf.data()[25] ^ 0x4f;
			m_user_data[14] = buf.data()[26] ^ 0x93;
			++m_sd_seq;
		}
		if(m_sd_sync && (m_sd_seq == 7) && (buf.data()[14] == 7) && (buf.data()[24] == 0x33)){
			m_user_data[15] = buf.data()[25] ^ 0x4f;
			m_user_data[16] = buf.data()[26] ^ 0x93;
			++m_sd_seq;
		}
		if(m_sd_sync && (m_sd_seq == 8) && (buf.data()[14] == 8)){
			m_user_data[17] = buf.data()[24] ^ 0x70;
			m_user_data[18] = buf.data()[25] ^ 0x4f;
			m_user_data[19] = buf.data()[26] ^ 0x93;
			m_user_data[20] = '\0';
			m_sd_sync = 0;
			m_sd_seq = 0;
			m_modeinfo.usertxt = m_user_data;
		}
		for(int i = 0; i < 9; ++i){
			m_rxcodecq.append(buf.data()[15+i]);
		}
	}
	notify_update(m_modeinfo);
}

void XRF::on_network_connected() {
    QByteArray out;
    out.append(QByteArray::fromStdString(m_modeinfo.callsign));
    out.append(8 - m_modeinfo.callsign.size(), ' ');
    out.append(m_module);
    out.append(m_module);
    out.append(11);
    m_udp->write((const uint8_t*)out.constData(), out.size());

    if(m_debug){
        QDebug debug = qDebug();
        debug.noquote();
        QString s = "CONN:";
        for(int i = 0; i < out.size(); ++i){
            s += " " + QString("%1").arg((uint8_t)out.data()[i], 2, 16, QChar('0'));
        }
        debug << s;
    }
}

void XRF::send_ping()
{
	QByteArray out;
	out.append(QByteArray::fromStdString(m_modeinfo.callsign));
	out.append(8 - m_modeinfo.callsign.size(), ' ');
	out.append('\x00');
	m_udp->write((const uint8_t*)out.constData(), out.size());

    if(m_debug){
        QDebug debug = qDebug();
        debug.noquote();
        QString s = "PING:";
        for(int i = 0; i < out.size(); ++i){
            s += " " + QString("%1").arg((uint8_t)out.data()[i], 2, 16, QChar('0'));
        }
        debug << s;
    }
}

void XRF::send_disconnect()
{
	QByteArray out;
	out.append(QByteArray::fromStdString(m_modeinfo.callsign));
	out.append(8 - m_modeinfo.callsign.size(), ' ');
	out.append(m_module);
	out.append(' ');
	out.append('\x00');
	m_udp->write((const uint8_t*)out.constData(), out.size());

    if(m_debug){
        QDebug debug = qDebug();
        debug.noquote();
        QString s = "DISC:";
        for(int i = 0; i < out.size(); ++i){
            s += " " + QString("%1").arg((uint8_t)out.data()[i], 2, 16, QChar('0'));
        }
        debug << s;
    }
}

void XRF::format_callsign(std::string &s)
{
	size_t start = s.find_first_not_of(' ');
	if (start == std::string::npos) {
		s = std::string(8, ' ');
		return;
	}
	size_t end = s.find_last_not_of(' ');
	std::string trimmed = s.substr(start, end - start + 1);

	size_t space_pos = trimmed.find(' ');
	if (space_pos != std::string::npos) {
		std::string part1 = trimmed.substr(0, space_pos);
		size_t part2_start = trimmed.find_first_not_of(' ', space_pos);
		if (part2_start != std::string::npos) {
			std::string part2 = trimmed.substr(part2_start);
			if (part1.size() < 7) {
				part1.append(7 - part1.size(), ' ');
			}
			s = part1 + part2;
		} else {
			s = part1;
			if (s.size() < 8) {
				s.append(8 - s.size(), ' ');
			}
		}
	} else {
		s = trimmed;
		if (s.size() < 8) {
			s.append(8 - s.size(), ' ');
		}
	}
}

void XRF::process_modem_data(QByteArray d)
{
	char cs[9];
	uint8_t ambe[9];

	uint8_t *p_frame = (uint8_t *)(d.data());
	if(p_frame[2] == MMDVM_DSTAR_HEADER){
		format_callsign(m_txrptr1);
		format_callsign(m_txrptr2);
		cs[8] = 0;
		memcpy(cs, p_frame + 22, 8);
		m_txurcall = std::string(cs);
		memcpy(cs, p_frame + 30, 8);
		m_txmycall = std::string(cs);
		m_modeinfo.stream_state = TRANSMITTING_MODEM;
		m_tx = true;
	}
	else if( (p_frame[2] == MMDVM_DSTAR_EOT) || (p_frame[2] == MMDVM_DSTAR_LOST) ){
		m_tx = false;
	}
	else if(p_frame[2] == MMDVM_DSTAR_DATA){
		memcpy(ambe, p_frame + 3, 9);
	}
	send_frame(ambe);
}

void XRF::toggle_tx(bool tx)
{
	tx ? start_tx() : stop_tx();
}

void XRF::start_tx()
{
	format_callsign(m_txmycall);
	format_callsign(m_txurcall);
	format_callsign(m_txrptr1);
	format_callsign(m_txrptr2);
	Mode::start_tx();
}

void XRF::transmit()
{
	uint8_t ambe[9]{};
	uint8_t ambe_frame[72]{};
	int16_t pcm[160]{};
	
#ifdef USE_FLITE
	if(m_ttsid > 0){
		for(int i = 0; i < 160; ++i){
			if(m_ttscnt >= tts_audio->num_samples/2){
				pcm[i] = 0;
			}
			else{
				pcm[i] = tts_audio->samples[m_ttscnt*2] / 8;
				m_ttscnt++;
			}
		}
	}
#endif
	if(m_ttsid == 0){
		if(m_audio && m_audio->read(pcm, 160)){
		}
		else{
			return;
		}
	}
	if(m_hwtx){
#if !defined(Q_OS_IOS)
		if (m_ambedev) m_ambedev->encode(pcm);
#endif
		if(m_tx && (m_txcodecq.size() >= 9)){
			for(int i = 0; i < 9; ++i){
				ambe[i] = m_txcodecq.dequeue();
			}
			send_frame(ambe);
		}
		else if(!m_tx){
			send_frame(ambe);
		}
	}
	else{
		if(m_modeinfo.sw_vocoder_loaded){
			m_mbevocoder->encode_2400x1200(pcm, ambe);
		}
		send_frame(ambe);
	}
}

void XRF::send_frame(uint8_t *ambe)
{
	QByteArray txdata;

	if(m_txstreamid == 0){
		m_txstreamid = static_cast<uint16_t>((::rand() & 0xFFFF));
	}

	if(m_sendheader){
		m_sendheader = 0;
		txdata.resize(56);
		txdata[0] = 0x44;
		txdata[1] = 0x53;
		txdata[2] = 0x56;
		txdata[3] = 0x54;
		txdata[4] = 0x10;
		txdata[5] = 0x00;
		txdata[6] = 0x00;
		txdata[7] = 0x00;
		txdata[8] = 0x20;
		txdata[9] = 0x00;
		txdata[10] = 0x01;
		txdata[11] = 0x02;
		txdata[12] = (m_txstreamid >> 8) & 0xff;
		txdata[13] = m_txstreamid & 0xff;
		txdata[14] = 0x80;
		txdata[15] = 0x00;
		txdata[16] = 0x00;
		txdata[17] = 0x00;
        txdata.replace(18, 8, m_txrptr2.c_str());
        txdata.replace(26, 8, m_txrptr1.c_str());
        txdata.replace(34, 8, m_txurcall.c_str());
        txdata.replace(42, 8, m_txmycall.c_str());
        txdata.replace(50, 4, "AMBE");
        CCRC::addCCITT161((uint8_t *)txdata.data() + 15, 41);

		m_modeinfo.src = m_txmycall;
		m_modeinfo.dst = m_txurcall;
		m_modeinfo.gw = m_txrptr1;
		m_modeinfo.gw2 = m_txrptr2;
		m_modeinfo.streamid = m_txstreamid;
		m_modeinfo.frame_number = m_txcnt % 21;
	}
	else{
		txdata.resize(27);
		txdata[0] = 0x44;
		txdata[1] = 0x53;
		txdata[2] = 0x56;
		txdata[3] = 0x54;
		txdata[4] = 0x20;
		txdata[5] = 0x00;
		txdata[6] = 0x00;
		txdata[7] = 0x00;
		txdata[8] = 0x20;
		txdata[9] = 0x00;
		txdata[10] = 0x01;
		txdata[11] = 0x02;
		txdata[12] = (m_txstreamid >> 8) & 0xff;
		txdata[13] = m_txstreamid & 0xff;
		txdata[14] = m_txcnt % 21;
		memcpy(txdata.data() + 15, ambe, 9);

		m_modeinfo.frame_number = m_txcnt % 21;

		switch(txdata.data()[14]){
		case 0:
			txdata[24] = 0x55;
			txdata[25] = 0x2d;
			txdata[26] = 0x16;
			break;
		case 1:
			txdata[24] = 0x40 ^ 0x70;
			txdata[25] = m_txusrtxt[0] ^ 0x4f;
			txdata[26] = m_txusrtxt[1] ^ 0x93;
			break;
		case 2:
			txdata[24] = m_txusrtxt[2] ^ 0x70;
			txdata[25] = m_txusrtxt[3] ^ 0x4f;
			txdata[26] = m_txusrtxt[4] ^ 0x93;
			break;
		case 3:
			txdata[24] = 0x41 ^ 0x70;
			txdata[25] = m_txusrtxt[5] ^ 0x4f;
			txdata[26] = m_txusrtxt[6] ^ 0x93;
			break;
		case 4:
			txdata[24] = m_txusrtxt[7] ^ 0x70;
			txdata[25] = m_txusrtxt[8] ^ 0x4f;
			txdata[26] = m_txusrtxt[9] ^ 0x93;
			break;
		case 5:
			txdata[24] = 0x42 ^ 0x70;
			txdata[25] = m_txusrtxt[10] ^ 0x4f;
			txdata[26] = m_txusrtxt[11] ^ 0x93;
			break;
		case 6:
			txdata[24] = m_txusrtxt[12] ^ 0x70;
			txdata[25] = m_txusrtxt[13] ^ 0x4f;
			txdata[26] = m_txusrtxt[14] ^ 0x93;
			break;
		case 7:
			txdata[24] = 0x43 ^ 0x70;
			txdata[25] = m_txusrtxt[15] ^ 0x4f;
			txdata[26] = m_txusrtxt[16] ^ 0x93;
			break;
		case 8:
			txdata[24] = m_txusrtxt[17] ^ 0x70;
			txdata[25] = m_txusrtxt[18] ^ 0x4f;
			txdata[26] = m_txusrtxt[19] ^ 0x93;
			break;
		default:
			txdata[24] = 0x16;
			txdata[25] = 0x29;
			txdata[26] = 0xf5;
			break;
		}
	}

	if(m_tx){
		m_txcnt++;
	}
	else{
		txdata[14] = (++m_txcnt % 21) | 0x40;
		m_txcnt = 0;
		m_txstreamid = 0;
		m_modeinfo.streamid = 0;
		m_sendheader = 1;
		stop_timers();

		if((m_ttsid == 0) && (m_modeinfo.stream_state == TRANSMITTING) ){
			if (m_audio) m_audio->stop_capture();
		}

		m_ttscnt = 0;
		m_modeinfo.stream_state = STREAM_IDLE;
	}

	m_udp->write((const uint8_t*)txdata.constData(), txdata.size());
	if (m_audio) notify_output_level(m_audio->level() * 2);
	notify_update(m_modeinfo);

    if(m_debug){
        QDebug debug = qDebug();
        debug.noquote();
        QString s = "SEND:";
        for(int i = 0; i < txdata.size(); ++i){
            s += " " + QString("%1").arg((uint8_t)txdata.data()[i], 2, 16, QChar('0'));
        }
        debug << s;
    }
}

void XRF::get_ambe()
{
#if !defined(Q_OS_IOS)
	uint8_t ambe[9];

	if(m_ambedev && m_ambedev->getAmbe(ambe)){
		for(int i = 0; i < 9; ++i){
			m_txcodecq.append(ambe[i]);
		}
	}
#endif
}

void XRF::process_rx_data()
{
    poll_network();
	int16_t pcm[160];
	uint8_t ambe[9];

	if(m_rxwatchdog++ > 100){
		qDebug() << "XRF RX stream timeout ";
		m_rxwatchdog = 0;
		m_modeinfo.stream_state = STREAM_LOST;
		m_modeinfo.ts = QDateTime::currentMSecsSinceEpoch();
		notify_update(m_modeinfo);
		m_modeinfo.streamid = 0;
	}

	if(m_rxmodemq.size() > 2){
		QByteArray out;
		int s = m_rxmodemq[1];
		if((m_rxmodemq[0] == MMDVM_FRAME_START) && (m_rxmodemq.size() >= s)){
			for(int i = 0; i < s; ++i){
				out.append(m_rxmodemq.dequeue());
			}
#if !defined(Q_OS_IOS)
			if (m_modem) m_modem->write(out);
#endif
		}
	}

	if((!m_tx) && (m_rxcodecq.size() > 8) ){
		for(int i = 0; i < 9; ++i){
			ambe[i] = m_rxcodecq.dequeue();
		}
		if(m_hwrx){
#if !defined(Q_OS_IOS)
			if (m_ambedev) m_ambedev->decode(ambe);

			if(m_ambedev && m_ambedev->getAudio(pcm)){
				if (m_audio) m_audio->write(pcm, 160);
				if (m_audio) notify_output_level(m_audio->level());
			}
#endif
		}
		else{
			if(m_modeinfo.sw_vocoder_loaded){
				m_mbevocoder->decode_2400x1200(pcm, ambe);
			}
			else{
				memset(pcm, 0, 160 * sizeof(int16_t));
			}
			if (m_audio) m_audio->write(pcm, 160);
			if (m_audio) notify_output_level(m_audio->level());
		}
	}
	else if ( (m_modeinfo.stream_state == STREAM_END) || (m_modeinfo.stream_state == STREAM_LOST) ){
		stop_timers();
		if (m_audio) m_audio->stop_playback();
		m_rxwatchdog = 0;
		m_modeinfo.streamid = 0;
		m_rxcodecq.clear();
		qDebug() << "XRF playback stopped";
		m_modeinfo.stream_state = STREAM_IDLE;
		return;
	}
}
