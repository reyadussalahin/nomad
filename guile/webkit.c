/*
 * webkit.c
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
#include "request.h"
#include <libguile.h>
#include <webkit2/webkit2.h>

SCM_DEFINE_PUBLIC (scm_nomad_webkit_new, "webkit-new", 0, 0, 0, (SCM pointer),
                   "Returns a newly initialized webkit view")
{
  GtkWidget *view = webkit_web_view_new ();
  return scm_from_pointer (view, NULL);
}

SCM_DEFINE_PUBLIC (scm_nomad_webkit_uri, "webkit-uri", 1, 0, 0, (SCM pointer),
                   "Returns the current uri for a webkit view pointer. If "
                   "webview has not uri it returns #f")
{
  GtkWidget *view = (GtkWidget *)scm_to_pointer (pointer);
  const char *uri = webkit_web_view_get_uri (WEBKIT_WEB_VIEW (view));
  if (uri)
    {
      return scm_from_locale_string (uri);
    }
  return scm_from_utf8_string ("NULL");
}

SCM_DEFINE_PUBLIC (scm_nomad_webkit_load_uri, "webkit-load-uri", 2, 0, 0,
                   (SCM pointer, SCM uri),
                   "Requests webkit VIEW pointer to load URI")
{
  GtkWidget *view = (GtkWidget *)scm_to_pointer (pointer);
  char *c_uri = scm_to_locale_string (uri);
  webkit_web_view_load_uri (WEBKIT_WEB_VIEW (view), c_uri);
  g_free (c_uri);
  return SCM_UNSPECIFIED;
}

SCM_DEFINE_PUBLIC (scm_nomad_webkit_load_html, "webkit-load-html", 2, 0, 0,
                   (SCM pointer, SCM html),
                   "Requests webkit VIEW pointer to load HTML")
{
  GtkWidget *view = (GtkWidget *)scm_to_pointer (pointer);
  char *c_content = scm_to_locale_string (html);
  webkit_web_view_load_html (WEBKIT_WEB_VIEW (view), c_content, "nomad://");
  g_free (c_content);
  return SCM_UNSPECIFIED;
}

gboolean
scroll_up_invoke (void *data)
{
  WebKitWebView *web_view;
  NomadApp *app = nomad_app_get_default ();

  web_view = nomad_app_get_webview (NOMAD_APP (app));
  webkit_web_view_run_javascript (web_view, "window.scrollBy(0, -25)", NULL,
                                  NULL, NULL);
  return FALSE;
}

SCM_DEFINE_PUBLIC (scm_nomad_scroll_up, "scroll-up", 0, 0, 0, (),
                   "Internal procedure to scroll WebView up")
{
  g_main_context_invoke (NULL, scroll_up_invoke, NULL);
  return SCM_UNDEFINED;
}

gboolean
scroll_down_invoke (void *data)
{
  WebKitWebView *web_view;
  NomadApp *app = nomad_app_get_default ();

  web_view = nomad_app_get_webview (NOMAD_APP (app));
  webkit_web_view_run_javascript (web_view, "window.scrollBy(0, 25)", NULL,
                                  NULL, NULL);
  return FALSE;
}

SCM_DEFINE_PUBLIC (scm_nomad_scroll_down, "scroll-down", 0, 0, 0, (), "")
{
  g_main_context_invoke (NULL, scroll_down_invoke, NULL);
  return SCM_UNDEFINED;
}

gboolean
web_view_back_invoke (void *data)
{
  struct request *request = data;
  NomadApp *app = nomad_app_get_default ();

  WebKitWebView *web_view = nomad_app_get_webview (app);

  if (web_view == NULL)
    {
      request->done = TRUE;
      return FALSE;
    }

  if (!webkit_web_view_can_go_back (web_view))
    {
      request->done = TRUE;
      return FALSE;
    }
  webkit_web_view_go_back (web_view);
  request->response = SCM_BOOL_T;
  request->done = TRUE;
  return FALSE;
}

SCM_DEFINE_PUBLIC (
    scm_nomad_webkit_go_back, "webview-go-back", 0, 0, 0, (),
    "Request WebKitView to go back in history. If WebView can not be found or "
    "there is no back history then it return #f. Otherwise it returns #t.")
{
  struct request *request
      = &(struct request){ .response = SCM_BOOL_F, .done = FALSE };

  g_main_context_invoke (NULL, web_view_back_invoke, request);
  wait_for_response (request);
  return request->response;
}

// FIXME: invoke on main thread
SCM_DEFINE_PUBLIC (
    scm_nomad_webkit_go_foward, "webview-go-forward", 0, 0, 0, (),
    "Internal request WebKitView to go forward in history. If WebView can not "
    "be found or there is no forward history then it returns #f. Otherwise it "
    "returns #t. TODO: maybe provide a callback for load-change signal.")
{
  WebKitWebView *web_view;
  NomadApp *app = nomad_app_get_default ();

  web_view = nomad_app_get_webview (NOMAD_APP (app));

  if (web_view == NULL)
    {
      return SCM_BOOL_F;
    }

  if (!webkit_web_view_can_go_forward (web_view))
    {
      return SCM_BOOL_F;
    }
  webkit_web_view_go_forward (web_view);
  return SCM_BOOL_T;
}

SCM_DEFINE_PUBLIC (
    scm_nomad_webkit_reload, "webview-reload", 0, 1, 0, (SCM nocache),
    "Internally reloads WebKitView, if nocache is #t then bypass "
    "WebKit cache. This procedure should almost never be called "
    "directly. TODO: detail higher level procedures for reloading "
    "webkit. Probably only (reload) in this case.")
{
  WebKitWebView *web_view;
  NomadApp *app = nomad_app_get_default ();

  web_view = nomad_app_get_webview (NOMAD_APP (app));

  if (web_view == NULL)
    {
      return SCM_BOOL_F;
    }

  if (scm_is_true (nocache))
    {
      webkit_web_view_reload_bypass_cache (web_view);
    }
  else
    {
      webkit_web_view_reload (web_view);
    }
  return SCM_BOOL_T;
}

SCM_DEFINE_PUBLIC (
    scm_nomad_get_current_url, "webview-current-url", 0, 0, 0, (),
    "Return's the WebView's current URL. This calls webkit's "
    "webkit_web_view_get_uri. Note: this function can potentially "
    "return a URI that is not a URL. Since the API is directed "
    "towards end users, we use URL since it's the more common term, "
    "see https://danielmiessler.com/study/url-uri/ on the distinction "
    "of URI vs URL")
{
  NomadApp *app = nomad_app_get_default ();
  WebKitWebView *web_view;
  const char *uri;
  SCM result;

  web_view = nomad_app_get_webview (NOMAD_APP (app));
  uri = webkit_web_view_get_uri (web_view);

  if (uri == NULL)
    {
      result = scm_from_utf8_string ("URI not loaded");
    }
  else
    {
      result = scm_from_locale_string (uri);
    }

  return result;
}

void
run_hints_cb (GObject *source_object, GAsyncResult *res, gpointer user_data)
{
  WebKitWebView *view = user_data;
  GError *error = NULL;
  webkit_web_view_run_javascript_from_gresource_finish (view, res, &error);
  if (error != NULL)
    {
      g_printerr ("Error invoking Javascript resource: %s\n", error->message);
      g_error_free (error);
    }
  g_print ("RESULT CB\n");
}

// FIXME: invoke on main thread?
SCM_DEFINE_PUBLIC (scm_nomad_show_hints, "hints", 0, 0, 0, (),
                   "Shows WebView html links.")
{
  NomadApp *app = nomad_app_get_default ();
  WebKitWebView *view = nomad_app_get_webview (app);

  webkit_web_view_run_javascript_from_gresource (
      view, "/org/gnu/nomad/hints.js", NULL, run_hints_cb, view);

  return SCM_UNDEFINED;
}

void
nomad_webkit_register_function (void *data)
{
#ifndef SCM_MAGIC_SNARFER
#include "webkit.x"
#endif
}
