#!/bin/bash
# Mock JSON where the URL is on a new line or has spaces
MOCK_JSON='{
  "assets": [
    {
      "name": "Hammerspoon.zip",
      "browser_download_url" : 
          "https://github.com/fake/Hammerspoon.zip"
    }
  ]
}'
echo "Testing fragile grep parsing:"
echo "$MOCK_JSON" | grep "browser_download_url.*\.zip" | cut -d '"' -f 4 || echo "Grep failed to find it!"

echo "Testing bulletproof python parsing:"
echo "$MOCK_JSON" | python3 -c '
import json, sys
try:
    for a in json.load(sys.stdin).get("assets", []):
        if a["name"].endswith(".zip"):
            print(a.get("browser_download_url", ""))
            break
except Exception as e:
    pass
'
