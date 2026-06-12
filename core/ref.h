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

#ifndef REF_H
#define REF_H

#include "mode.h"

class REF : public Mode
{
public:
	REF();
	~REF();
	uint8_t * get_frame(uint8_t *ambe);
protected:
	uint8_t packet_size;
	bool m_sd_sync = false;
	int m_sd_txt_seq = 0;
	int m_sd_gps_cnt = 0;
	int m_sd_hdr_cnt = 0;
	int m_sd_debug_cnt = 0;
	char m_user_data[21]{};
	QByteArray m_gps_data;
	uint8_t m_debug_data[64]{};
	uint16_t m_txstreamid = 0;
	bool m_sendheader = true;
	void toggle_tx(bool);
	void start_tx();
	void process_modem_data(QByteArray);
	void process_rx_data();
	void get_ambe();
	void send_ping();
	void send_disconnect();
	void transmit();
	void format_callsign(std::string &s);
	void on_network_connected() override;
	void on_network_read(const uint8_t* data, int len) override;
	void module_changed(char m) { m_module = m; m_modeinfo.streamid = 0; }
	void send_frame(uint8_t *);
};

#endif // REF_H
