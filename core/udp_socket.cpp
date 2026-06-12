#include "udp_socket.h"
#include <sys/socket.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#include <fcntl.h>
#include <cstring>
#include <cerrno>

UdpSocket::UdpSocket() = default;

UdpSocket::~UdpSocket() { close(); }

bool UdpSocket::create(bool ipv6) {
    m_ipv6 = ipv6;
    m_fd = socket(ipv6 ? AF_INET6 : AF_INET, SOCK_DGRAM, 0);
    if (m_fd < 0) {
        m_lastError = "socket() failed: " + std::string(strerror(errno));
        return false;
    }
    return true;
}

bool UdpSocket::setNonBlocking(bool nb) {
    if (m_fd < 0) {
        m_lastError = "Socket not created";
        return false;
    }
    int flags = fcntl(m_fd, F_GETFL, 0);
    if (flags < 0) {
        m_lastError = "fcntl(F_GETFL) failed: " + std::string(strerror(errno));
        return false;
    }
    if (nb)
        flags |= O_NONBLOCK;
    else
        flags &= ~O_NONBLOCK;
    if (fcntl(m_fd, F_SETFL, flags) < 0) {
        m_lastError = "fcntl(F_SETFL) failed: " + std::string(strerror(errno));
        return false;
    }
    return true;
}

bool UdpSocket::connectTo(const std::string& host, uint16_t port) {
    if (m_fd < 0) {
        m_lastError = "Socket not created";
        return false;
    }

    m_port = port;
    std::memset(&m_addr, 0, sizeof(m_addr));

    if (m_ipv6) {
        auto* addr6 = reinterpret_cast<struct sockaddr_in6*>(&m_addr);
        addr6->sin6_family = AF_INET6;
        addr6->sin6_port = htons(port);

        if (inet_pton(AF_INET6, host.c_str(), &addr6->sin6_addr) == 1)
            return true;

        struct addrinfo hints, *res = nullptr;
        std::memset(&hints, 0, sizeof(hints));
        hints.ai_family = AF_INET6;
        hints.ai_socktype = SOCK_DGRAM;

        if (getaddrinfo(host.c_str(), nullptr, &hints, &res) == 0 && res) {
            std::memcpy(&addr6->sin6_addr,
                &reinterpret_cast<struct sockaddr_in6*>(res->ai_addr)->sin6_addr,
                sizeof(addr6->sin6_addr));
            freeaddrinfo(res);
            return true;
        }
    } else {
        auto* addr4 = reinterpret_cast<struct sockaddr_in*>(&m_addr);
        addr4->sin_family = AF_INET;
        addr4->sin_port = htons(port);

        if (inet_pton(AF_INET, host.c_str(), &addr4->sin_addr) == 1)
            return true;

        struct addrinfo hints, *res = nullptr;
        std::memset(&hints, 0, sizeof(hints));
        hints.ai_family = AF_INET;
        hints.ai_socktype = SOCK_DGRAM;

        if (getaddrinfo(host.c_str(), nullptr, &hints, &res) == 0 && res) {
            std::memcpy(&addr4->sin_addr,
                &reinterpret_cast<struct sockaddr_in*>(res->ai_addr)->sin_addr,
                sizeof(addr4->sin_addr));
            freeaddrinfo(res);
            return true;
        }
    }

    m_lastError = "Failed to resolve: " + host;
    return false;
}

bool UdpSocket::write(const uint8_t* data, size_t len) {
    if (m_fd < 0) {
        m_lastError = "Socket not created";
        return false;
    }

    socklen_t addrLen = m_ipv6 ? sizeof(struct sockaddr_in6) : sizeof(struct sockaddr_in);
    int ret = sendto(m_fd, data, len, 0,
                     reinterpret_cast<struct sockaddr*>(&m_addr), addrLen);
    if (ret < 0) {
        m_lastError = "sendto() failed: " + std::string(strerror(errno));
        return false;
    }
    return true;
}

int UdpSocket::read(uint8_t* buffer, size_t max_size) {
    if (m_fd < 0) {
        m_lastError = "Socket not created";
        return -1;
    }

    socklen_t addrLen = m_ipv6 ? sizeof(struct sockaddr_in6) : sizeof(struct sockaddr_in);
    struct sockaddr_storage from;
    int ret = recvfrom(m_fd, buffer, max_size, 0,
                       reinterpret_cast<struct sockaddr*>(&from), &addrLen);
    if (ret < 0) {
        if (errno == EWOULDBLOCK || errno == EAGAIN)
            return 0;
        m_lastError = "recvfrom() failed: " + std::string(strerror(errno));
        return -1;
    }
    return ret;
}

void UdpSocket::close() {
    if (m_fd >= 0) {
        ::close(m_fd);
        m_fd = -1;
    }
}
