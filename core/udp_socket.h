#ifndef UDP_SOCKET_H
#define UDP_SOCKET_H

#include <string>
#include <cstdint>
#include <cstddef>
#include <sys/socket.h>

class UdpSocket {
public:
    UdpSocket();
    ~UdpSocket();

    bool create(bool ipv6 = false);
    bool setNonBlocking(bool nb);
    bool connectTo(const std::string& host, uint16_t port);
    bool write(const uint8_t* data, size_t len);
    int read(uint8_t* buffer, size_t max_size);
    void close();
    bool isValid() const { return m_fd >= 0; }
    std::string lastError() const { return m_lastError; }

private:
    int m_fd = -1;
    uint16_t m_port = 0;
    std::string m_lastError;
    struct sockaddr_storage m_addr;
    bool m_ipv6 = false;
};

#endif
