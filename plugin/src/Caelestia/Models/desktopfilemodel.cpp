#include "desktopfilemodel.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qstring.h>

#include <algorithm>
#include <utility>

namespace caelestia::shell::models {

using Qt::StringLiterals::operator""_s;
using Qt::StringLiterals::operator""_ba;

namespace {

QString unescapeValue(QString value) {
    QString out;
    out.reserve(value.size());

    for (qsizetype i = 0; i < value.size(); ++i) {
        const QChar c = value.at(i);
        if (c != u'\\' || i + 1 >= value.size()) {
            out += c;
            continue;
        }

        const QChar next = value.at(++i);
        switch (next.unicode()) {
        case u's':
            out += u' ';
            break;
        case u'n':
            out += u'\n';
            break;
        case u't':
            out += u'\t';
            break;
        case u'r':
            out += u'\r';
            break;
        default:
            out += next;
            break;
        }
    }

    return out;
}

// Exec is not a shell command, but it does have its own quoting and field codes.
QStringList parseCommand(const QString& exec) {
    QStringList args;
    QString current;
    bool quoted = false;
    bool started = false;

    for (qsizetype i = 0; i < exec.size(); ++i) {
        const QChar c = exec.at(i);

        if (c == u'\\' && i + 1 < exec.size()) {
            current += exec.at(++i);
            started = true;
            continue;
        }

        if (c == u'"') {
            quoted = !quoted;
            started = true;
            continue;
        }

        if (c.isSpace() && !quoted) {
            if (started) {
                args << current;
                current.clear();
                started = false;
            }
            continue;
        }

        if (c == u'%' && i + 1 < exec.size()) {
            const QChar code = exec.at(++i);
            if (code == u'%') {
                current += u'%';
                started = true;
            } else if (QStringLiteral("fFuUdDnNickvm").contains(code)) {
                // A field code expands to a file, uri, name, icon or similar. None
                // of them have anything to contribute when launching from an icon.
            } else {
                current += c;
                started = true;
            }
            continue;
        }

        current += c;
        started = true;
    }

    if (started) {
        args << current;
    }

    return args;
}

} // namespace

DesktopFile::DesktopFile(QString path, QString id, QString name, QString comment, QString icon, QStringList command,
    QString workingDirectory, bool terminal, QObject* parent)
    : QObject(parent)
    , m_path(std::move(path))
    , m_id(std::move(id))
    , m_name(std::move(name))
    , m_comment(std::move(comment))
    , m_icon(std::move(icon))
    , m_command(std::move(command))
    , m_workingDirectory(std::move(workingDirectory))
    , m_terminal(terminal) {}

QString DesktopFile::path() const {
    return m_path;
}

QString DesktopFile::id() const {
    return m_id;
}

QString DesktopFile::name() const {
    return m_name;
}

QString DesktopFile::comment() const {
    return m_comment;
}

QString DesktopFile::icon() const {
    return m_icon;
}

QStringList DesktopFile::command() const {
    return m_command;
}

QString DesktopFile::workingDirectory() const {
    return m_workingDirectory;
}

bool DesktopFile::terminal() const {
    return m_terminal;
}

DesktopFileModel::DesktopFileModel(QObject* parent)
    : QAbstractListModel(parent)
    , m_watchChanges(true)
    , m_reloadTimer(new QTimer(this)) {
    m_reloadTimer->setSingleShot(true);
    m_reloadTimer->setInterval(150);

    connect(m_reloadTimer, &QTimer::timeout, this, &DesktopFileModel::reload);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, [this] {
        m_reloadTimer->start();
    });
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this] {
        m_reloadTimer->start();
    });
}

int DesktopFileModel::rowCount(const QModelIndex& parent) const {
    if (parent != QModelIndex()) {
        return 0;
    }
    return static_cast<int>(m_entries.size());
}

QVariant DesktopFileModel::data(const QModelIndex& index, int role) const {
    if (role != Qt::UserRole || !index.isValid() || index.row() >= m_entries.size()) {
        return {};
    }
    return QVariant::fromValue(m_entries.at(index.row()));
}

QHash<int, QByteArray> DesktopFileModel::roleNames() const {
    return { { Qt::UserRole, "modelData"_ba } };
}

QString DesktopFileModel::path() const {
    return m_path;
}

void DesktopFileModel::setPath(const QString& path) {
    if (m_path == path) {
        return;
    }

    m_path = path;
    emit pathChanged();
    reload();
}

bool DesktopFileModel::watchChanges() const {
    return m_watchChanges;
}

void DesktopFileModel::setWatchChanges(bool watchChanges) {
    if (m_watchChanges == watchChanges) {
        return;
    }

    m_watchChanges = watchChanges;
    emit watchChangesChanged();
    updateWatcher();
}

QQmlListProperty<DesktopFile> DesktopFileModel::entries() {
    return { this, &m_entries };
}

void DesktopFileModel::reload() {
    QList<DesktopFile*> found;

    if (!m_path.isEmpty()) {
        const QDir dir(m_path);
        const auto files = dir.entryInfoList({ u"*.desktop"_s }, QDir::Files | QDir::Readable, QDir::NoSort);

        for (const auto& info : files) {
            QFile file(info.filePath());
            if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
                continue;
            }

            QString name;
            QString comment;
            QString icon;
            QString exec;
            QString workingDirectory;
            QString type;
            bool terminal = false;
            bool hidden = false;

            const auto lines = QString::fromUtf8(file.readAll()).split(u'\n');
            bool inEntry = false;
            for (const auto& rawLine : lines) {
                const auto line = rawLine.trimmed();
                if (line.isEmpty() || line.startsWith(u'#')) {
                    continue;
                }

                if (line.startsWith(u'[') && line.endsWith(u']')) {
                    inEntry = line == u"[Desktop Entry]"_s;
                    continue;
                }

                if (!inEntry) {
                    continue;
                }

                const auto separator = line.indexOf(u'=');
                if (separator <= 0) {
                    continue;
                }

                const auto key = line.left(separator);
                if (key.contains(u'[')) {
                    // A localised value; the plain key is the fallback.
                    continue;
                }

                const auto value = unescapeValue(line.mid(separator + 1).trimmed());
                if (key == u"Name"_s) {
                    name = value;
                } else if (key == u"Comment"_s) {
                    comment = value;
                } else if (key == u"Icon"_s) {
                    icon = value;
                } else if (key == u"Exec"_s) {
                    exec = value;
                } else if (key == u"Path"_s) {
                    workingDirectory = value;
                } else if (key == u"Type"_s) {
                    type = value;
                } else if (key == u"Terminal"_s) {
                    terminal = value.compare(u"true"_s, Qt::CaseInsensitive) == 0;
                } else if (key == u"Hidden"_s || key == u"NoDisplay"_s) {
                    hidden = hidden || value.compare(u"true"_s, Qt::CaseInsensitive) == 0;
                }
            }

            if (hidden || (!type.isEmpty() && type != u"Application"_s)) {
                continue;
            }

            auto command = parseCommand(exec);
            if (command.isEmpty()) {
                continue;
            }

            if (name.isEmpty()) {
                name = info.completeBaseName();
            }

            found << new DesktopFile(info.filePath(), info.completeBaseName(), name, comment, icon, std::move(command),
                workingDirectory, terminal, this);
        }
    }

    std::sort(found.begin(), found.end(), [](const DesktopFile* a, const DesktopFile* b) {
        const auto byName = QString::compare(a->name(), b->name(), Qt::CaseInsensitive);
        if (byName != 0) {
            return byName < 0;
        }
        return QString::compare(a->id(), b->id(), Qt::CaseInsensitive) < 0;
    });

    const auto old = m_entries;
    beginResetModel();
    m_entries = found;
    endResetModel();

    // Delegates hold the old entries until the reset has propagated.
    for (auto* entry : old) {
        entry->deleteLater();
    }

    emit entriesChanged();
    updateWatcher();
}

void DesktopFileModel::updateWatcher() {
    const auto watchedDirs = m_watcher.directories();
    if (!watchedDirs.isEmpty()) {
        m_watcher.removePaths(watchedDirs);
    }

    const auto watchedFiles = m_watcher.files();
    if (!watchedFiles.isEmpty()) {
        m_watcher.removePaths(watchedFiles);
    }

    if (!m_watchChanges || m_path.isEmpty()) {
        return;
    }

    if (QFileInfo::exists(m_path)) {
        m_watcher.addPath(m_path);
    }

    for (const auto* entry : m_entries) {
        if (QFileInfo::exists(entry->path())) {
            m_watcher.addPath(entry->path());
        }
    }
}

} // namespace caelestia::shell::models
