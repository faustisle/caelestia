#include <fcntl.h>
#include <poll.h>
#include <sys/mman.h>
#include <sys/prctl.h>
#include <unistd.h>
#include <wayland-client.h>

#include <algorithm>
#include <cerrno>
#include <cmath>
#include <csignal>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

#include "wlr-gamma-control-unstable-v1-client-protocol.h"

namespace {

constexpr int kMinTemperature = 1000;
constexpr int kMaxTemperature = 20000;
constexpr int kNeutralTemperature = 6500;

struct Output {
    uint32_t globalName = 0;
    wl_output* output = nullptr;
    zwlr_gamma_control_v1* control = nullptr;
    uint32_t gammaSize = 0;
};

struct State {
    wl_display* display = nullptr;
    wl_registry* registry = nullptr;
    zwlr_gamma_control_manager_v1* manager = nullptr;
    std::vector<Output*> outputs;
    int temperature = kNeutralTemperature;
    bool identity = true;
    bool running = true;
};

State* g_state = nullptr;

void onSignal(int) {
    if (g_state)
        g_state->running = false;
}

double channelFactor(int channel, int temperature) {
    if (channel == 0)
        return 1.0;

    // Tanner Helland's blackbody approximation, normalised so red stays at 1.
    // This is intentionally simple; the output is a colour tint, not a
    // colorimetric transform.
    const double t = std::clamp(temperature, kMinTemperature, kMaxTemperature) / 100.0;
    double value = 0.0;

    if (channel == 1) {
        if (t <= 66.0)
            value = 99.4708025861 * std::log(t) - 161.1195681661;
        else
            value = 288.1221695283 * std::pow(t - 60.0, -0.0755148492);
    } else {
        if (t >= 66.0)
            value = 255.0;
        else if (t <= 19.0)
            value = 0.0;
        else
            value = 138.5177312231 * std::log(t - 10.0) - 305.0447927307;
    }

    return std::clamp(value / 255.0, 0.0, 1.0);
}

void setGamma(Output* output) {
    if (!output || !output->control || output->gammaSize < 2)
        return;

    const uint32_t size = output->gammaSize;
    const size_t bytes = static_cast<size_t>(size) * 3 * sizeof(uint16_t);
    const int fd = memfd_create("caelestia-nightlight", MFD_CLOEXEC);
    if (fd < 0)
        return;

    if (ftruncate(fd, static_cast<off_t>(bytes)) != 0) {
        close(fd);
        return;
    }

    void* data = mmap(nullptr, bytes, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
    if (data == MAP_FAILED) {
        close(fd);
        return;
    }

    auto* ramp = static_cast<uint16_t*>(data);
    const double r = g_state->identity ? 1.0 : channelFactor(0, g_state->temperature);
    const double g = g_state->identity ? 1.0 : channelFactor(1, g_state->temperature);
    const double b = g_state->identity ? 1.0 : channelFactor(2, g_state->temperature);
    const double denom = static_cast<double>(size - 1);

    for (uint32_t i = 0; i < size; ++i) {
        const double value = static_cast<double>(i) / denom * 65535.0;
        ramp[i] = static_cast<uint16_t>(std::clamp(value * r, 0.0, 65535.0));
        ramp[size + i] = static_cast<uint16_t>(std::clamp(value * g, 0.0, 65535.0));
        ramp[size * 2 + i] = static_cast<uint16_t>(std::clamp(value * b, 0.0, 65535.0));
    }

    munmap(data, bytes);
    zwlr_gamma_control_v1_set_gamma(output->control, fd);
    close(fd);
}

void applyAll() {
    for (Output* output : g_state->outputs)
        setGamma(output);
    wl_display_flush(g_state->display);
}

void onGammaSize(void* data, zwlr_gamma_control_v1*, uint32_t size) {
    auto* output = static_cast<Output*>(data);
    output->gammaSize = size;
    setGamma(output);
    wl_display_flush(g_state->display);
}

void onGammaFailed(void* data, zwlr_gamma_control_v1* control) {
    auto* output = static_cast<Output*>(data);
    output->gammaSize = 0;
    if (output->control == control)
        output->control = nullptr;
    zwlr_gamma_control_v1_destroy(control);
}

const zwlr_gamma_control_v1_listener gammaListener = {
    .gamma_size = onGammaSize,
    .failed = onGammaFailed,
};

void createControl(Output* output) {
    if (!g_state->manager || !output || output->control)
        return;

    output->control = zwlr_gamma_control_manager_v1_get_gamma_control(g_state->manager, output->output);
    zwlr_gamma_control_v1_add_listener(output->control, &gammaListener, output);
}

void onGlobal(void* data, wl_registry* registry, uint32_t name, const char* interface, uint32_t version) {
    (void)data;

    if (std::strcmp(interface, wl_output_interface.name) == 0) {
        auto* output = new Output;
        output->globalName = name;
        output->output =
            static_cast<wl_output*>(wl_registry_bind(registry, name, &wl_output_interface, std::min(version, 1u)));
        g_state->outputs.push_back(output);
        createControl(output);
        return;
    }

    if (std::strcmp(interface, zwlr_gamma_control_manager_v1_interface.name) == 0) {
        g_state->manager = static_cast<zwlr_gamma_control_manager_v1*>(
            wl_registry_bind(registry, name, &zwlr_gamma_control_manager_v1_interface, std::min(version, 1u)));
        for (Output* output : g_state->outputs)
            createControl(output);
    }
}

void onGlobalRemove(void* data, wl_registry*, uint32_t name) {
    (void)data;

    for (auto it = g_state->outputs.begin(); it != g_state->outputs.end(); ++it) {
        Output* output = *it;
        if (output->globalName != name)
            continue;

        if (output->control)
            zwlr_gamma_control_v1_destroy(output->control);
        if (output->output)
            wl_output_destroy(output->output);
        delete output;
        g_state->outputs.erase(it);
        return;
    }
}

const wl_registry_listener registryListener = {
    .global = onGlobal,
    .global_remove = onGlobalRemove,
};

void handleLine(std::string line) {
    while (!line.empty() && (line.back() == '\r' || line.back() == ' ' || line.back() == '\t'))
        line.pop_back();
    size_t start = 0;
    while (start < line.size() && (line[start] == ' ' || line[start] == '\t'))
        ++start;
    line.erase(0, start);

    if (line == "identity") {
        g_state->identity = true;
        applyAll();
        return;
    }

    if (line == "quit" || line == "exit") {
        g_state->running = false;
        return;
    }

    constexpr const char* prefix = "temperature ";
    if (line.rfind(prefix, 0) == 0) {
        char* end = nullptr;
        const long value = std::strtol(line.c_str() + std::strlen(prefix), &end, 10);
        if (!end || *end != '\0')
            return;

        const int temperature = static_cast<int>(std::clamp<long>(value, kMinTemperature, kMaxTemperature));
        g_state->temperature = temperature;
        g_state->identity = false;
        applyAll();
    }
}

void readStdin(std::string& buffer) {
    char chunk[256];
    for (;;) {
        const ssize_t n = read(STDIN_FILENO, chunk, sizeof(chunk));
        if (n > 0) {
            buffer.append(chunk, static_cast<size_t>(n));
            continue;
        }

        if (n == 0) {
            g_state->running = false;
            return;
        }

        if (errno == EAGAIN || errno == EWOULDBLOCK)
            return;

        if (errno == EINTR)
            continue;

        g_state->running = false;
        return;
    }
}

} // namespace

int main(int argc, char** argv) {
    // Make sure the filter is restored if the shell dies without a clean exit.
    prctl(PR_SET_PDEATHSIG, SIGTERM);
    if (getppid() == 1)
        return 0;

    int initialTemperature = kNeutralTemperature;
    bool initialIdentity = true;

    for (int i = 1; i < argc; ++i) {
        if ((std::strcmp(argv[i], "--temperature") == 0 || std::strcmp(argv[i], "-t") == 0) && i + 1 < argc) {
            initialTemperature = std::clamp(std::atoi(argv[++i]), kMinTemperature, kMaxTemperature);
            initialIdentity = false;
        } else if (std::strcmp(argv[i], "--identity") == 0 || std::strcmp(argv[i], "-i") == 0) {
            initialIdentity = true;
        }
    }

    State state;
    state.temperature = initialTemperature;
    state.identity = initialIdentity;
    g_state = &state;

    struct sigaction action = {};
    action.sa_handler = onSignal;
    sigemptyset(&action.sa_mask);
    sigaction(SIGINT, &action, nullptr);
    sigaction(SIGTERM, &action, nullptr);
    signal(SIGPIPE, SIG_IGN);

    state.display = wl_display_connect(nullptr);
    if (!state.display) {
        std::fprintf(stderr, "caelestia-nightlight: unable to connect to Wayland\n");
        return 1;
    }

    state.registry = wl_display_get_registry(state.display);
    wl_registry_add_listener(state.registry, &registryListener, nullptr);
    wl_display_roundtrip(state.display);

    if (!state.manager)
        std::fprintf(stderr, "caelestia-nightlight: compositor does not expose zwlr_gamma_control_v1\n");
    else
        wl_display_roundtrip(state.display);

    int flags = fcntl(STDIN_FILENO, F_GETFL, 0);
    if (flags >= 0)
        fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK);

    applyAll();
    std::printf("ready\n");
    std::fflush(stdout);

    std::string buffer;
    while (state.running) {
        wl_display_flush(state.display);

        pollfd fds[2] = {
            { wl_display_get_fd(state.display), POLLIN, 0 },
            { STDIN_FILENO, POLLIN, 0 },
        };

        const int result = poll(fds, 2, -1);
        if (result < 0) {
            if (errno == EINTR)
                continue;
            break;
        }

        if (fds[0].revents & POLLIN) {
            if (wl_display_dispatch(state.display) < 0)
                break;
        }

        if (fds[1].revents & (POLLIN | POLLHUP)) {
            readStdin(buffer);
            size_t pos;
            while ((pos = buffer.find('\n')) != std::string::npos) {
                const std::string line = buffer.substr(0, pos);
                buffer.erase(0, pos + 1);
                handleLine(line);
            }
        }
    }

    // Best-effort restore. The compositor also restores the ramp when the
    // gamma control object is destroyed.
    state.identity = true;
    applyAll();
    wl_display_roundtrip(state.display);

    for (Output* output : state.outputs) {
        if (output->control)
            zwlr_gamma_control_v1_destroy(output->control);
        if (output->output)
            wl_output_destroy(output->output);
        delete output;
    }
    state.outputs.clear();

    if (state.manager)
        zwlr_gamma_control_manager_v1_destroy(state.manager);
    if (state.registry)
        wl_registry_destroy(state.registry);
    if (state.display)
        wl_display_disconnect(state.display);

    return 0;
}
