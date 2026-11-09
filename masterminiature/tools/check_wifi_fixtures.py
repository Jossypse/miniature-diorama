import argparse
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--app-root',required=True);a=p.parse_args()
left=Path(__file__).resolve().parents[1]/'tests/fixtures/wifi_api';right=Path(a.app_root)/'test/fixtures/wifi_api'
assert {p.name for p in left.glob('*.json')}=={p.name for p in right.glob('*.json')}
for f in left.glob('*.json'): assert f.read_bytes()==(right/f.name).read_bytes(),f.name
print('PASS: shared Wi-Fi API fixtures match')
