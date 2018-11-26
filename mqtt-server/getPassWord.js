var hasher = require("pbkdf2-password")();
var opts = {
    password: "12345678"
};
hasher(opts, console.log)