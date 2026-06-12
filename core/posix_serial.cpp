#include "posix_serial.h"
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <sys/select.h>
#include <glob.h>
#include <cstring>
#include <cerrno>
#include <cstdio>

#ifndef B460800
#define B460800 460800
#endif
#ifndef B921600
#define B921600 921600
#endif

PosixSerial::PosixSerial() {}

PosixSerial::~PosixSerial() {
    close();
}

int PosixSerial::baudToSpeed(int baudrate) {
    switch (baudrate) {
        case 1200: return B1200;
        case 2400: return B2400;
        case 4800: return B4800;
        case 9600: return B9600;
        case 19200: return B19200;
        case 38400: return B38400;
        case 57600: return B57600;
        case 115200: return B115200;
        case 230400: return B230400;
        case 460800: return B460800;
        case 921600: return B921600;
        default: return B9600;
    }
}

bool PosixSerial::configureTermios(int baudrate) {
    struct termios tty;
    if (tcgetattr(m_fd, &tty) != 0) {
        perror("tcgetattr");
        return false;
    }

    speed_t speed = baudToSpeed(baudrate);
    cfsetospeed(&tty, speed);
    cfsetispeed(&tty, speed);

    tty.c_cflag &= ~PARENB;   // No parity
    tty.c_cflag &= ~CSTOPB;   // 1 stop bit
    tty.c_cflag &= ~CSIZE;
    tty.c_cflag |= CS8;       // 8 data bits
    tty.c_cflag &= ~CRTSCTS;  // No hardware flow control (default)

    tty.c_cflag |= (CLOCAL | CREAD); // Enable receiver, ignore modem control lines

    tty.c_iflag &= ~(IXON | IXOFF | IXANY); // No software flow control
    tty.c_iflag &= ~(IGNBRK | BRKINT | PARMRK | ISTRIP | INLCR | IGNCR | ICRNL);

    tty.c_oflag &= ~OPOST; // Raw output
    tty.c_lflag &= ~(ECHO | ECHONL | ICANON | ISIG | IEXTEN); // Raw input

    tty.c_cc[VMIN] = 0;  // Non-blocking read
    tty.c_cc[VTIME] = 0; // No timeout

    if (tcsetattr(m_fd, TCSANOW, &tty) != 0) {
        perror("tcsetattr");
        return false;
    }
    return true;
}

bool PosixSerial::open(const std::string& port, int baudrate) {
    close();
    m_fd = ::open(port.c_str(), O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (m_fd < 0) {
        perror(("Failed to open " + port).c_str());
        return false;
    }

    if (!configureTermios(baudrate)) {
        ::close(m_fd);
        m_fd = -1;
        return false;
    }

    m_baudrate = baudrate;
    return true;
}

void PosixSerial::close() {
    if (m_fd >= 0) {
        ::close(m_fd);
        m_fd = -1;
        m_baudrate = 0;
    }
}

int PosixSerial::read(uint8_t* buf, int size) {
    if (m_fd < 0) return -1;
    int n = (int)::read(m_fd, buf, size);
    if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
        return 0;
    }
    return n;
}

int PosixSerial::write(const uint8_t* data, int size) {
    if (m_fd < 0) return -1;
    int n = (int)::write(m_fd, data, size);
    if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) {
        return 0;
    }
    return n;
}

int PosixSerial::write(const std::vector<uint8_t>& data) {
    return write(data.data(), (int)data.size());
}

int PosixSerial::write(const std::string& data) {
    return write((const uint8_t*)data.data(), (int)data.size());
}

int PosixSerial::available() {
    if (m_fd < 0) return -1;
    fd_set read_fds;
    FD_ZERO(&read_fds);
    FD_SET(m_fd, &read_fds);
    struct timeval tv = {0, 0};
    int ret = select(m_fd + 1, &read_fds, nullptr, nullptr, &tv);
    if (ret < 0) return -1;
    return ret; // 0 = none, 1 = data available
}

int PosixSerial::readTimeout(uint8_t* buf, int size, int timeout_ms) {
    if (m_fd < 0) return -1;
    fd_set read_fds;
    FD_ZERO(&read_fds);
    FD_SET(m_fd, &read_fds);
    struct timeval tv;
    tv.tv_sec = timeout_ms / 1000;
    tv.tv_usec = (timeout_ms % 1000) * 1000;
    int ret = select(m_fd + 1, &read_fds, nullptr, nullptr, &tv);
    if (ret < 0) return -1;
    if (ret == 0) return 0;
    return (int)::read(m_fd, buf, size);
}

std::vector<PosixSerial::PortInfo> PosixSerial::availablePorts() {
    std::vector<PortInfo> ports;

    const char* patterns[] = {"/dev/cu.*", "/dev/tty.*"};
    for (const char* pattern : patterns) {
        glob_t globbuf;
        int ret = glob(pattern, GLOB_NOSORT, nullptr, &globbuf);
        if (ret == 0) {
            for (size_t i = 0; i < globbuf.gl_pathc; i++) {
                const char* path = globbuf.gl_pathv[i];
                std::string p(path);
                if (p.find("Bluetooth") != std::string::npos)
                    continue;
                PortInfo info;
                info.path = p;
                info.description = p.substr(p.rfind('/') + 1);
                ports.push_back(info);
            }
        }
        globfree(&globbuf);
    }
    return ports;
}
