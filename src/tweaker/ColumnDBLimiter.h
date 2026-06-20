// SPDX-License-Identifier: GPL-3.0-only
/*
 * Copyright (C) 2022-present, PenUniverse.
 * This file is part of the PenMods open source project.
 */

#pragma once

#include "mod/Config.h"

namespace mod {

class ColumnDBLimiter : public QObject, public Singleton<ColumnDBLimiter> {
    Q_OBJECT

    Q_PROPERTY(bool patch READ getPatch WRITE setPatch NOTIFY patchChanged);
    Q_PROPERTY(int limit READ getLimit WRITE setLimit NOTIFY limitChanged)

public:
    [[nodiscard]] bool getPatch() const;

    void setPatch(bool);

    void setLimit(int);

    [[nodiscard]] int getLimit() const;

signals:

    void patchChanged();

    void limitChanged();

private:
    friend Singleton<ColumnDBLimiter>;
    explicit ColumnDBLimiter();

    std::string mClassName = "column_db";
    json        mCfg;

    bool mPatch;
    int  mLimit;
};

} // namespace mod
