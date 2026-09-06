from pathlib import Path
import yaml
root=Path(__file__).resolve().parents[1]
c=yaml.safe_load((root/'docker-compose.yml').read_text())
assert set(c['services'])=={'postgres','app','n8n','proxy'}
for name,s in c['services'].items():
 assert ':latest' not in s.get('image','')
 assert not any('docker.sock' in str(v) for v in s.get('volumes',[]))
 if name not in {'proxy','n8n'}:assert not s.get('ports')
 if name=='n8n':assert all(str(v).startswith('127.0.0.1:') for v in s['ports'])
 assert s.get('mem_limit') and s.get('cpus')
assert c['services']['app']['environment']['OUTBOUND_ENABLED']=='false'
assert c['services']['n8n']['environment']['N8N_SSRF_PROTECTION_ENABLED']=='true'
assert c['networks']['database']['internal'] is True
print('PASS topology: private DB, private n8n, no socket, resources and disabled outbound')
