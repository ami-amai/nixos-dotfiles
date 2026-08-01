-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
-- hl.on("hyprland.start", function () 
--   hl.exec_cmd(terminal)
--   hl.exec_cmd("nm-applet")
--   hl.exec_cmd("waybar & hyprpaper & firefox")
-- end)

hl.exec_cmd("awww-daemon")
hl.exec_cmd("amixer set Master unmute")
hl.exec_cmd("amixer set Master 50%")
hl.exec_cmd("sudo alsactl store")



hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
