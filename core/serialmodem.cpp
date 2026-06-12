#include "serialmodem.h"
#include "MMDVMDefines.h"
#include <cstdio>
#include <cstring>

//#define DEBUGHW

SerialModem::SerialModem(const std::string& mode) {
    setMode(mode);
    m_dmrDelay = 0;
    m_debug = false;
    m_dmrColorCode = 1;
    m_m17TXHang = 5;
    m_ax25Enabled = false;
    m_configured = 0;
}

SerialModem::~SerialModem() {
    disconnect();
}

void SerialModem::setMode(const std::string& m) {
    m_dstarEnabled = false;
    m_dmrEnabled = false;
    m_ysfEnabled = false;
    m_p25Enabled = false;
    m_nxdnEnabled = false;
    m_pocsagEnabled = false;
    m_m17Enabled = false;

    if (m == "REF" || m == "DCS" || m == "XRF")
        m_dstarEnabled = true;
    else if (m == "DMR")
        m_dmrEnabled = true;
    else if (m == "YSF" || m == "FCS")
        m_ysfEnabled = true;
    else if (m == "P25")
        m_p25Enabled = true;
    else if (m == "NXDN")
        m_nxdnEnabled = true;
    else if (m == "M17")
        m_m17Enabled = true;
}

void SerialModem::setModemFlags(bool rxInvert, bool txInvert, bool pttInvert, bool useCOSAsLockout, bool duplex) {
    m_rxInvert = rxInvert;
    m_txInvert = txInvert;
    m_pttInvert = pttInvert;
    m_useCOSAsLockout = useCOSAsLockout;
    m_duplex = duplex;
    m_ysfLoDev = false;
}

void SerialModem::setModemParams(uint32_t baudrate, uint32_t rxfreq, uint32_t txfreq, uint32_t txDelay,
                                  float rxLevel, float rfLevel, uint32_t ysfTXHang,
                                  float cwIdTXLevel, float dstarTXLevel, float dmrTXLevel,
                                  float ysfTXLevel, float p25TXLevel, float nxdnTXLevel,
                                  float pocsagTXLevel, float m17TXLevel) {
    m_baudrate = baudrate;
    m_rxfreq = rxfreq;
    m_txfreq = txfreq;
    m_txDelay = txDelay;
    m_rxLevel = rxLevel;
    m_rfLevel = rfLevel;
    m_cwIdTXLevel = cwIdTXLevel;
    m_dstarTXLevel = dstarTXLevel;
    m_dmrTXLevel = dmrTXLevel;
    m_ysfTXLevel = ysfTXLevel;
    m_p25TXLevel = p25TXLevel;
    m_nxdnTXLevel = nxdnTXLevel;
    m_pocsagTXLevel = pocsagTXLevel;
    m_m17TXLevel = m17TXLevel;
    m_ysfTXHang = ysfTXHang;
}

bool SerialModem::connectToSerial(const std::string& port) {
    m_serial = new PosixSerial();
    if (!m_serial->open(port, m_baudrate)) {
        fprintf(stderr, "Failed to open modem serial port %s\n", port.c_str());
        delete m_serial;
        m_serial = nullptr;
        return false;
    }

    configModem();
    return true;
}

void SerialModem::disconnect() {
    if (m_serial) {
        m_serial->close();
        delete m_serial;
        m_serial = nullptr;
    }
    m_serialdata.clear();
}

void SerialModem::configModem() {
    std::vector<uint8_t> a;
    a.push_back(MMDVM_FRAME_START);
    a.push_back(3);
    a.push_back(MMDVM_GET_VERSION);
    m_serial->write(a);
}

void SerialModem::poll() {
    if (!m_serial || !m_serial->isOpen()) return;

    uint8_t buf[1024];
    int n;
    while ((n = m_serial->read(buf, sizeof(buf))) > 0) {
        for (int i = 0; i < n; i++)
            m_serialdata.push_back(buf[i]);
        processModem();
    }
}

void SerialModem::processSerial() {
    // Data already read; processModem already called from poll()
}

void SerialModem::processModem() {
    if (m_serialdata.size() < 3) return;

    if (m_serialdata[0] == MMDVM_FRAME_START && m_serialdata.size() >= m_serialdata[1]) {
        uint8_t r = m_serialdata[2];
        uint8_t s = m_serialdata[1];

        if (r == MMDVM_NAK) {
            fprintf(stderr, "Received MMDVM_NAK\n");
            while (s-- > 0 && !m_serialdata.empty())
                m_serialdata.pop_front();
        } else if (r == MMDVM_ACK) {
            fprintf(stderr, "Received MMDVM_ACK\n");
            while (s-- > 0 && !m_serialdata.empty())
                m_serialdata.pop_front();
        } else if (r == MMDVM_GET_VERSION) {
            if (m_serialdata.size() >= s) {
                m_protocol = m_serialdata[3];
                m_version.clear();
                uint8_t desc_offset = (m_protocol == 2) ? 23 : 4;
                for (int i = 0; i < (int)(s - desc_offset); ++i)
                    m_version += (char)m_serialdata[desc_offset + i];
                fprintf(stderr, "MMDVM Protocol %d: %s\n", m_protocol, m_version.c_str());
                if (on_modem_ready) on_modem_ready();
                m_configured = 1;
            }
            while (s-- > 0 && !m_serialdata.empty())
                m_serialdata.pop_front();
            return;
        } else if (r == MMDVM_GET_STATUS) {
            while (s-- > 0 && !m_serialdata.empty())
                m_serialdata.pop_front();
        } else if (m_serialdata.size() >= s) {
            std::vector<uint8_t> out;
            for (int i = 0; i < s; ++i) {
                out.push_back(m_serialdata.front());
                m_serialdata.pop_front();
            }
            if (on_modem_data_ready) on_modem_data_ready(out);
        }
    }

    if (m_configured == 1) {
        setFreq();
        m_configured++;
        return;
    }
    if (m_configured == 2) {
        setConfig();
        m_configured++;
        if (on_connected) on_connected(true);
    }
}

void SerialModem::getStatusModem() {
    std::vector<uint8_t> a;
    a.push_back(MMDVM_FRAME_START);
    a.push_back(3);
    a.push_back(MMDVM_GET_STATUS);
    m_serial->write(a);
}

void SerialModem::setFreq() {
    uint32_t pfreq = 433000000U;
    fprintf(stderr, "setFreq() rx:tx == %u:%u\n", m_rxfreq, m_txfreq);

    std::vector<uint8_t> out;
    out.push_back(MMDVM_FRAME_START);
    out.push_back(17);
    out.push_back(MMDVM_SET_FREQ);
    out.push_back(0x00);
    auto add32 = [&](uint32_t v) {
        out.push_back((v >> 0) & 0xFF);
        out.push_back((v >> 8) & 0xFF);
        out.push_back((v >> 16) & 0xFF);
        out.push_back((v >> 24) & 0xFF);
    };
    add32(m_rxfreq);
    add32(m_txfreq);
    out.push_back((uint8_t)(m_rfLevel * 2.55F + 0.5F));
    add32(pfreq);
    m_serial->write(out);
}

void SerialModem::setConfig() {
    std::vector<uint8_t> out;
    out.push_back(MMDVM_FRAME_START);

    if (m_protocol == 1)
        out.push_back(26U);
    else if (m_protocol == 2)
        out.push_back(40U);

    out.push_back(MMDVM_SET_CONFIG);

    uint8_t c = 0;
    if (m_rxInvert) c |= 0x01U;
    if (m_txInvert) c |= 0x02U;
    if (m_pttInvert) c |= 0x04U;
    if (m_ysfLoDev) c |= 0x08U;
    if (m_debug) c |= 0x10U;
    if (m_useCOSAsLockout) c |= 0x20U;
    if (!m_duplex) c |= 0x80U;
    out.push_back(c);

    c = 0;
    if (m_dstarEnabled) c |= 0x01U;
    if (m_dmrEnabled)  c |= 0x02U;
    if (m_ysfEnabled)  c |= 0x04U;
    if (m_p25Enabled)  c |= 0x08U;
    if (m_nxdnEnabled) c |= 0x10U;
    if (m_pocsagEnabled) c |= 0x20U;
    if (m_m17Enabled)  c |= 0x40U;
    out.push_back(c);

    if (m_protocol == 1) {
        out.push_back(m_txDelay / 10U);
        out.push_back(MODE_IDLE);
        out.push_back((uint8_t)(m_rxLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)(m_cwIdTXLevel * 2.55F + 0.5F));
        out.push_back(m_dmrColorCode);
        out.push_back(m_dmrDelay);
        out.push_back(128U);
        out.push_back((uint8_t)(m_dstarTXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)(m_dmrTXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)(m_ysfTXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)(m_p25TXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)(m_txDCOffset + 128));
        out.push_back((uint8_t)(m_rxDCOffset + 128));
        out.push_back((uint8_t)(m_nxdnTXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)m_ysfTXHang);
        out.push_back((uint8_t)(m_pocsagTXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)(m_fmTXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)m_p25TXHang);
        out.push_back((uint8_t)m_nxdnTXHang);
        out.push_back((uint8_t)(m_m17TXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)m_m17TXHang);
    } else if (m_protocol == 2) {
        c = 0;
        if (m_pocsagEnabled) c |= 0x01U;
        if (m_ax25Enabled)  c |= 0x02U;
        out.push_back(c);
        out.push_back(m_txDelay / 10U);
        out.push_back(MODE_IDLE);
        out.push_back((uint8_t)(m_txDCOffset + 128));
        out.push_back((uint8_t)(m_rxDCOffset + 128));
        out.push_back((uint8_t)(m_rxLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)(m_cwIdTXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)(m_dstarTXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)(m_dmrTXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)(m_ysfTXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)(m_p25TXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)(m_nxdnTXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)(m_m17TXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)(m_pocsagTXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)(m_fmTXLevel * 2.55F + 0.5F));
        out.push_back((uint8_t)(m_ax25TXLevel * 2.55F + 0.5F));
        out.push_back(0);
        out.push_back(0);
        out.push_back((uint8_t)m_ysfTXHang);
        out.push_back((uint8_t)m_p25TXHang);
        out.push_back((uint8_t)m_nxdnTXHang);
        out.push_back((uint8_t)m_m17TXHang);
        out.push_back(0);
        out.push_back(0);
        out.push_back(m_dmrColorCode);
        out.push_back(m_dmrDelay);
        out.push_back((uint8_t)(m_ax25RXTwist + 128));
        out.push_back(m_ax25TXDelay / 10U);
        out.push_back(m_ax25SlotTime / 10U);
        out.push_back(m_ax25PPersist);
        out.push_back(0);
        out.push_back(0);
        out.push_back(0);
        out.push_back(0);
        out.push_back(0);
    }

    m_serial->write(out);
}

void SerialModem::setMode(uint8_t m) {
    std::vector<uint8_t> out;
    out.push_back(MMDVM_FRAME_START);
    out.push_back(4);
    out.push_back(MMDVM_SET_MODE);
    out.push_back(m);
    m_serial->write(out);
}

void SerialModem::write(const std::vector<uint8_t>& data) {
    m_serial->write(data);
}

void SerialModem::write(const QByteArray& data) {
    m_serial->write(reinterpret_cast<const uint8_t*>(data.constData()), data.size());
}

std::vector<std::pair<std::string, std::string>> SerialModem::discoverDevices() {
    std::vector<std::pair<std::string, std::string>> devlist;
    auto ports = PosixSerial::availablePorts();
    for (const auto& p : ports) {
        devlist.push_back({p.path, p.description + ":" + p.path});
    }
    return devlist;
}
