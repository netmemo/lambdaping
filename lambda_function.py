#import json
import urllib3

print('Loading function')


def lambda_handler(event, context):
    #print("Received event: " + json.dumps(event, indent=2))
#    print("value1 = " + event['key1'])
#    print("value2 = " + event['key2'])
#    print("value3 = " + event['key3'])

    http = urllib3.PoolManager()
    resp = http.request("GET", "http://172.31.0.8")
    print(resp.data)

#    return event['key1']  # Echo back the first key value
    #raise Exception('Something went wrong')

