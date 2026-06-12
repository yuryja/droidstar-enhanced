#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"
#include "audioengine.h"
#include <cmath>
#include <cstdio>
#include <algorithm>

AudioEngine::AudioEngine(const std::string& in, const std::string& out) :
    m_outputdevice(out),
    m_inputdevice(in)
{
    m_aout_max_buf_idx = 0;
    std::memset(m_aout_max_buf, 0, sizeof(m_aout_max_buf));
}

AudioEngine::~AudioEngine()
{
    stop_capture();
    stop_playback();
    if (m_captureDevice) {
        ma_device_uninit(m_captureDevice);
        delete m_captureDevice;
        m_captureDevice = nullptr;
    }
    if (m_playbackDevice) {
        ma_device_uninit(m_playbackDevice);
        delete m_playbackDevice;
        m_playbackDevice = nullptr;
    }
}

std::vector<std::string> AudioEngine::discover_audio_devices(uint8_t d)
{
    std::vector<std::string> list;
    ma_context context;
    if (ma_context_init(NULL, 0, NULL, &context) != MA_SUCCESS) {
        return list;
    }

    ma_device_info* pPlaybackInfos;
    ma_uint32 playbackCount;
    ma_device_info* pCaptureInfos;
    ma_uint32 captureCount;

    if (ma_context_get_devices(&context, &pPlaybackInfos, &playbackCount, &pCaptureInfos, &captureCount) != MA_SUCCESS) {
        ma_context_uninit(&context);
        return list;
    }

    if (d) {
        for (ma_uint32 i = 0; i < playbackCount; ++i) {
            list.push_back(pPlaybackInfos[i].name);
        }
    } else {
        for (ma_uint32 i = 0; i < captureCount; ++i) {
            list.push_back(pCaptureInfos[i].name);
        }
    }

    ma_context_uninit(&context);
    return list;
}

void AudioEngine::init()
{
    m_agc = true;

    ma_device_config playbackConfig = ma_device_config_init(ma_device_type_playback);
    playbackConfig.playback.format = ma_format_s16;
    playbackConfig.playback.channels = 1;
    playbackConfig.sampleRate = 8000;
    playbackConfig.dataCallback = playback_callback_data;
    playbackConfig.pUserData = this;
    if (!m_outputdevice.empty()) {
        playbackConfig.playback.pDeviceID = nullptr;
    }

    m_playbackDevice = new ma_device();
    if (ma_device_init(NULL, &playbackConfig, m_playbackDevice) != MA_SUCCESS) {
        std::fprintf(stderr, "AudioEngine: Failed to open playback device\n");
        delete m_playbackDevice;
        m_playbackDevice = nullptr;
    } else {
        ma_device_set_master_volume(m_playbackDevice, m_outputVolume);
        std::fprintf(stderr, "AudioEngine: Playback device initialized\n");
    }

    ma_device_config captureConfig = ma_device_config_init(ma_device_type_capture);
    captureConfig.capture.format = ma_format_s16;
    captureConfig.capture.channels = 1;
    captureConfig.sampleRate = 8000;
    captureConfig.dataCallback = capture_callback_data;
    captureConfig.pUserData = this;
    if (!m_inputdevice.empty()) {
        captureConfig.capture.pDeviceID = nullptr;
    }

    m_captureDevice = new ma_device();
    if (ma_device_init(NULL, &captureConfig, m_captureDevice) != MA_SUCCESS) {
        std::fprintf(stderr, "AudioEngine: Failed to open capture device\n");
        delete m_captureDevice;
        m_captureDevice = nullptr;
    } else {
        std::fprintf(stderr, "AudioEngine: Capture device initialized\n");
    }
}

void AudioEngine::start_capture()
{
    std::lock_guard<std::mutex> lock(m_captureMutex);
    m_captureq.clear();
    if (m_captureDevice) {
        ma_device_start(m_captureDevice);
    }
}

void AudioEngine::stop_capture()
{
    if (m_captureDevice) {
        ma_device_stop(m_captureDevice);
    }
}

void AudioEngine::start_playback()
{
    if (m_playbackDevice) {
        ma_device_start(m_playbackDevice);
    }
}

void AudioEngine::stop_playback()
{
    if (m_playbackDevice) {
        ma_device_stop(m_playbackDevice);
    }
}

void AudioEngine::write(const int16_t* pcm, size_t s)
{
    m_maxlevel = 0;

    if (s > 0) {
        int16_t* mutable_pcm = const_cast<int16_t*>(pcm);
        if (m_agc) {
            process_audio(mutable_pcm, s);
        }

        {
            std::lock_guard<std::mutex> lock(m_playbackMutex);
            for (size_t i = 0; i < s; ++i) {
                m_playbackq.push_back(mutable_pcm[i]);
                uint16_t abs_val = static_cast<uint16_t>(std::abs(mutable_pcm[i]));
                if (abs_val > m_maxlevel) {
                    m_maxlevel = abs_val;
                }
            }
        }
    }
}

uint16_t AudioEngine::read(int16_t* pcm, int s)
{
    uint16_t result = 0;
    m_maxlevel = 0;

    {
        std::lock_guard<std::mutex> lock(m_captureMutex);
        size_t available = m_captureq.size();
        size_t to_read = std::min(static_cast<size_t>(s), available);

        for (size_t i = 0; i < to_read; ++i) {
            pcm[i] = m_captureq.front();
            m_captureq.pop_front();
            uint16_t abs_val = static_cast<uint16_t>(std::abs(pcm[i]));
            if (abs_val > m_maxlevel) {
                m_maxlevel = abs_val;
            }
        }

        if (to_read < static_cast<size_t>(s)) {
            std::memset(pcm + to_read, 0, sizeof(int16_t) * (s - to_read));
        }

        result = (to_read > 0) ? 1 : 0;
    }

    return result;
}

uint16_t AudioEngine::read(int16_t* pcm)
{
    int s;
    m_maxlevel = 0;

    {
        std::lock_guard<std::mutex> lock(m_captureMutex);
        s = static_cast<int>(m_captureq.size());
        if (s > 160) s = 160;

        for (int i = 0; i < s; ++i) {
            pcm[i] = m_captureq.front();
            m_captureq.pop_front();
            uint16_t abs_val = static_cast<uint16_t>(std::abs(pcm[i]));
            if (abs_val > m_maxlevel) {
                m_maxlevel = abs_val;
            }
        }
    }

    return static_cast<uint16_t>(s);
}

void AudioEngine::playback_callback_data(ma_device* pDevice, void* pOutput, const void*, ma_uint32 frameCount)
{
    auto* engine = static_cast<AudioEngine*>(pDevice->pUserData);
    auto* out = static_cast<int16_t*>(pOutput);

    std::lock_guard<std::mutex> lock(engine->m_playbackMutex);
    size_t available = engine->m_playbackq.size();
    size_t to_copy = std::min(static_cast<size_t>(frameCount), available);

    for (size_t i = 0; i < to_copy; ++i) {
        out[i] = engine->m_playbackq.front();
        engine->m_playbackq.pop_front();
    }
    for (size_t i = to_copy; i < static_cast<size_t>(frameCount); ++i) {
        out[i] = 0;
    }
}

void AudioEngine::capture_callback_data(ma_device* pDevice, void*, const void* pInput, ma_uint32 frameCount)
{
    auto* engine = static_cast<AudioEngine*>(pDevice->pUserData);
    auto* in = static_cast<const int16_t*>(pInput);

    std::lock_guard<std::mutex> lock(engine->m_captureMutex);
    for (ma_uint32 i = 0; i < frameCount; ++i) {
        engine->m_captureq.push_back(in[i]);
    }
}

void AudioEngine::process_audio(int16_t* pcm, size_t s)
{
    float aout_abs, max, gainfactor, gaindelta, maxbuf;

    for (size_t i = 0; i < s; ++i) {
        m_audio_out_temp_buf[i] = static_cast<float>(pcm[i]);
    }

    max = 0;
    float* buf_p = m_audio_out_temp_buf;
    for (size_t i = 0; i < s; i++) {
        aout_abs = fabsf(*buf_p);
        if (aout_abs > max) max = aout_abs;
        buf_p++;
    }

    m_aout_max_buf[m_aout_max_buf_idx] = max;
    m_aout_max_buf_idx++;
    if (m_aout_max_buf_idx > 24) {
        m_aout_max_buf_idx = 0;
    }

    for (size_t i = 0; i < 25; i++) {
        maxbuf = m_aout_max_buf[i];
        if (maxbuf > max) max = maxbuf;
    }

    if (max > 0.0f) {
        gainfactor = (30000.0f / max);
    } else {
        gainfactor = 50.0f;
    }

    if (gainfactor < m_aout_gain) {
        m_aout_gain = gainfactor;
        gaindelta = 0.0f;
    } else {
        if (gainfactor > 50.0f) gainfactor = 50.0f;
        gaindelta = gainfactor - m_aout_gain;
        if (gaindelta > (0.05f * m_aout_gain)) {
            gaindelta = (0.05f * m_aout_gain);
        }
    }

    gaindelta /= static_cast<float>(s);

    buf_p = m_audio_out_temp_buf;
    for (size_t i = 0; i < s; i++) {
        *buf_p = (m_aout_gain + (static_cast<float>(i) * gaindelta)) * (*buf_p);
        buf_p++;
    }

    m_aout_gain += (static_cast<float>(s) * gaindelta);
    buf_p = m_audio_out_temp_buf;

    double vol = m_outputVolume.load();
    for (size_t i = 0; i < s; i++) {
        *buf_p *= static_cast<float>(vol);
        if (*buf_p > 32760.0f) *buf_p = 32760.0f;
        else if (*buf_p < -32760.0f) *buf_p = -32760.0f;
        pcm[i] = static_cast<int16_t>(*buf_p);
        buf_p++;
    }
}
