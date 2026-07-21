#!/bin/bash
curl -s -X POST https://gryphn.phys.uconn.edu/halld/token \
    --data-urlencode "vault_token=$(cat vt_u7896)" \
    --data-urlencode "min_lifetime=1200" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK' if 'bearer_token' in d else 'FAIL: '+d.get('error','unknown'))"
