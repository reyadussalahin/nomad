/*
 * frame.c
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

#include "../src/app.h"
#include "../src/window.h"
#include <libguile.h>

SCM_DEFINE_PUBLIC (scm_nomad_frame_new, "frame-new", 0, 0, 0, (),
                   "Creates a new frame. *warn* this should not be used")
{
  NomadAppWindow *win = nomad_app_window_new (nomad_app_get_default ());
  return scm_from_pointer (win, NULL);
}

void
nomad_frame_register_function (void *data)
{
#ifndef SCM_MAGIC_SNARFER
#include "frame.x"
#endif
}