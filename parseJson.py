import sys, json; 
curl="{\"name\": \"hey\"}";
#sys.stdin

#print(json.load(curl)['name']);
print(json.loads(curl)['name']);
