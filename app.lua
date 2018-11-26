config = require("config")

IO_LED = 5
gpio.mode(IO_LED, gpio.OUTPUT)
m = nil
-- Sends a simple ping to the broker
local function send_ping()
    m:publish(config.ENDPOINT .."/fromnode",gpio.read(5)..gpio.read(6)..gpio.read(7)..gpio.read(8),0,1)
    print("Published the status")
end

local function set_ping(payload)
    gpio.write(IO_LED, payload['stusts'])
    m:publish(config.ENDPOINT .."/fromnode", 'set_LED:'..gpio.read(5),0,1)
    print("Published the status")
end

local function consume_data( payload )
  --do someting with the payload and send responce
    if(payload['type'] == 'set') then
        set_ping(payload);
    else
        send_ping()
    end
end
-- Sends my id to the broker for registration
local function register_myself()
    m:subscribe(config.ENDPOINT .. "/tonode",0,function(conn)
        print("Successfully subscribed to data endpoint")
        send_ping()
    end)
end

local function mqtt_start()
    m = mqtt.Client(config.ID, 120,config.USERNAME,config.PASSWORD)
    -- register message callback beforehand
    m:on("message", function(conn, topic, data)
      if data ~= nil then
        print(topic .. ": " .. data)
        local tabe1 = sjson.decode(data)
        consume_data(tabe1)
      end
    end)
    -- Connect to broker
    m:connect(config.HOST, config.PORT, 0, 1, function(con)
        register_myself()
    end)

end
mqtt_start()
