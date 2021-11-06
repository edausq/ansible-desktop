-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
require("awful.completion")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
-- now using dunst
--local naughty = require("naughty")

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/home/edausque/.config/awesome/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
editor = os.getenv("EDITOR") or "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.floating,
    awful.layout.suit.tile,
--    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
--    awful.layout.suit.tile.top,
--    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
--    awful.layout.suit.spiral,
--    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max.fullscreen,
    awful.layout.suit.max,
    awful.layout.suit.magnifier
}
-- }}}

-- {{{ Helper functions
local function client_menu_toggle_fn()
    local instance = nil

    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end
-- }}}


-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "restart", awesome.restart },
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "quit", function() awesome.quit() end }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })
-- }}}

mykeyboardlayout = awful.widget.keyboardlayout()

-- Create a textclock widget
mytextclock = awful.widget.textclock(" %a %b %d, %H:%M:%S ", 1)

-- Create a wibox for each screen and add it
local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t)
                                              if client.focus then
                                                  client.focus:move_to_tag(t)
                                              end
                                          end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t)
                                              if client.focus then
                                                  client.focus:toggle_tag(t)
                                              end
                                          end),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() and c.first_tag then
                                                      c.first_tag:view_only()
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, client_menu_toggle_fn()),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                          end))


-- {{{ Wibox
myvolstatus = wibox.widget.textbox()
myvolstatus:set_text('♫ ♩ ')
myvolstatus:buttons(awful.util.table.join(
    awful.button({}, 1, function () awful.spawn('sh -c \'notify-send -t 10000 "Volume" "$(pacmd dump | grep set-)"\'') end ), -- looking for something better..
    awful.button({}, 2, function () volume('toggle') end ),
    awful.button({}, 3, function () awful.spawn('pavucontrol') end ),
    awful.button({}, 4, function () volume('up') end ),
    awful.button({}, 5, function () volume('down') end )
))

mysystemstatus = wibox.widget.textbox()
mysystemstatus:set_markup(' (loading)')

-- hook MAJ status bar
mytimer = timer({ timeout = 5 })
mytimer:connect_signal("timeout", function()
-- {{ loadavg
    local f = io.open('/proc/loadavg')
    if f then
        local loads = f:read("*l")
        f:close()
        if loads then
            load1 = loads:match("^(%d+%.%d%d)")
        end
    end

    load1 = tonumber(load1)
    if load1 <= 0.65 then color = 'grey' end
    if load1 > 0.65 then color = 'white' end
    if load1 > 0.99 then color = 'orange' end
    if load1 > 3.5  then color = 'red' end
    loadavg = string.format('<span color="%s">%.2f</span>', color, load1)
-- }}

-- {{ %mem
    local mem = {}
    for line in io.lines("/proc/meminfo") do
            for k, v in string.gmatch(line, "([%a]+):[%s]+([%d]+).+") do
                    if     k == "MemTotal"	then mem.total = v
                    elseif k == "MemFree"	then mem.free = v
                    elseif k == "Buffers"	then mem.buffers = v
                    elseif k == "Cached"	then mem.cached = v
                    end
            end
    end

    mem = tonumber(100*(1  - (mem.free + mem.buffers + mem.cached) / mem.total))
    if mem <= 60 then color = 'grey' end
    if mem > 60 then color = 'white' end
    if mem > 75 then color = 'orange' end
    if mem > 85  then color = 'red' end
    meminfo = string.format('<span color="%s">%.2f%%</span>', color, mem)
-- }}

-- {{ battery
    local f = io.popen('acpi -b')
    if f then
        local bats = f:read("*l")
        f:close()
        if bats then
            bat = bats:match("^Battery 0:.*")
        end
    end

    state = bat:match("Battery 0: (.*),")
    pourc = bat:match("(%d+)%%")
    rem = bat:match("(%d+:%d+):")

    if string.find(state, ",") then
        state = state:match("(.*),")
    end

    if state == 'Full' then status = '↯'
    elseif state == 'Discharging' then status = '<span color="white">⚡</span>'
    elseif state == 'Charging' then status = '↯'
    elseif state == 'Unknown' then status = '?'
    else status = state end

    pourc = tonumber(pourc)
    if pourc > 40 then color = 'grey' end
    if pourc <= 40 then color = 'white' end
    if pourc <= 25 then color = 'orange' end
    if pourc <= 10 then color = 'red' end
    pourcinfo = string.format('<span color="%s">%2d%%</span>', color, pourc)

    -- alert
    if pourc <= 10 and state == 'Discharging' then
    awful.util.spawn('sh -c \'notify-send -u critical -t 4950 "Alert battery" "$(acpi -b)"\'')
    end

    -- sleep
    if pourc < 3 and state == 'Discharging' then
    awful.util.spawn('sh -c \'dbus-send --system --print-reply --dest="org.freedesktop.UPower" /org/freedesktop/UPower org.freedesktop.UPower.Suspend >/dev/null\'')
    end

    batinfo = string.format('%s%s', status, pourcinfo)
    if rem then batinfo = string.format('%s (%s)', batinfo, rem) end
-- }}

-- week of year

    useDate = os.time()
    weekNum = getWeekNumberOfYear(useDate)
    out = string.format(" %s - %s %s - W%s", loadavg, meminfo, batinfo, weekNum)

    mysystemstatus:set_markup(out) --TODO: split that in 3 widgets (and then, add buttons (htop, upower -d)
end)
mytimer:start()

function Dec2Hex(nValue)
    if type(nValue) == "string" then
        nValue = String.ToNumber(nValue);
    end
    nHexVal = string.format("%X", nValue);  -- %X returns uppercase hex, %x gives lowercase letters
    sHexVal = nHexVal.."";
    return sHexVal;
end



-- Get day of a week at year beginning 
--(tm can be any date and will be forced to 1st of january same year)
-- return 1=mon 7=sun
function getYearBeginDayOfWeek(tm)
  yearBegin = os.time{year=os.date("*t",tm).year,month=1,day=1}
  yearBeginDayOfWeek = tonumber(os.date("%w",yearBegin))
  -- sunday correct from 0 -> 7
  if(yearBeginDayOfWeek == 0) then yearBeginDayOfWeek = 7 end
  return yearBeginDayOfWeek
end

-- tm: date (as retruned fro os.time)
-- returns basic correction to be add for counting number of week
--  weekNum = math.floor((dayOfYear + returnedNumber) / 7) + 1 
-- (does not consider correctin at begin and end of year) 
function getDayAdd(tm)
  yearBeginDayOfWeek = getYearBeginDayOfWeek(tm)
  if(yearBeginDayOfWeek < 5 ) then
    -- first day is week 1
    dayAdd = (yearBeginDayOfWeek - 2)
  else 
    -- first day is week 52 or 53
    dayAdd = (yearBeginDayOfWeek - 9)
  end  
  return dayAdd
end
-- tm is date as returned from os.time()
-- return week number in year based on ISO8601 
-- (week with 1st thursday since Jan 1st (including) is considered as Week 1)
-- (if Jan 1st is Fri,Sat,Sun then it is part of week number from last year -> 52 or 53)
function getWeekNumberOfYear(tm)
  dayOfYear = os.date("%j",tm)
  dayAdd = getDayAdd(tm)
  dayOfYearCorrected = dayOfYear + dayAdd
  if(dayOfYearCorrected < 0) then
    -- week of last year - decide if 52 or 53
    lastYearBegin = os.time{year=os.date("*t",tm).year-1,month=1,day=1}
    lastYearEnd = os.time{year=os.date("*t",tm).year-1,month=12,day=31}
    dayAdd = getDayAdd(lastYearBegin)
    dayOfYear = dayOfYear + os.date("%j",lastYearEnd)
    dayOfYearCorrected = dayOfYear + dayAdd
  end  
  weekNum = math.floor((dayOfYearCorrected) / 7) + 1
  if( (dayOfYearCorrected > 0) and weekNum == 53) then
    -- check if it is not considered as part of week 1 of next year
    nextYearBegin = os.time{year=os.date("*t",tm).year+1,month=1,day=1}
    yearBeginDayOfWeek = getYearBeginDayOfWeek(nextYearBegin)
    if(yearBeginDayOfWeek < 5 ) then
      weekNum = 1
    end  
  end  
  return weekNum
end  



-- volume function
function volume(cmd)
    --device = 'alsa_output.usb-Generic_USB_Audio_200901010001-00.HiFi__hw_Dock_0__sink'
    --device = 'alsa_output.pci-0000_00_1f.3.analog-stereo'
    --device = 'alsa_output.usb-Kingston_HyperX_Virtual_Surround_Sound_00000000-00.analog-stereo'
    device = 'alsa_output.usb-Sennheiser_Sennheiser_SC_1x5_USB_A002460193007107-00.analog-stereo'
    if cmd == 'toggle' then cmd = string.format('pactl set-sink-mute %s toggle',device)
    elseif cmd == 'up' then cmd = string.format('pactl set-sink-volume %s +2%%',device)
    elseif cmd == 'down' then cmd = string.format('pactl set-sink-volume %s -2%%',device)
    else cmd = "pacmd dump" end

    local c = io.popen(cmd)
    local f = io.popen("sleep 0.05 && pacmd dump")
    if f then
        local amixer = f:read("*a")
        f:close()
        if amixer then
            --status = amixer:match("set%-sink%-mute [^%s]+alsa_output.usb%-Kingston_HyperX_Virtual_Surround_Sound_00000000%-00.analog%-stereo (%a+)")
            status = amixer:match("set%-sink%-mute alsa_output.usb%-Kingston_HyperX_Virtual_Surround_Sound_00000000%-00.analog%-stereo (%a+)")
            pourc = amixer:match("set%-sink%-volume alsa_output.usb%-Kingston_HyperX_Virtual_Surround_Sound_00000000%-00.analog%-stereo (0x%x+)")
            if pourc == nil then
                pourc = 0
            end
        end
    end
    if status == 'no' then status = '♫ ' else status = '♩ ' end


    --pourc = tonumber(pourc) / 0x10000
    pourc = tonumber(string.format('%.0f', pourc / 0x10000 * 100))
    if pourc == 80 then
        volinfo = string.format('<span color="#FFFFFF">%s</span>', status)
    elseif pourc > 80 and pourc < 101 then
        color = Dec2Hex((100-pourc)*12+16)
        volinfo = string.format('<span color="#FF%s%s">%s</span>', color, color, status) -- red
    elseif pourc < 80 then
        color = Dec2Hex(272-((80-pourc)*3+16))
        volinfo = string.format('<span color="#%sFF%s">%s</span>', color, color, status) -- green
    elseif pourc > 100 then
        volinfo = string.format('<span color="#FF0000">%s!!</span>', status) -- green
    end

    myvolstatus:set_markup(volinfo)
end
volume('update') -- init

local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper is a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

local function getWeekNumberOfYear()
  dayOfYear = os.date("%j", os.time())
  dayAdd = getDayAdd(tm)
  dayOfYearCorrected = dayOfYear + dayAdd
  if(dayOfYearCorrected < 0) then
    -- week of last year - decide if 52 or 53
    lastYearBegin = os.time{year=os.date("*t",tm).year-1,month=1,day=1}
    lastYearEnd = os.time{year=os.date("*t",tm).year-1,month=12,day=31}
    dayAdd = getDayAdd(lastYearBegin)
    dayOfYear = dayOfYear + os.date("%j",lastYearEnd)
    dayOfYearCorrected = dayOfYear + dayAdd
  end  
  weekNum = math.floor((dayOfYearCorrected) / 7) + 1
  if( (dayOfYearCorrected > 0) and weekNum == 53) then
    -- check if it is not considered as part of week 1 of next year
    nextYearBegin = os.time{year=os.date("*t",tm).year+1,month=1,day=1}
    yearBeginDayOfWeek = getYearBeginDayOfWeek(nextYearBegin)
    if(yearBeginDayOfWeek < 5 ) then
      weekNum = 1
    end  
  end  
  return weekNum
end

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.layouts[2])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end),
                           awful.button({ }, 4, function () awful.layout.inc( 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(-1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    -- Create the wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })

    -- Add widgets to the wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            --mykeyboardlayout,
            myvolstatus,
            wibox.widget.systray(),
            mysystemstatus,
            mytextclock,
            s.mylayoutbox,
        },
    }
end)
-- }}}

-- {{{ Mouse bindings
--[[
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
--]]
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext),
    awful.key({ modkey,           }, "Up", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Down", awful.tag.history.restore),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey, "Shift"   }, "Tab",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey, "Control" }, "Tab", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control", "Shift" }, "Tab", function () awful.screen.focus_relative(-1) end),

    awful.key({ modkey,           }, "oe",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- fn keys
    awful.key({ modkey, }, "Scroll_Lock", false, function () awful.spawn.with_shell("/home/edausque/.local/bin/lock") end), --xlock script
    awful.key({ modkey, }, "Pause", false, function () awful.spawn.with_shell("/home/edausque/.local/bin/lock") end), --xlock script
    awful.key({ }, "Pause", function () awful.spawn.with_shell("mocp -G") end), --pause moc
    awful.key({ }, "Print", function () awful.spawn.with_shell("/home/edausque/.local/bin/scrot") end), --scrot script
    awful.key({ modkey, }, "Print", false, function () awful.spawn.with_shell("/home/edausque/.local/bin/scrot -s") end),
    awful.key({ modkey, }, "F10", false, function () volume('toggle') end),
    awful.key({ modkey, }, "F11", false, function () volume('down') end),
    awful.key({ modkey, }, "F12", false, function () volume('up') end),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end, {description = "run prompt", group = "launcher"})
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Shift"   }, "f",      awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        -- View tag only.
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                           tag:view_only()
                        end
                  end,
                  {description = "view tag #"..i, group = "tag"}),
        -- Toggle tag display.
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end,
                  {description = "toggle tag #" .. i, group = "tag"}),
        -- Move client to tag.
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                     end
                  end,
                  {description = "move focused client to tag #"..i, group = "tag"}),
        -- Toggle tag on focused client.
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
                      end
                  end,
                  {description = "toggle focused client on tag #" .. i, group = "tag"})
    )
end


clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen } },
   { rule_any = { instance = {"plugin-container", "exe", "/usr/lib64/firefox/plugin-container"} }, properties = { floating = true } },
   { rule = { name = "PlayOnLinux" }, properties = { floating = true, tag = "4" } },
   { rule = { class = "Wine" }, properties = { floating = true, tag = "4" } },
   { rule = { class = "Steam" }, properties = { floating = true, tag = "5" } },
   { rule = { instance = "skype" }, properties = { floating = true } },
   --{ rule = { instance = "skype", role = "CallWindow" }, properties = { floating = false, tag = tags[1][3] } },
   { rule = { class = "Pidgin", role = "buddy_list" }, properties = { floating = true } },
   { rule = { class = "Pidgin", role = "conversation" }, callback = awful.client.setslave },
   { rule = { class = "URxvt" }, callback = awful.client.setslave },
   { rule = { class = "libreoffice" }, properties = { floating = false ,  maximized = false} },
   { rule = { role = "browser" }, properties = { floating = false ,  maximized = false} },
   { rule = { name = "PopupWidgetTitle" }, properties = { floating = true ,  maximized = false} },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

awful.spawn("nm-applet")
awful.completion.bashcomp_load("/usr/share/bash-completion/completions/pass")
--completion.bashcomp_load()
awful.spawn("xset -dpms")
awful.spawn("xset s off")
awful.spawn("/usr/bin/dunst -config /home/edausque/.config/dunst/dunstrc")


-- }}}/
