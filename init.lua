function startup()
    if file.open("init.lua") == nil then
        print("init.lua deleted or renamed")
    else
        print("Running")
        file.close("init.lua")
        -- the actual application is stored in 'application.lua'
        dofile("app.lua")
    end
end

-------------
-- define
-------------
IO_LED_AP = 1
IO_LED = 2
IO_BTN_CFG = 3
IO_BLINK = 4

TMR_WIFI = 0
TMR_BLINK = 1
TMR_BTN = 2

gpio.mode(IO_LED, gpio.OUTPUT)
gpio.mode(IO_LED_AP, gpio.OUTPUT)
gpio.mode(IO_BTN_CFG, gpio.INT)
gpio.mode(IO_BLINK, gpio.OUTPUT)

-------------
-- button
-------------
function onBtnEvent()
	gpio.trig(IO_BTN_CFG)
	tmr.alarm(TMR_BTN, 500, tmr.ALARM_SINGLE, function()
		gpio.trig(IO_BTN_CFG, 'up', onBtnEvent)
  end)
  wifi.sta.disconnect()
  print("Aborting connection to AP!")
  print("清除配置重新进入smartConfig模式")
  getMartConfig();
end
gpio.trig(IO_BTN_CFG, 'up', onBtnEvent)

gpio.write(IO_LED_AP, gpio.LOW)
wifi.setmode(wifi.STATION)
-------------
-- blink
-------------
blink = nil
tmr.register(TMR_BLINK, 100, tmr.ALARM_AUTO, function()
	gpio.write(IO_BLINK, blink.i % 2)
	tmr.interval(TMR_BLINK, blink[blink.i + 1])
	blink.i = (blink.i + 1) % #blink
end)

function blinking(param)
	if type(param) == 'table' then
		blink = param
		blink.i = 0
		tmr.interval(TMR_BLINK, 1)
		running, _ = tmr.state(TMR_BLINK)
		if running ~= true then
			tmr.start(TMR_BLINK)
		end
	else
		tmr.stop(TMR_BLINK)
		gpio.write(IO_BLINK, param or gpio.LOW)
	end
end
-- Define WiFi station event callbacks 
wifi_connect_event = function(T) 
  print("MAC: "..wifi.sta.getmac());
  print("Connection to AP("..T.SSID..") established!")
  print("Waiting for IP address...")
end
wifi_disconnect_event = function(T)
  if T.reason == wifi.eventmon.reason.ASSOC_LEAVE then 
    --the station has disassociated from a previously connected AP
    return 
  end
  -- total_tries: how many times the station will attempt to connect to the AP. Should consider AP reboot duration.
  local total_tries = 10
  print("\nWiFi connection to AP("..T.SSID..") has failed!")

  --There are many possible disconnect reasons, the following iterates through 
  --the list and returns the string corresponding to the disconnect reason.
  for key,val in pairs(wifi.eventmon.reason) do
    if val == T.reason then
      print("Disconnect reason: "..val.."("..key..")")
      break
    end
  end

  if disconnect_ct == nil then 
    disconnect_ct = 1 
  else
    disconnect_ct = disconnect_ct + 1 
  end
  if disconnect_ct < total_tries then 
    print("Retrying connection...(attempt "..(disconnect_ct+1).." of "..total_tries..")")
  else
    wifi.sta.disconnect()
    print("Aborting connection to AP!")
    -- getMartConfig();
    disconnect_ct = nil  
  end
end
wifi_got_ip_event = function(T) 
  -- Note: Having an IP address does not mean there is internet access!
  -- Internet connectivity can be determined with net.dns.resolve().    
  print("Wifi connection is ready! IP address is: "..T.IP)
  print("Startup will resume momentarily, you have 3 seconds to abort.")
  print("Waiting...")
  if disconnect_ct ~= nil then disconnect_ct = nil end
  tmr.create():alarm(3000, tmr.ALARM_SINGLE, startup)
end
prvStatus = nil
status = nil
statusStr = ''
wifi_modechange_event = function()
    status = wifi.sta.status();
    if status == prvStatus then return else prvStatus = status end
    if status == wifi.STA_WRONGPWD then
        statusStr = 'STA_WRONGPWD'
        blinking({100, 100 , 100, 500})
    elseif status == wifi.STA_CONNECTING then
        statusStr = 'STA_CONNECTING'
        blinking({300, 300})
    elseif status == wifi.STA_GOTIP then
        statusStr = 'STA_GOTIP'
        blinking()
        print('IP-MASK-ROUTER:'..wifi.sta.getip())
    elseif status == wifi.STA_APNOTFOUND or status == 0 then
        statusStr = 'STA_APNOTFOUND'
        blinking({2000, 2000})
    end
    print('STA_STATUS: '..statusStr)
end
tmr.create():alarm(1000, tmr.ALARM_AUTO, wifi_modechange_event)
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, wifi_got_ip_event)
wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, wifi_connect_event)
wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, wifi_disconnect_event)
-------------
-- wifi
-------------
function setSTAConfig(SSID, PASSWORD)
  local station_cfg={}
  station_cfg.ssid=SSID
  station_cfg.pwd=PASSWORD
  station_cfg.save=true
  station_cfg.auto=true
  if SSID == "PABank-Web" then
    wifi.sta.setmac("14:10:9f:d0:9c:57")
  end
  wifi.sta.config(station_cfg)
end
-------------
-- getWIFIConfig
-------------
function getMartConfig()
    wifi.sta.clearconfig();
    gpio.write(IO_LED_AP, gpio.HIGH)
    print('starting to get martConfig...')
    wifi.startsmart(0, function(ssid, password)
        print(string.format("Success. SSID:%s ; PASSWORD:%s", ssid, password));
        wifi.stopsmart();
        gpio.write(IO_LED_AP, gpio.LOW)
        if(password == '~~~~~~~~') then password = '' end
        setSTAConfig(ssid,password);
    end)
end
function hasDefaultconfig()
  local ssid, password, bssid_set, bssid=wifi.sta.getdefaultconfig();
  if ssid ~= '' then
    if ssid == "PABank-Web" then
      wifi.sta.setmac("14:10:9f:d0:9c:57")
    end
    print("good! has Defaultconfig!")
  else
    print("don't has Defaultconfig!")
    getMartConfig()
  end
end

print('Setting up WIFI...')
wifi.sta.setmac("14:10:9f:d0:9c:57")
-- setSTAConfig('PABank-Web', '')
hasDefaultconfig()