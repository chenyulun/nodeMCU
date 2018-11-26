local module = {}

module.HOST = "172.19.12.133"
module.PORT = 1883
module.USERNAME = "chenyulun"
module.PASSWORD = "12345678"
module.ID = node.chipid()

module.ENDPOINT = "/nodemcu/"..node.chipid()
return module