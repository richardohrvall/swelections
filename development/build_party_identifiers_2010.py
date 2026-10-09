"""Development-only identity metadata for 2006 comparison parties in 2010 XML.
No votes or candidate identities are imported from 2006.
"""
import csv,hashlib,html,io,json,zipfile
from pathlib import Path
from lxml import etree
source=Path('.local-data/rkl/2006/valresultat/xml.zip')
z=zipfile.ZipFile(source);records=set()
for member in z.namelist():
 if not member.endswith('.zip'):continue
 nested=zipfile.ZipFile(io.BytesIO(z.read(member)))
 for name in nested.namelist():
  if not name.endswith('.xml'):continue
  d=etree.fromstring(nested.read(name));v={'R':'RD','L':'RF','K':'KF'}.get(member[-5])
  if not v:continue
  area=member[:4] if v=='KF' else member[:2] if v=='RF' else '00'
  for p in d.xpath('.//PARTI[@KOD and @BETECKNING]'):
   records.add((v,area,html.unescape(p.get('BETECKNING')),p.get('KOD')))
# Keep the literal 2010 source designation as the runtime match key.
current=zipfile.ZipFile('.local-data/rkl/2010/valresultat/slutresultat.zip');out=set()
for f in current.namelist():
 if not f.endswith('.xml'):continue
 v={'R':'RD','L':'RF','K':'KF'}[f[-5]];c=f.split('_')[1][:-5]
 area=c if v=='KF' and len(c)==4 else c[:2] if v=='RF' and len(c)==4 else '00'
 parser=etree.XMLPullParser(events=('start',))
 with current.open(f) as stream:
  done=False
  while not done:
   data=stream.read(8192)
   if not data:break
   parser.feed(data)
   for _,n in parser.read_events():
    if n.tag=='PARTI':
     label=n.get('BETECKNING');codes={r[3] for r in records if r[:3]==(v,area,html.unescape(label))}
     if len(codes)==1:out.add((v,area,label,next(iter(codes))))
    if n.tag in ('NATION','KOMMUN'):done=True;break
folder=Path('.local-data/rkl/2010/kandidater/official-party-identifiers');folder.mkdir(exist_ok=True)
target=folder/'previous-election-2006.csv'
with target.open('x',encoding='utf-8',newline='') as f:
 w=csv.writer(f);w.writerow(['valtyp','valomradeskod','partibeteckning','partikod']);w.writerows(sorted(out))
b=source.read_bytes();p={'purpose':'Party IDs only for prior-election comparison rows; no 2006 votes/candidates', 'source':str(source),'source_md5':hashlib.md5(b).hexdigest(),'source_sha256':hashlib.sha256(b).hexdigest(),'output_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'rows':len(out),'matching':'Exact election/area and source party designation (HTML entities decoded only for matching)'}
with (folder/'provenance.json').open('x',encoding='utf-8') as f:json.dump(p,f,ensure_ascii=False,indent=2)
print('party metadata rows',len(out))
