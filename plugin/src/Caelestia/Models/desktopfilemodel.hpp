#pragma once

#include <qabstractitemmodel.h>
#include <qfilesystemwatcher.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qqmllist.h>
#include <qtimer.h>

namespace caelestia::shell::models {

class DesktopFile : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("DesktopFile instances can only be retrieved from a DesktopFileModel")

    Q_PROPERTY(QString path READ path CONSTANT)
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString comment READ comment CONSTANT)
    Q_PROPERTY(QString icon READ icon CONSTANT)
    // "application", "folder" or "file"
    Q_PROPERTY(QString kind READ kind CONSTANT)
    Q_PROPERTY(QStringList command READ command CONSTANT)
    Q_PROPERTY(QString workingDirectory READ workingDirectory CONSTANT)
    Q_PROPERTY(bool terminal READ terminal CONSTANT)

public:
    explicit DesktopFile(QString path, QString id, QString name, QString comment, QString icon, QString kind,
        QStringList command, QString workingDirectory, bool terminal, QObject* parent = nullptr);

    [[nodiscard]] QString path() const;
    [[nodiscard]] QString id() const;
    [[nodiscard]] QString name() const;
    [[nodiscard]] QString comment() const;
    [[nodiscard]] QString icon() const;
    [[nodiscard]] QString kind() const;
    [[nodiscard]] QStringList command() const;
    [[nodiscard]] QString workingDirectory() const;
    [[nodiscard]] bool terminal() const;

private:
    const QString m_path;
    const QString m_id;
    const QString m_name;
    const QString m_comment;
    const QString m_icon;
    const QString m_kind;
    const QStringList m_command;
    const QString m_workingDirectory;
    const bool m_terminal;
};

class DesktopFileModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString path READ path WRITE setPath NOTIFY pathChanged)
    Q_PROPERTY(bool watchChanges READ watchChanges WRITE setWatchChanges NOTIFY watchChangesChanged)
    // When false, only application shortcuts (.desktop files) are listed.
    Q_PROPERTY(bool showFiles READ showFiles WRITE setShowFiles NOTIFY showFilesChanged)
    Q_PROPERTY(QQmlListProperty<caelestia::shell::models::DesktopFile> entries READ entries NOTIFY entriesChanged)

public:
    explicit DesktopFileModel(QObject* parent = nullptr);

    [[nodiscard]] int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    [[nodiscard]] QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

    [[nodiscard]] QString path() const;
    void setPath(const QString& path);

    [[nodiscard]] bool watchChanges() const;
    void setWatchChanges(bool watchChanges);

    [[nodiscard]] bool showFiles() const;
    void setShowFiles(bool showFiles);

    [[nodiscard]] QQmlListProperty<DesktopFile> entries();

signals:
    void pathChanged();
    void watchChangesChanged();
    void showFilesChanged();
    void entriesChanged();

private:
    QString m_path;
    bool m_watchChanges;
    bool m_showFiles;
    QFileSystemWatcher m_watcher;
    QTimer* m_reloadTimer;
    QList<DesktopFile*> m_entries;

    void reload();
    void updateWatcher();
};

} // namespace caelestia::shell::models
