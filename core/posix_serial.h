#ifndef POSIX_SERIAL_H
#define POSIX_SERIAL_H

#include <string>
#include <vector>
#include <map>
#include <cstdint>
#include <functional>

class PosixSerial {
public:
    struct PortInfo {
        std::string path;
        std::string description;
        std::string manufacturer;
        std::string serial;
        uint16_t vid = 0;
        uint16_t pid = 0;
    };

    PosixSerial();
    ~PosixSerial();

    bool open(const std::string& port, int baudrate);
    void close();
    bool isOpen() const { return m_fd >= 0; }

    int read(uint8_t* buf, int size);
    int write(const uint8_t* data, int size);
    int write(const std::vector<uint8_t>& data);
    int write(const std::string& data);

    // Non-blocking poll: returns bytes available, 0 if none, -1 on error
    int available();

    // Blocking read with timeout (ms)
    int readTimeout(uint8_t* buf, int size, int timeout_ms);

    static std::vector<PortInfo> availablePorts();

private:
    int m_fd = -1;
    int m_baudrate = 0;

    bool configureTermios(int baudrate);
    static int baudToSpeed(int baudrate);
};

#endif // POSIX_SERIAL_H
