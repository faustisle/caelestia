#include "tickingservice.hpp"

#include "config/rootnodes.hpp"
#include "config/serviceconfig.hpp"

namespace caelestia::shell::services {

TickingService::TickingService(QObject* parent)
    : Service(parent)
    , m_timer(new QTimer(this)) {
    m_timer->setSingleShot(false);
    QObject::connect(m_timer, &QTimer::timeout, this, [this] {
        tick();
    });

    const auto* services = caelestia::shell::config::ConfigSingleton::instance()->services();
    applyInterval(services->resourceUpdateInterval());
    QObject::connect(
        services, &caelestia::shell::config::ServiceConfig::resourceUpdateIntervalChanged, this, [this, services] {
            applyInterval(services->resourceUpdateInterval());
        });
}

int TickingService::updateInterval() const {
    return m_interval;
}

void TickingService::start() {
    m_running = true;
    if (m_interval > 0) {
        m_timer->start(m_interval);
    }
    tick();
}

void TickingService::stop() {
    m_running = false;
    m_timer->stop();
}

void TickingService::applyInterval(int ms) {
    if (ms <= 0 || ms == m_interval) {
        return;
    }
    m_interval = ms;
    if (m_running) {
        m_timer->start(m_interval);
    }
    emit updateIntervalChanged();
}

} // namespace caelestia::shell::services
