# ion_overlay_guard

Small Android-only helper used to temporarily hide third-party overlay windows
(`TYPE_APPLICATION_OVERLAY`) while sensitive flows are running.

On Android 12+ it calls `Window.setHideOverlayWindows(true)`.

On other platforms / versions it's a no-op.
