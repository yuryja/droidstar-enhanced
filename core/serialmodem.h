#ifndef SERIALMODEM_H
#define SERIALMODEM_H

#include <string>
#include <deque>
#include <functional>
#include <cstdint>
#include <vector>
#include <QByteArray>
#include "posix_serial.h"

class SerialModem
{
public:
    SerialModem(const std::string& mode);
    ~SerialModem();

    void setMode(const std::string& m);
    void setModemFlags(bool rxInvert, bool txInvert, bool pttInvert, bool useCOSAsLockout, bool duplex);
    void setModemParams(uint32_t baudrate, uint32_t rxfreq, uint32_t txfreq, uint32_t txDelay,
                        float rxLevel, float rfLevel, uint32_t ysfTXHang,
                        float cwIdTXLevel, float dstarTXLevel, float dmrTXLevel,
                        float ysfTXLevel, float p25TXLevel, float nxdnTXLevel,
                        float pocsagTXLevel, float m17TXLevel);
    bool connectToSerial(const std::string& port);
    void disconnect();
    std::string getVersion() const { return m_version; }
    void write(const std::vector<uint8_t>& data);
    void write(const QByteArray& data);
    void setCC(uint32_t cc) { m_dmrColorCode = cc; }
    void setMode(uint8_t m);
    bool isConnected() const { return m_serial && m_serial->isOpen(); }

    // Poll for incoming serial data (call from run_loop)
    void poll();

    std::function<void()> on_data_ready;
    std::function<void(std::vector<uint8_t>)> on_modem_data_ready;
    std::function<void(bool)> on_connected;
    std::function<void()> on_modem_ready;

    static std::vector<std::pair<std::string, std::string>> discoverDevices();

private:
    PosixSerial *m_serial = nullptr;
    std::string m_version;
    uint8_t m_protocol = 0;
    uint8_t m_configured = 0;
    uint32_t m_baudrate = 0;
    uint8_t m_packet_size = 0;
    std::deque<uint8_t> m_serialdata;
    uint32_t m_rxfreq = 0;
    uint32_t m_txfreq = 0;
    uint32_t m_dmrColorCode = 1;
    bool m_ysfLoDev = false;
    uint32_t m_ysfTXHang = 0;
    uint32_t m_p25TXHang = 0;
    uint32_t m_nxdnTXHang = 0;
    uint32_t m_m17TXHang = 5;
    bool m_duplex = false;
    bool m_rxInvert = false;
    bool m_txInvert = false;
    bool m_pttInvert = false;
    uint32_t m_txDelay = 0;
    uint32_t m_dmrDelay = 0;
    float m_rxLevel = 0;
    float m_rfLevel = 0;
    float m_cwIdTXLevel = 0;
    float m_dstarTXLevel = 0;
    float m_dmrTXLevel = 0;
    float m_ysfTXLevel = 0;
    float m_p25TXLevel = 0;
    float m_nxdnTXLevel = 0;
    float m_pocsagTXLevel = 0;
    float m_m17TXLevel = 0;
    float m_fmTXLevel = 0;
    float m_ax25TXLevel = 0;
    int m_ax25RXTwist = 0;
    uint32_t m_ax25TXDelay = 0;
    uint32_t m_ax25SlotTime = 0;
    uint32_t m_ax25PPersist = 0;
    bool m_debug = false;
    bool m_useCOSAsLockout = false;
    bool m_dstarEnabled = false;
    bool m_dmrEnabled = false;
    bool m_ysfEnabled = false;
    bool m_p25Enabled = false;
    bool m_nxdnEnabled = false;
    bool m_pocsagEnabled = false;
    bool m_ax25Enabled = false;
    bool m_m17Enabled = false;
    bool m_fmEnabled = false;
    int m_rxDCOffset = 0;
    int m_txDCOffset = 0;

    void processSerial();
    void processModem();
    void getStatusModem();
    void setFreq();
    void setConfig();
    void configModem();
};

#endif // SERIALMODEM_H
