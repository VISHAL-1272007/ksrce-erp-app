import urllib.request, urllib.error, json

url = "https://ksrce-erp-app.onrender.com/admin/create-admin"
data = json.dumps({
    "secret": "ksrce-seed-2024",
    "email": "admin@ksrce.ac.in",
    "password": "Admin@1234",
    "name": "Admin"
}).encode("utf-8")

req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"}, method="POST")
try:
    with urllib.request.urlopen(req, timeout=30) as resp:
        print("SUCCESS:", resp.read().decode())
except urllib.error.HTTPError as e:
    print("HTTP Error", e.code, e.read().decode())
except Exception as ex:
    print("Error:", ex)
