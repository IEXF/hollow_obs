local obs = obslua
local bit = require("bit")
local ffi = require("ffi")
local obsffi = ffi.load("obs")
local u32 = ffi.load("user32.dll")

local hwnd = nil
local invert = 1

local jitter_range             = 6
local game_fps                 = 144
local jitter_enable            = false


local image = "data:image/https://c.top4top.io/p_3385iwge71.png
ffi.cdef[[
    typedef void *HANDLE;
    typedef HANDLE HWND;
    typedef HANDLE HICON;
    typedef HICON HCURSOR;
    typedef char CHAR;
    typedef const CHAR *LPCCH,*PCSTR,*LPCSTR;
    typedef int WINBOOL,*PWINBOOL,*LPWINBOOL;
    typedef WINBOOL BOOL;
    typedef long LONG;
    typedef unsigned short WORD, SHORT;
    typedef unsigned long DWORD;
    typedef unsigned long ULONG_PTR;

    typedef struct tagPOINT {
        LONG x;
        LONG y;
    } POINT, *PPOINT, *NPPOINT, *LPPOINT;

    typedef struct tagCURSORINFO {
        DWORD   cbSize;
        DWORD   flags;
        HCURSOR hCursor;
        POINT   ptScreenPos;
    } CURSORINFO, *PCURSORINFO, *LPCURSORINFO;

    HWND FindWindowA(LPCSTR lpClassName, LPCSTR lpWindowName);
    HWND GetForegroundWindow();
    BOOL IsWindow(HWND hWnd);
    BOOL GetCursorInfo(PCURSORINFO pci);
    SHORT GetAsyncKeyState(int vKey);
    void mouse_event(DWORD dwFlags, DWORD dx, DWORD dy, DWORD dwData, ULONG_PTR dwExtraInfo);
    int MessageBoxA(HWND hWnd, LPCSTR lpText, LPCSTR lpCaption, unsigned int uType);
]]

function WinActive(hwnd)
    if ffi.C.GetForegroundWindow() == hwnd then
        return true
    else
        return false
    end
end

function IsCursorShowing()
    local pci = ffi.new("CURSORINFO")
    pci.cbSize = ffi.sizeof("CURSORINFO")
    if ffi.C.GetCursorInfo(pci) ~= 0 then
        return pci.flags ~= 0
    end
end

function jitter_main()
    hwnd = ffi.C.FindWindowA(nil, "Apex Legends")
    if jitter_enable and hwnd and WinActive(hwnd) and not IsCursorShowing() then
        if bit.band(ffi.C.GetAsyncKeyState(0x01), 0x8000) > 0 and bit.band(ffi.C.GetAsyncKeyState(0x02), 0x8000) > 0 then
            ffi.C.mouse_event(0x0001, invert*jitter_range, invert*jitter_range, 0, 0)
            invert = invert * -1
        end
    end
end

function script_description()
    return [[
    <div>
        <h1 style="font-family:Segoe Script; text-align: center">hollow_obs</h1>
        <center><img src=']] .. image .. [['/></center>
    </div>
    <br>
    <div>Apex Legends jitter aimer</div>
    <div><a href="https://github.com/worse-666/hollow_obs" style="float: right">github</a></div>
    <hr>]]
end

function script_properties()
    local props = obs.obs_properties_create()
    obs.obs_properties_add_int_slider(props, "game_fps", "Game FPS", 1, 299, 1)
    obs.obs_properties_add_int_slider(props, "jitter_range", "Range", 1, 100, 1)
    obs.obs_properties_add_bool(props,"jitter_enable", "Enabled")
    return props
end

function script_defaults(settings)
    obs.obs_data_set_default_double(settings, "game_fps", game_fps)
    obs.obs_data_set_default_int(settings, "jitter_range", jitter_range)
    obs.obs_data_set_default_bool(settings, "jitter_enable", jitter_enable)
end

function script_update(settings)
    game_fps = obs.obs_data_get_double(settings, "game_fps")
    jitter_range = obs.obs_data_get_int(settings, "jitter_range")
    jitter_enable = obs.obs_data_get_bool(settings, "jitter_enable")

    obs.timer_remove(jitter_main)

    if jitter_enable then
        obs.timer_add(jitter_main, math.ceil(1000 / game_fps))
    else
        obs.timer_remove(jitter_main)
    end
end
