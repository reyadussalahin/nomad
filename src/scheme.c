/*
 * scm.c
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
#include <gtk/gtk.h>
#include <libguile.h>
#include <webkit2/webkit2.h>

#include "app.h"
#include "scheme.h"
#include "window.h"

#define WEMACS_VERSION "0.1"

SCM_DEFINE (scm_wemacs_version, "wemacs-version", 0, 0, 0, (), "test macro")
{
  return scm_from_locale_string (WEMACS_VERSION);
}

SCM_DEFINE (scm_wemacs_start, "browser-start", 0, 0, 0, (), "")
{
  intmax_t status;
  app = G_APPLICATION (wemacs_app_new ());
  status = g_application_run (app, 0, NULL);
  return scm_from_intmax (status);
}

SCM_DEFINE (scm_wemacs_kill, "wemacs-kill", 0, 0, 0, (), "test macro")
{
  g_application_quit (G_APPLICATION (app));
  return SCM_UNDEFINED;
}

SCM_DEFINE (scm_wemacs_webkit_load_uri, "web-view-load-uri", 1, 0, 0,
            (SCM uri), "TODO: document this procedure.")
{
  gchar *curi;
  WebKitWebView *webView;

  curi = scm_to_locale_string (uri);
  webView = wemacs_app_get_webview (WEMACS_APP (app));
  if (!webView)
    {
      return SCM_BOOL_F;
    }
  webkit_web_view_load_uri (webView, curi);
  return uri;
}

void *
scroll_down (void *data)
{
  WebKitWebView *web_view;
  web_view = wemacs_app_get_webview (WEMACS_APP (app));
  webkit_web_view_run_javascript (web_view, "window.scrollBy(0, 25)", NULL,
                                  NULL, NULL);
  return NULL;
}
SCM_DEFINE (scm_wemacs_scroll_down, "scroll-down", 0, 0, 0, (), "test macro")
{
  scm_with_guile (scroll_down, NULL);
  return SCM_UNDEFINED;
}

SCM_DEFINE (scm_wemacs_scroll_up, "scroll-up", 0, 0, 0, (), "test macro")
{
  WebKitWebView *webView;
  webView = wemacs_app_get_webview (WEMACS_APP (app));
  webkit_web_view_run_javascript (webView, "window.scrollBy(0, -25)", NULL,
                                  NULL, NULL);
  return SCM_UNDEFINED;
}

SCM_DEFINE (
    scm_wemacs_webkit_go_back, "web-view-go-back", 0, 0, 0, (),
    "Internal request WebKitView to go back in history. If WebView can not \
be found or there is no back history then it returns #f. Otherwise \
it returns #t. TODO: maybe provide a callback for load-change signal.")
{
  WebKitWebView *webView;

  webView = wemacs_app_get_webview (WEMACS_APP (app));

  if (!webView)
    {
      return SCM_BOOL_F;
    }

  if (!webkit_web_view_can_go_back (webView))
    {
      return SCM_BOOL_F;
    }
  webkit_web_view_go_back (webView);
  return SCM_BOOL_T;
}

SCM_DEFINE (
    scm_wemacs_webkit_go_foward, "web-view-go-forward", 0, 0, 0, (),
    "Internal request WebKitView to go forward in history. If WebView can \
not be found or there is no forward history then it returns \
#f. Otherwise it returns #t. TODO: maybe provide a callback for \
load-change signal.")
{
  WebKitWebView *webView;

  webView = wemacs_app_get_webview (WEMACS_APP (app));

  if (!webView)
    {
      return SCM_BOOL_F;
    }

  if (!webkit_web_view_can_go_forward (webView))
    {
      return SCM_BOOL_F;
    }
  webkit_web_view_go_forward (webView);
  return SCM_BOOL_T;
}

SCM_DEFINE (
    scm_wemacs_webkit_reload, "web-view-reload", 0, 1, 0, (SCM nocache),
    "Internally reloads WebKitView, if nocache is #t then bypass WebKit \
cache. This procedure should almost never be called directly. TODO: \
detail higher level procedures for reloading webkit. Probably only \
(reload) in this case.")
{
  WebKitWebView *webView;

  webView = wemacs_app_get_webview (WEMACS_APP (app));

  if (!webView)
    {
      return SCM_BOOL_F;
    }

  if (scm_is_true (nocache))
    {
      webkit_web_view_reload_bypass_cache (webView);
    }
  else
    {
      webkit_web_view_reload (webView);
    }
  return SCM_BOOL_T;
}

void
register_functions (void *data)
{
#include "scheme.x"
}
SCM_DEFINE (scm_wemacs_get_current_url, "current-url", 0, 0, 0, (),
            "Return's the WebView's current URL. This calls webkit's \
webkit_web_view_get_uri. Note: this function can potentially return a \
URI that is not a URL. Since the API is directed towards end users, \
we use URL since it's the more common term. \
\
see https://danielmiessler.com/study/url-uri/ on the distinction of     \
URI vs URL")
{
  WebKitWebView *web_view;
  const char *uri;
  SCM result;

  web_view = wemacs_app_get_webview (WEMACS_APP (app));
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

