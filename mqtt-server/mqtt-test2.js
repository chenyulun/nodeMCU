const mqtt = require('mqtt');

const client = mqtt.connect({
    host: '127.0.0.1',
    port: 1883,
    clientId: 'esp8266ex',
    username: 'chenlilan',
    password: Buffer.from('12345678')
});

client.on('connect', () => {
    console.log("connect!")
    client.subscribe('/nodemcu/1520350/fromnode');
    client.publish('/nodemcu/1520350/tonode', JSON.stringify({type:'set', num: 1, stusts: 0}))
});

client.on('message', (topic, message) => {
    console.log('topic:', topic);
    console.log('getMessage:', message.toString());
    // client.end();
});
