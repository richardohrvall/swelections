"""Independent, read-only XML/SKV and relationship validation (development only)."""
import csv,collections,hashlib,json,zipfile,re
from pathlib import Path
from lxml import etree
root=Path('.local-data/rkl/2010');z=zipfile.ZipFile(root/'valresultat/slutresultat.zip')
outputs=json.load(open('.local-data/2010-independent-outputs.json',encoding='utf-8'));report={}
original=json.load(open('development/2010_SOURCE_INVENTORY.json',encoding='utf-8'))
for row in original:
 b=Path(row['file']).read_bytes()
 assert hashlib.md5(b).hexdigest()==row['md5'] and hashlib.sha256(b).hexdigest()==row['sha256'],row['file']
for v,letter in [('RD','R'),('RF','L'),('KF','K')]:
 elected=[];substitutes=[];districts={};area_votes=collections.Counter();areas_person=0;unfilled=0
 for member in z.namelist():
  if not member.endswith(letter+'.xml'):continue
  doc=etree.fromstring(z.read(member));municipal=len(member.split('_')[1])==9
  if municipal:
   for d in doc.xpath('.//VALDISTRIKT|.//ONSDAGSDISTRIKT'):
    raw_code=d.get('KOD')
    collection=re.fullmatch(r'[RLK]-(\d{4})-(\d{2})',raw_code)
    code=collection.group(1)+'00'+collection.group(2) if collection else raw_code
    assert code not in districts,(v,'duplicate district key',code)
    districts[code]=d
  selected=municipal if v=='KF' else not municipal
  if not selected:continue
  path='.//KRETS_KOMMUN' if v=='KF' else './/KRETS_RIKSDAG' if v=='RD' else './/KRETS_LANDSTING'
  for area in doc.xpath(path):
   code=area.get('KOD');parent='00' if v=='RD' else code[:2] if v=='RF' else code[:4]
   constituency=None if v!='RD' and code.endswith('00') else code
   for party in area.xpath('./GILTIGA|./ÖVRIGA_GILTIGA/GILTIGA'):
    lists=party.xpath('./VALSEDEL|./PARTISEDEL');codes={n.get('LISTNUMMER')[:4] for n in lists}
    pc=next(iter(codes)) if len(codes)==1 else party.get('PARTI') if party.get('PARTI','').isdigit() else None
    for p in party.xpath('./PERSONVAL'):
     ident=p.get('KANDNR');ident='442089' if v=='RF' and ident=='451964' else ident
     assert pc is not None,(v,code,party.get('PARTI'))
     area_votes[(parent,code if constituency else parent,pc,ident)]+=int(p.get('PERSONKRYSS'))
    for group in party.xpath('./GRUPP_VALDA'):
     for candidate in group.xpath('./VALD'):
      ident=candidate.get('KANDNR')
      if not ident:unfilled+=1;continue
      elected.append((ident,pc,parent,constituency,int(candidate.get('ORDNING')),candidate.get('GRUND'),group.get('ORDNING')))
      for sub in group.xpath('./ERSÄTTARE'):
       substitutes.append((ident,sub.get('KANDNR'),pc,parent,constituency,int(sub.get('ORDNING')),group.get('ORDNING')))
 actual=outputs[v]
 actual_e=[(r['kandidatnummer'],r['partikod'],r['invald_valomradeskod'],r['invald_valkretskod'],r['invalsordning'],r['valgrund_id'],r['ersattargrupp']) for r in actual['elected_data']]
 assert collections.Counter(elected)==collections.Counter(actual_e),(v,'elected relationship difference')
 actual_s=[(r['ledamot_kandidatnummer'],r['ersattare_kandidatnummer'],r['partikod'],r['valomradeskod'],r['valkretskod'],r['ersattarordning'],r['ersattargrupp']) for r in actual['substitute_data']]
 assert collections.Counter(substitutes)==collections.Counter(actual_s),(v,'substitute difference')
 actual_votes={(r['valomradeskod'],r['personvalsomradeskod'],r['partikod'],r['kandidatnummer']):r['antal_personroster'] for r in actual['area_votes']}
 assert dict(area_votes)==actual_votes,(v,'area candidate preference-vote difference')
 file=root/'valresultat'/('slutligt_valresultat_valdistrikt_'+letter+('_antal' if v=='KF' else '')+'.skv')
 checked=missing=0;rowcount=0;differences=[]
 with file.open(encoding='latin1') as f:
  reader=csv.reader(f,delimiter=';');header=next(reader)
  for row in reader:
   if not row:continue
   rowcount+=1;district_key='00'+row[2][2:] if row[2].startswith('VK') else row[2].zfill(4)
   code=row[0].zfill(2)+row[1].zfill(2)+district_key
   if code not in districts:
    differences.append({'district':code,'issue':'SKV district absent from XML'});continue
   d=districts[code]
   for field,value in zip(header[6:],row[6:]):
    if not value.strip():continue
    if v!='KF' and not field.endswith(' tal'):continue
    alias=field[:-4] if field.endswith(' tal') else field
    if alias in ('OVR','ÖVR','BL','BLANK','OG') or field in ('Rost Giltiga','Rostande','Rostb','VDT'):continue
    if not value.strip().isdigit():continue
    if alias.isdigit():alias=alias.zfill(4)
    nodes=d.xpath('./GILTIGA[@PARTI=$alias]|./ÖVRIGA_GILTIGA/GILTIGA[@PARTI=$alias]',alias=alias)
    if not nodes:
     if int(value)==0:missing+=1;continue
     differences.append({'district':code,'party':alias,'SKV':int(value),'XML':None});continue
    assert len(nodes)==1,(v,code,alias)
    actual_value=int(nodes[0].get('RÖSTER'))
    if actual_value!=int(value):
     differences.append({'district':code,'party':alias,'SKV':int(value),'XML':actual_value})
    checked+=1
 report[v]={k:actual[k] for k in ('ballot_rows','population_rows','candidates','elected','substitutes','positive','zero','missing','preference_votes')}
 report[v].update(unfilled=unfilled,independent_elected=len(elected),independent_substitute_relations=len(substitutes),district_skv_rows=rowcount,district_party_comparisons=checked,skv_zero_without_xml_party=missing,skv_differences=differences)
 assert sum(area_votes.values())==actual['preference_votes']
 print(v,{k:val for k,val in report[v].items() if k!='skv_differences'},'differences',len(differences),flush=True)
# Fixed-mandate calculation tables are independent of the result parser.
for v,letter,kind,path in [('RD','R','ri','.//KRETS_RIKSDAG'),('RF','L','lf','.//KRETS_LANDSTING'),('KF','K','kf','.//KRETS_KOMMUN')]:
 fixed={}
 for member in z.namelist():
  if not member.endswith(letter+'.xml'):continue
  if v!='KF' and member!='slutresultat_00'+letter+'.xml':continue
  if v=='KF' and member=='slutresultat_00K.xml':continue
  doc=etree.fromstring(z.read(member))
  for area in doc.xpath(path):
   parties=area.xpath('./GILTIGA|./ÖVRIGA_GILTIGA/GILTIGA')
   fixed[area.get('KOD')]=(area.get('NAMN'),sum(int(p.get('MANDAT','0'))-int(p.get('VARAV_UTJÄMNING','0')) for p in parties))
 with (root/'kandidater'/('fastamandat_'+kind+'.csv')).open(encoding='utf-8') as f:
  rows=[r for r in csv.reader(f,delimiter=';') if r]
 for row in rows:
  if v=='RD':
   # This independent table has only the official constituency name, no code.
   codes=[code for code,value in fixed.items() if value[0]==row[0]]
   assert len(codes)==1,row
   code=codes[0]
  else:code=(row[2] if v=='KF' else row[0])+row[4 if v=='KF' else 3].zfill(2)
  assert fixed[code][1]==int(row[-1]),(v,code,row,fixed[code])
 report[v]['independent_fixed_mandate_rows']=len(rows)
 assert not report[v]['skv_differences'],(v,'independent SKV differences',report[v]['skv_differences'])
# Optional readxl export: independent mandate Excel snapshots include the
# 2011 re-election scopes and cannot redefine the ordinary 2010 XML result.
excel_path=Path('.local-data/2010-mandate-excel.json')
if excel_path.exists():
 excel=json.load(excel_path.open(encoding='utf-8'));excel_report={}
 for v,letter,path in [('RD','R','.//KRETS_RIKSDAG'),('RF','L','.//KRETS_LANDSTING'),('KF','K','.//KRETS_KOMMUN')]:
  areas={}
  for member in z.namelist():
   if not member.endswith(letter+'.xml'):continue
   if v!='KF' and member!='slutresultat_00'+letter+'.xml':continue
   if v=='KF' and member=='slutresultat_00K.xml':continue
   for area in etree.fromstring(z.read(member)).xpath(path):areas[area.get('KOD')]=area
  header=excel[v]['header'];differences=[];checked=0
  for row in excel[v]['rows']:
   code=row[0].zfill(2)+row[1].zfill(2)+(row[2].zfill(2) if v=='KF' else '')
   assert code in areas,(v,code)
   start=7 if v=='KF' else 5
   for field,value in zip(header[start:],row[start:]):
    if value is None:continue
    adjustment=field.endswith(' utj');alias=field[:-4] if adjustment else field
    nodes=areas[code].xpath('./GILTIGA[@PARTI=$alias]|./ÖVRIGA_GILTIGA/GILTIGA[@PARTI=$alias]',alias=alias)
    actual=0
    if len(nodes)==1:
     total=int(nodes[0].get('MANDAT','0'));adjust=int(nodes[0].get('VARAV_UTJÄMNING','0'))
     actual=adjust if adjustment else total-(adjust if v!='KF' else 0)
    if actual!=int(value):differences.append(dict(area=code,party_field=field,Excel=int(value),XML=actual))
    checked+=1
  assert all((v=='RF' and d['area'].startswith('14')) or (v=='KF' and d['area']=='188004') for d in differences),(v,differences)
  excel_report[v]=dict(rows=len(excel[v]['rows']),mandate_cells=checked,differences=differences,
   classification='Later re-election scope: RF Vastra Gotaland and KF Orebro nordost; validation only')
 report['mandate_excel']=excel_report
report['raw_integrity']={'original_files':len(original),'modified':0}
report['scb']={'RD_preference_votes':1494924,'RF_preference_votes':1422296,'KF_preference_votes':1848627,'RD_matches':report['RD']['preference_votes']==1494924,'RF_matches':report['RF']['preference_votes']==1422296,'KF_matches':report['KF']['preference_votes']==1848627,'sources':['https://www.scb.se/contentassets/b485269e93864392b0640b8b8c6b1c28/me0104_2010a01_br_me01br1101.pdf','https://www.scb.se/contentassets/a00250031a1543a4ae0512101861df9b/me0104_2010a01_br_me02br1101.pdf','https://www.scb.se/contentassets/35b0b096633d414e818d0bac3d02d396/me0104_2010a01_br_me03br1101.pdf'],'note':'Ordinary 2010 election tables; 2011 re-election tables are excluded.'}
assert report['scb']['RD_matches'] and report['scb']['RF_matches'] and report['scb']['KF_matches']
with open('.local-data/2010-source-validation.json','w',encoding='utf-8') as f:json.dump(report,f,ensure_ascii=False,indent=2)
