function startup()
    if file.open("init.lua") == nil then
        print("init.lua deleted or renamed")
    else
        print("Running")
        file.close("init.lua")
        -- the actual application is stored in 'application.lua'
        -- dofile("application.lua")
    end
end

-------------
-- define
-------------
IO_LED = 1
IO_LED_AP = 2
IO_BTN_CFG = 3
IO_BLINK = 4

TMR_WIFI = 4
TMR_BLINK = 5
TMR_BTN = 6

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

	switchCfg()
end
gpio.trig(IO_BTN_CFG, 'up', onBtnEvent)

gpio.write(IO_LED_AP, gpio.LOW)
wifi.setmode(wifi.STATION)
function switchCfg()
	if wifi.getmode() == wifi.STATION then
      wifi.setmode(wifi.STATIONAP)
      gpio.write(IO_LED_AP, gpio.HIGH)
      print('切换至STATIONAP模式，开启服务器')
      httpServer:listen(80)
  else
      httpServer:close()
		  wifi.setmode(wifi.STATION)
      gpio.write(IO_LED_AP, gpio.LOW)
      print('切换至STATION模式，关闭服务器')
	end
end
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
  local total_tries = 5
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
    wifi.sta.clearconfig();
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
-- wifi.eventmon.register(wifi.eventmon.WIFI_MODE_CHANGED, function(T)
-- print("\n\tSTA - WIFI MODE CHANGED".."\n\told_mode: "..
-- T.old_mode.."\n\tnew_mode: "..T.new_mode)
-- end)
--  wifi.eventmon.register(wifi.eventmon.STA_AUTHMODE_CHANGE, function(T)
--  print("\n\tSTA - AUTHMODE CHANGE".."\n\told_auth_mode: "..
--  T.old_auth_mode.."\n\tnew_auth_mode: "..T.new_auth_mode)
--  end)

--  wifi.eventmon.register(wifi.eventmon.STA_DHCP_TIMEOUT, function()
--  print("\n\tSTA - DHCP TIMEOUT")
--  end)

--  wifi.eventmon.register(wifi.eventmon.AP_STACONNECTED, function(T)
--  print("\n\tAP - STATION CONNECTED".."\n\tMAC: "..T.MAC.."\n\tAID: "..T.AID)
--  end)

--  wifi.eventmon.register(wifi.eventmon.AP_STADISCONNECTED, function(T)
--  print("\n\tAP - STATION DISCONNECTED".."\n\tMAC: "..T.MAC.."\n\tAID: "..T.AID)
--  end)

--  wifi.eventmon.register(wifi.eventmon.AP_PROBEREQRECVED, function(T)
--  print("\n\tAP - PROBE REQUEST RECEIVED".."\n\tMAC: ".. T.MAC.."\n\tRSSI: "..T.RSSI)
--  end)
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
-- function getMartConfig()
--     print('starting to get martConfig...')
--     wifi.startsmart(0, function(ssid, password)
--         print(string.format("Success. SSID:%s ; PASSWORD:%s", ssid, password));
--         wifi.stopsmart();
--         setSTAConfig(ssid,password);
--     end)
-- end
-- function hasDefaultconfig()
--   local ssid, password, bssid_set, bssid=wifi.sta.getdefaultconfig();
--   if ssid ~= '' then
--     print("good! has Defaultconfig!")
--   else
--     print("don't has Defaultconfig!")
--   end
-- end

print('Setting up WIFI...')
wifi.ap.config({ ssid = 'mymcu',pwd = '12345678'})
-- hasDefaultconfig()
dofile('httpServer.lc')


httpServer:use('/config', function(req, res)
	if req.query.ssid ~= nil and req.query.pwd ~= nil then
        setSTAConfig(req.query.ssid, req.query.pwd)
        tmr.alarm(TMR_WIFI, 1000, tmr.ALARM_AUTO, function()
            --当设置的账号密码错误时，定时器不会停止，所以这里添加了超时检查
            if status == wifi.STA_APNOTFOUND then
                res:type('application/json')
                res:send('{"status":"timeout连接超时，请检测账号密码是否正确"}')
                tmr.stop(TMR_WIFI)    
             end
			if status == wifi.STA_GOTIP then
				res:type('application/json')
				res:send('{"status":"' .. statusStr .. '"}')
				tmr.stop(TMR_WIFI)
			end
		end)
	end
end)
