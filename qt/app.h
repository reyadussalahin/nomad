/*
 * app.h
 * Copyright (C) 2017-2018 Michael Rosset <mike.rosset@gmail.com>
 *
 * This file is part of Nomad
 *
 * Nomad is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Nomad is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#ifndef APP_H
#define APP_H
#include "keymap.h"

extern QObject *root;
extern QObject *window;
extern Keymap keymap;

SCM qstring_to_scm (QString text);

QString scm_to_qstring(SCM text);

QString scm_to_human (SCM in);

void print_methods (QObject *object);

QVariant invoke_method(QObject*, const char*);
#endif // APP_H
