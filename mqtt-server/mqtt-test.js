const mqtt = require('mqtt');

const client = mqtt.connect({
    host: '127.0.0.1',
    port: 1883,
    clientId: 'esp8266',
    username: 'chenyulun',
    password: Buffer.from('12345678')
});

client.on('connect', () => {
    client.subscribe('presence/chenyulun');
    client.publish('presence/chenlilan', 'hello mqtt')
});

client.on('message', (topic, message) => {
    console.log('topic:', topic);
    console.log('getMessage:', message.toString());
    // client.end();
});
