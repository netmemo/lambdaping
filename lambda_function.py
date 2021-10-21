import urllib3

print('Loading function')

def lambda_handler(event, context):
    http = urllib3.PoolManager()
    resp = http.request("GET", "http://172.31.0.8")
    print(resp.data)
