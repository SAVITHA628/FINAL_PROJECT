import urllib.request
import json

url = "http://localhost:8000/api/match"

similar_payload = {
    "lostItem": {
        "itemId": "item_lost_001",
        "title": "Blue Samsung Galaxy A54",
        "description": "Lost my blue Samsung phone near library cafeteria with stickers.",
        "category": "Electronics",
        "location": "Library Cafeteria"
    },
    "foundItem": {
        "itemId": "item_found_001",
        "title": "Found Samsung Galaxy Mobile Phone",
        "description": "Blue Samsung phone found on cafeteria table near library.",
        "category": "Electronics",
        "location": "Library Cafeteria"
    }
}

different_payload = {
    "lostItem": {
        "itemId": "item_lost_002",
        "title": "Silver Maruti Car Keys",
        "description": "Car key ring with red keychain.",
        "category": "Keys",
        "location": "Central Canteen"
    },
    "foundItem": {
        "itemId": "item_found_002",
        "title": "HP Laptop Charger 65W",
        "description": "Lost HP charger in Lab 204 with red tape.",
        "category": "Electronics",
        "location": "Lab 204"
    }
}

def post(data):
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode("utf-8"),
        headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))

print("=== TEST 1: SIMILAR PAIR ===")
res1 = post(similar_payload)
print(json.dumps(res1, indent=2))

print("\n=== TEST 2: DIFFERENT PAIR ===")
res2 = post(different_payload)
print(json.dumps(res2, indent=2))
