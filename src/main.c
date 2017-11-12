/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 4; tab-width: 4 -*-  */
/*
 * main.c 
 * Copyright (C) 2017 Mike Rosset <mike.rosset@gmail.com>
 * 
 * wemacs is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * wemacs is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#include <libguile.h>
#include <gtk/gtk.h>

#include "wemacsapp.h"
#include "scheme.h"

int
main (int argc, char *argv[])
{
  scm_with_guile (&register_functions, NULL);
  scm_shell (argc, argv);
 //return g_application_run (G_APPLICATION (wemacs_app_new ()), argc, argv);
  
}
