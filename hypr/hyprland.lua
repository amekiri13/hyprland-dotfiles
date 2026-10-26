-- Hyprland 0.56 Lua migration of hyprland.conf.
local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "dolphin"
local menu = "hyprlauncher"

hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
-- XWayland uses XIM; Qt applications use the Fcitx5 input module.
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_IM_MODULE", "fcitx")

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("dunst")
    hl.exec_cmd("/home/amekiri/.config/hypr/obs-dunst-quiet.sh")
    hl.exec_cmd("polkit-kde-agent")
    hl.exec_cmd("kwalletd6")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("fcitx5")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("/usr/lib/pam_kwallet_init")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("mkdir -p ~/Pictures/Screenshots")
end)

hl.config({
    general = { border_size = 0 },
    dwindle = { force_split = 2 },
    render = {
        cm_enabled = true,
        cm_auto_hdr = 1,
        direct_scanout = 0,
    },
    xwayland = { force_zero_scaling = true },
    misc = { render_unfocused_fps = 60 },
})

hl.monitor({
    output = "DP-2",
    mode = "2560x1600@240",
    position = "0x0",
    scale = 1.6,
    bitdepth = 10,
    cm = "hdr",
    sdrbrightness = 3.0,
})

-- Blur Waybar and Dunst's translucent layer-shell surfaces.
hl.layer_rule({
    name = "waybar-blur",
    match = { namespace = "waybar" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.5,
})
hl.layer_rule({
    name = "notifications-blur",
    match = { namespace = "notifications" },
    blur = true,
    ignore_alpha = 0.5,
})

hl.window_rule({
    name = "kitty-suppress-maximize",
    match = { class = "^(kitty)$" },
    suppress_event = "maximize",
})

for _, class in ipairs({
    "^(mpv)$",
    "^(addiction_demo-win64-shipping.exe)$",
    "^(steam_app_default)$",
}) do
    hl.window_rule({
        name = "disable-tonemap-" .. class,
        match = { class = class },
        tonemap = "off",
    })
end

hl.window_rule({
    name = "steam-render-unfocused",
    match = { class = "^(steam_app_default)$" },
    render_unfocused = true,
})
hl.window_rule({
    name = "render-unfocused",
    match = { class = ".*" },
    render_unfocused = true,
})

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("pidof hyprlock || hyprlock"))

for _, direction in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mainMod .. " + " .. direction, hl.dsp.focus({ direction = direction }))
end

for workspace = 1, 10 do
    local key = workspace % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end

for key, workspace in pairs({ bracketleft = "-1", bracketright = "+1" }) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = workspace }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
end
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Capture to a file and the clipboard; retain the original key mappings.
local screenshotDir = "~/Pictures/Screenshots/"
local timestamp = "$(date +%Y%m%d_%H%M%S)"
hl.bind("Print", hl.dsp.exec_cmd('f=' .. screenshotDir .. timestamp .. '.png && grim "$f" && wl-copy < "$f"'))
local areaCapture = 'f=' .. screenshotDir .. timestamp .. '.png && grim -g "$(slurp)" "$f" && wl-copy < "$f"'
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(areaCapture))
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd(areaCapture))
hl.bind("CTRL + Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
