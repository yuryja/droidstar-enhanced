#ifndef AUDIOENGINE_H
#define AUDIOENGINE_H

#include <string>
#include <vector>
#include <deque>
#include <mutex>
#include <cstdint>
#include <atomic>
#include <cstring>

struct ma_device;
struct ma_device_config;

#define AUDIO_OUT 1
#define AUDIO_IN  0

class AudioEngine
{
public:
    AudioEngine(const std::string& in, const std::string& out);
    ~AudioEngine();
    static std::vector<std::string> discover_audio_devices(uint8_t d);
    void init();
    void start_capture();
    void stop_capture();
    void start_playback();
    void stop_playback();
    void write(const int16_t*, size_t);
    uint16_t read(int16_t*, int);
    uint16_t read(int16_t*);
    void set_output_buffer_size(uint32_t b) { m_outputBufferSize = b; }
    void set_input_buffer_size(uint32_t b) { m_inputBufferSize = b; }
    void set_output_volume(double v) { m_outputVolume = v; }
    void set_input_volume(double v) { m_inputVolume = v; }
    void set_agc(bool agc) { m_agc = agc; }
    bool frame_available() const { std::lock_guard<std::mutex> lock(m_captureMutex); return m_captureq.size() >= 320; }
    uint16_t level() const { return m_maxlevel; }

private:
    static void playback_callback_data(ma_device* pDevice, void* pOutput, const void* pInput, uint32_t frameCount);
    static void capture_callback_data(ma_device* pDevice, void* pOutput, const void* pInput, uint32_t frameCount);

    std::string m_outputdevice;
    std::string m_inputdevice;

    ma_device* m_playbackDevice = nullptr;
    ma_device* m_captureDevice = nullptr;

    mutable std::mutex m_playbackMutex;
    std::deque<int16_t> m_playbackq;

    mutable std::mutex m_captureMutex;
    std::deque<int16_t> m_captureq;

    std::atomic<uint16_t> m_maxlevel{0};
    uint32_t m_outputBufferSize = 1280;
    uint32_t m_inputBufferSize = 640;
    std::atomic<double> m_outputVolume{1.0};
    std::atomic<double> m_inputVolume{1.0};
    bool m_agc = true;

    float m_aout_gain = 100.0f;
    float m_aout_max_buf[200]{};
    int m_aout_max_buf_idx = 0;
    float m_audio_out_temp_buf[320]{};

    void process_audio(int16_t* pcm, size_t s);
};

#endif
