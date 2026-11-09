"""Write the documented literal API-v1 wire examples into both repositories."""
import copy,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
APP=Path('C:/Users/josep/Downloads/dioramaapp')
base={
 'apiVersion':1,'bootId':'a1b2c3d4','revision':10,'uptimeMs':5000,'mode':'manual',
 'app':{'online':True},'slave':{'connected':True,'fresh':True,'ageMs':20},
 'sensors':{'fresh':True,'color':'RED','ir':False,'joyY':2048,'sound':{'sequence':0,'lastTriggerAgeMs':None,'detected':False}},
 'outputs':{'fountain':{'enabled':False,'color':'NONE'},'building':{'enabled':False},'rgb':{'enabled':False,'effect':'cycle'},'relays':{'known':True,'desired':0,'confirmed':0,'pending':False}},
 'audio':{'ready':True,'requested':False,'state':'stopped','trackId':None,'volumePercent':83,'completionSequence':0,'lastError':None},
 'combined':{'state':'off'},'motor':{'direction':'stopped','owner':'none','leaseRemainingMs':0,'sequence':0,'positionPercent':None},
 'capabilities':{'wifi':True,'bluetooth':False,'flagApp':True,'flagPosition':False,'audioPause':True,'audioVolume':True,'autoNarration':False,'phonePlayback':False,'tracks':[{'id':1,'title':'Track 1'},{'id':2,'title':'Track 2'}]},
 'logs':[{'sequence':1,'code':0,'message':'Boot'}]}
fixtures={'status_manual.json':base}
auto=copy.deepcopy(base);auto['mode']='automatic';auto['outputs']['fountain']={'enabled':True,'color':'RED'};fixtures['status_auto.json']=auto
offline=copy.deepcopy(base);offline['slave']={'connected':False,'fresh':False,'ageMs':None};offline['sensors']={'fresh':False,'color':None,'ir':None,'joyY':None,'sound':{'sequence':0,'lastTriggerAgeMs':None,'detected':None}};offline['outputs']['relays']['known']=False;offline['outputs']['relays']['confirmed']=None;fixtures['status_slave_offline.json']=offline
pulse=copy.deepcopy(auto);pulse['sensors']['sound']={'sequence':3,'lastTriggerAgeMs':750,'detected':True};pulse['outputs']['building']['enabled']=True;fixtures['status_sound_pulse.json']=pulse
paused=copy.deepcopy(base);paused['audio'].update(state='paused',trackId=1);fixtures['status_audio_paused.json']=paused
boot=copy.deepcopy(base);boot['bootId']='12345678';boot['revision']=0;fixtures['status_boot_changed.json']=boot
fixtures['request_light_on.json']={'id':'phone_1','bootId':'a1b2c3d4','action':'light.set','args':{'target':'fountain','enabled':True}}
fixtures['request_flag_move.json']={'id':'phone_2','bootId':'a1b2c3d4','action':'flag.move','args':{'leaseId':'gesture_1','sequence':1,'direction':'raising'}}
for state,reason,finished in [('pending',None,None),('applied',None,5010),('failed','MODE_REJECTED',5010)]:
 fixtures['result_'+state+'.json']={'apiVersion':1,'bootId':'a1b2c3d4','id':'phone_1','status':state,'reason':reason,'acceptedAtMs':5000,'finishedAtMs':finished}
fixtures['error_mode.json']={'apiVersion':1,'error':{'code':'MODE_REJECTED','message':'Switch to manual mode'}}
for root in (ROOT/'tests/fixtures/wifi_api',APP/'test/fixtures/wifi_api'):
 root.mkdir(parents=True,exist_ok=True)
 for name,value in fixtures.items(): (root/name).write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')
print(f'Wrote {len(fixtures)} fixtures to both projects')
