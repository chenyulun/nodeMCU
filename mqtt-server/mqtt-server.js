const mosca = require('mosca');
var fs = require("fs");
var Authorizer = require("mosca/lib/authorizer");
const ascoltatore = {
    // //using ascoltatore
    // type: 'mongo',
    // url: 'mongodb://localhost:27017/mqtt',
    // pubsubCollection: 'ascoltatori',
    // mongo: {}
};

const settings = {
    port: 1883,
    stats: false,
    backend: ascoltatore,
    persistence: {
        factory: mosca.persistence.Memory
    },
    http: {
        port: 1884,
        static: __dirname + "/static",
        bundle: true
    },
    // onlyHttp: true
};

const server = new mosca.Server(settings);

server.on('clientConnected', client => {
    console.log('clien Connected', client.id);
});

server.on('published', (packet, client) => {
    console.log('Published', packet);
    console.log('Client', client);
    console.log('PublishedPayload', packet.payload);
});

server.on('clientDisconnected', function(client) {
    console.log('Client Disconnected:', client.id);
});

server.on('ready', setup);

function loadAuthorizer(credentialsFile, cb) {
    if (credentialsFile) {
        fs.readFile(credentialsFile, function (err, data) {
            if (err) {
                cb(err);
                return;
            }

            var authorizer = new Authorizer();

            try {
                authorizer.users = JSON.parse(data);
                cb(null, authorizer);
            } catch (err) {
                cb(err);
            }
        });
    } else {
        cb(null, null);
    }
}

function setup() {
    console.log('Mosca server is up and running');
    // setup authorizer
    loadAuthorizer("./credentials.json", function (err, authorizer) {
        if (err) {
            // handle error here
        }
        if (authorizer) {
            server.authenticate = authorizer.authenticate;
            server.authorizeSubscribe = authorizer.authorizeSubscribe;
            server.authorizePublish = authorizer.authorizePublish;
        }
    });
}
