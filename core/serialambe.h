#ifndef SERIALAMBE_H
#define SERIALAMBE_H

#include <string>
#include <deque>
#include <functional>
#include <cstdint>
#include "posix_serial.h"

class SerialAMBE
{
public:
    SerialAMBE(const std::string& protocol);
    ~SerialAMBE();

    bool connectToSerial(const std::string& port);
    void disconnect();

    std::string getDescription() const { return m_description; }
    std::string getProdId() const { return m_ambeprodid; }
    std::string getVerString() const { return m_ambeverstring; }

    bool getAudio(int16_t *audio);
    bool getAmbe(uint8_t *ambe);
    void decode(uint8_t *ambe);
    void encode(int16_t *audio);
    void clearQueue();
    void setDecodeGain(float g) { m_decode_gain = g; }
    bool isConnected() const { return m_serial && m_serial->isOpen(); }

    // Poll for incoming serial data (call from run_loop)
    void poll();

    std::function<void(bool)> on_connected;
    std::function<void()> on_data_ready;
    std::function<void()> on_ambedev_ready;

    static std::vector<std::pair<std::string, std::string>> discoverDevices();

private:
    PosixSerial *m_serial = nullptr;
    std::string m_description;
    std::string m_protocol;
    std::string m_ambeverstring;
    std::string m_ambeprodid;
    uint8_t m_packet_size = 0;
    float m_decode_gain = 1.0f;
    std::deque<uint8_t> m_serialdata;

    void configAmbe();
    void processSerial();
    void decode2020(uint8_t *);
    void encode2020(int16_t *);
    void decode3000(uint8_t *);
    void encode3000(int16_t *);
    void processSerial2020();
    void processSerial3000();
};

#endif // SERIALAMBE_H
