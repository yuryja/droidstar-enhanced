#include "serialambe.h"
#include <cstring>
#include <cmath>
#include <thread>
#include <cstdio>

#define AMBE3000_START_BYTE     0x61
#define AMBE3000_TYPE_CONFIG    0x00
#define AMBE3000_TYPE_CHANNEL   0x01
#define AMBE3000_TYPE_SPEECH    0x02
#define AMBE3000_PKT_RATEP      0x0a
#define AMBE3000_PKT_INIT       0x0b
#define AMBE3000_PKT_PRODID     0x30
#define AMBE3000_PKT_VERSTRING  0x31
#define AMBE3000_PKT_READY      0x39
#define AMBE3000_PKT_RESET      0x33
#define AMBE3000_PKT_PARITYMODE 0x3f

static const uint8_t AMBEP251_4400_2800[17] = {AMBE3000_START_BYTE, 0x00, 0x0d, AMBE3000_TYPE_CONFIG, AMBE3000_PKT_RATEP, 0x05U, 0x58U, 0x08U, 0x6BU, 0x10U, 0x30U, 0x00U, 0x00U, 0x00U, 0x00U, 0x01U, 0x90U};
static const uint8_t AMBE2000_2400_1200[17] = {AMBE3000_START_BYTE, 0x00, 0x0d, AMBE3000_TYPE_CONFIG, AMBE3000_PKT_RATEP, 0x01U, 0x30U, 0x07U, 0x63U, 0x40U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x48U};
static const uint8_t AMBE3000_2450_1150[17] = {AMBE3000_START_BYTE, 0x00, 0x0d, AMBE3000_TYPE_CONFIG, AMBE3000_PKT_RATEP, 0x04U, 0x31U, 0x07U, 0x54U, 0x24U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x6fU, 0x48U};
static const uint8_t AMBE3000_2450_0000[17] = {AMBE3000_START_BYTE, 0x00, 0x0d, AMBE3000_TYPE_CONFIG, AMBE3000_PKT_RATEP, 0x04U, 0x31U, 0x07U, 0x54U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x00U, 0x70U, 0x31U};
static const uint8_t AMBE3000_PARITY_DISABLE[8] = {AMBE3000_START_BYTE, 0x00, 0x04, AMBE3000_TYPE_CONFIG, AMBE3000_PKT_PARITYMODE, 0x00, 0x2f, 0x14};
static const uint8_t AMBE3000_PRODID[5] = {AMBE3000_START_BYTE, 0x00, 0x01, AMBE3000_TYPE_CONFIG, AMBE3000_PKT_PRODID};
static const uint8_t AMBE3000_VERSION[5] = {AMBE3000_START_BYTE, 0x00, 0x01, AMBE3000_TYPE_CONFIG, AMBE3000_PKT_VERSTRING};
static const uint8_t AMBE2020[5] = {0x05, 0x00, 0x18, 0x00, 0x01};

SerialAMBE::SerialAMBE(const std::string& protocol) : m_protocol(protocol) {}

SerialAMBE::~SerialAMBE() {
    disconnect();
}

bool SerialAMBE::connectToSerial(const std::string& port) {
    if (port.empty() || port == "None" || port == "Software vocoder")
        return false;

    int br = 460800;
    // TODO: detect DV Dongle via VID/PID for 230400 baud
    m_serial = new PosixSerial();
    if (!m_serial->open(port, br)) {
        fprintf(stderr, "Failed to open serial port %s\n", port.c_str());
        delete m_serial;
        m_serial = nullptr;
        return false;
    }

    m_description = port.substr(port.rfind('/') + 1);
    configAmbe();
    return true;
}

void SerialAMBE::disconnect() {
    if (m_serial) {
        m_serial->close();
        delete m_serial;
        m_serial = nullptr;
    }
    m_serialdata.clear();
}

void SerialAMBE::configAmbe() {
    std::vector<uint8_t> a;

    if (m_description != "DV Dongle") {
        // Disable parity
        a.insert(a.end(), AMBE3000_PARITY_DISABLE, AMBE3000_PARITY_DISABLE + sizeof(AMBE3000_PARITY_DISABLE));
        m_serial->write(a);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        a.clear();

        // Request prod ID
        a.insert(a.end(), AMBE3000_PRODID, AMBE3000_PRODID + sizeof(AMBE3000_PRODID));
        m_serial->write(a);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        a.clear();

        // Request version string
        a.insert(a.end(), AMBE3000_VERSION, AMBE3000_VERSION + sizeof(AMBE3000_VERSION));
        m_serial->write(a);
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        a.clear();
    }

    if (m_protocol == "DMR") {
        a.insert(a.end(), AMBE3000_2450_1150, AMBE3000_2450_1150 + sizeof(AMBE3000_2450_1150));
        m_packet_size = 9;
    } else if (m_protocol == "YSF" || m_protocol == "NXDN") {
        a.insert(a.end(), AMBE3000_2450_0000, AMBE3000_2450_0000 + sizeof(AMBE3000_2450_0000));
        m_packet_size = 7;
    } else if (m_protocol == "P25") {
        a.insert(a.end(), AMBEP251_4400_2800, AMBEP251_4400_2800 + sizeof(AMBEP251_4400_2800));
    } else if (m_description != "DV Dongle") {
        a.insert(a.end(), AMBE2000_2400_1200, AMBE2000_2400_1200 + sizeof(AMBE2000_2400_1200));
        m_packet_size = 9;
    } else {
        a.insert(a.end(), AMBE2020, AMBE2020 + sizeof(AMBE2020));
        m_packet_size = 9;
    }

    m_serial->write(a);

    if (on_ambedev_ready) on_ambedev_ready();
}

void SerialAMBE::poll() {
    if (!m_serial || !m_serial->isOpen()) return;

    uint8_t buf[1024];
    int n;
    while ((n = m_serial->read(buf, sizeof(buf))) > 0) {
        for (int i = 0; i < n; i++) {
            m_serialdata.push_back(buf[i]);
        }
        processSerial();
    }
}

void SerialAMBE::processSerial() {
    if (m_description == "DV Dongle") {
        processSerial2020();
    } else {
        processSerial3000();
    }
}

void SerialAMBE::decode(uint8_t *ambe) {
    if (m_description == "DV Dongle") {
        decode2020(ambe);
    } else {
        decode3000(ambe);
    }
}

void SerialAMBE::encode(int16_t *audio) {
    uint8_t packet[327] = {AMBE3000_START_BYTE, 0x01, 0x43, AMBE3000_TYPE_SPEECH, 0x40, 0x00, 0xa0};
    for (int i = 0; i < 160; ++i) {
        packet[(i*2)+7] = (audio[i] >> 8) & 0xff;
        packet[(i*2)+8] = audio[i] & 0xff;
    }
    m_serial->write(packet, 327);
}

void SerialAMBE::decode2020(uint8_t *ambe) {
    uint8_t packet[50] = {0x32, 0xa0, 0xec, 0x13, 0x00, 0x00, 0x30, 0x10, 0x01, 0x00, 0x00, 0x00, 0x30, 0x42, 0x48, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
    uint8_t pcm[322];
    memset(pcm, 0, 322);
    pcm[0] = 0x42;
    pcm[1] = 0x81;
    memcpy(packet+24, ambe, m_packet_size);
    m_serial->write(packet, 50);
    m_serial->write(pcm, 322);
}

void SerialAMBE::decode3000(uint8_t *ambe) {
    uint8_t packet[15] = {AMBE3000_START_BYTE, 0x00, 0x0b, AMBE3000_TYPE_CHANNEL, 0x01, 0x48};
    if (m_packet_size == 7) {
        packet[2] = 0x09;
        packet[5] = 0x31;
    }
    memcpy(packet+6, ambe, m_packet_size);
    m_serial->write(packet, (6 + m_packet_size));
}

void SerialAMBE::encode2020(int16_t *audio) {
    (void)audio;
}

void SerialAMBE::encode3000(int16_t *audio) {
    (void)audio;
}

void SerialAMBE::processSerial2020() {
    if (m_serialdata.size() > 321 &&
        m_serialdata[0] == 0x42 &&
        m_serialdata[1] == 0x81)
    {
        if (on_data_ready) on_data_ready();
    }
    if (m_serialdata.size() > 49 &&
        m_serialdata[0] == 0x32 &&
        m_serialdata[1] == 0xa0)
    {
        if (on_data_ready) on_data_ready();
    }
}

void SerialAMBE::processSerial3000() {
    if (m_serialdata.size() < 3) return;

    while (m_serialdata.size() > 3 &&
           m_serialdata[0] == AMBE3000_START_BYTE &&
           m_serialdata[3] == 0x00 &&
           m_serialdata.size() >= m_serialdata[2])
    {
        switch (m_serialdata[4]) {
        case AMBE3000_PKT_PARITYMODE:
            fprintf(stderr, "AMBE3000 Parity %s\n", m_serialdata[5] ? "NOT disabled" : "disabled");
            break;
        case AMBE3000_PKT_PRODID: {
            m_ambeprodid.clear();
            int len = m_serialdata[2] - 2;
            for (int i = 0; i < len; ++i)
                m_ambeprodid += (char)m_serialdata[5 + i];
            fprintf(stderr, "PRODID == %s\n", m_ambeprodid.c_str());
            break;
        }
        case AMBE3000_PKT_VERSTRING: {
            m_ambeverstring.clear();
            int len = m_serialdata[2] - 2;
            for (int i = 0; i < len; ++i)
                m_ambeverstring += (char)m_serialdata[5 + i];
            fprintf(stderr, "VERSTRING == %s\n", m_ambeverstring.c_str());
            break;
        }
        case AMBE3000_PKT_RATEP:
            if (on_connected)
                on_connected(m_serialdata[5] == 0);
            break;
        default:
            break;
        }

        int sz = m_serialdata[2];
        while (sz-- > 0 && !m_serialdata.empty())
            m_serialdata.pop_front();
        while (!m_serialdata.empty() && m_serialdata[0] != AMBE3000_START_BYTE)
            m_serialdata.pop_front();
    }

    if (m_serialdata.size() >= (6 + m_packet_size) &&
        m_serialdata[0] == AMBE3000_START_BYTE &&
        m_serialdata[3] == AMBE3000_TYPE_CHANNEL)
    {
        if (on_data_ready) on_data_ready();
    }
}

bool SerialAMBE::getAmbe(uint8_t *ambe) {
    if (m_serialdata.empty()) return false;

    if (m_serialdata.size() > 3 &&
        m_serialdata[0] == AMBE3000_START_BYTE &&
        m_serialdata[3] != AMBE3000_TYPE_CHANNEL)
    {
        while (!m_serialdata.empty() && m_serialdata[0] != AMBE3000_START_BYTE)
            m_serialdata.pop_front();
    }

    if (m_serialdata.size() >= (6 + m_packet_size) &&
        m_serialdata[0] == AMBE3000_START_BYTE &&
        m_serialdata[3] == AMBE3000_TYPE_CHANNEL)
    {
        for (int i = 0; i < 6; ++i)
            m_serialdata.pop_front();
        for (int i = 0; i < m_packet_size; i++) {
            ambe[i] = m_serialdata.front();
            m_serialdata.pop_front();
        }
        return true;
    }
    return false;
}

bool SerialAMBE::getAudio(int16_t *audio) {
    static const uint8_t header[] = {AMBE3000_START_BYTE, 0x01, 0x42, AMBE3000_TYPE_SPEECH, 0x00, 0xA0};

    if (m_serialdata.size() >= 326) {
        bool match = true;
        for (int i = 0; i < 6; i++) {
            if ((uint8_t)m_serialdata[i] != header[i]) {
                match = false;
                break;
            }
        }
        if (match) {
            for (int i = 0; i < 6; i++)
                m_serialdata.pop_front();
            for (int i = 0; i < 160; i++) {
                audio[i] = ((m_serialdata.front() << 8) & 0xff00) | (m_serialdata[1] & 0xff);
                m_serialdata.pop_front();
                m_serialdata.pop_front();
                audio[i] = (int16_t)((float)audio[i] * m_decode_gain);
            }
            return true;
        } else {
            while (m_serialdata.size() > 5 &&
                   ((uint8_t)m_serialdata[0] != header[0] ||
                    (uint8_t)m_serialdata[1] != header[1] ||
                    (uint8_t)m_serialdata[2] != header[2] ||
                    (uint8_t)m_serialdata[3] != header[3] ||
                    (uint8_t)m_serialdata[4] != header[4] ||
                    (uint8_t)m_serialdata[5] != header[5]))
            {
                m_serialdata.pop_front();
            }
        }
    }
    return false;
}

void SerialAMBE::clearQueue() {
    m_serialdata.clear();
}

std::vector<std::pair<std::string, std::string>> SerialAMBE::discoverDevices() {
    std::vector<std::pair<std::string, std::string>> devlist;
    auto ports = PosixSerial::availablePorts();
    for (const auto& p : ports) {
        devlist.push_back({p.path, p.description + ":" + p.path});
    }
    return devlist;
}
