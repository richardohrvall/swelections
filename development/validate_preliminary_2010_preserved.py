"""Read-only source reconstruction audit; no canonical/public output is written."""
import collections, hashlib, json, re, zipfile
from pathlib import Path
from lxml import etree, html
ROOT=Path('.local-data/rkl/2010/valresultat')
SNAP=ROOT/'preliminary-collection-preservation-20261009'
COMMON={'M','C','FP','KD','S','V','MP','SD'}
expect=json.loads((SNAP/'expected-sources.json').read_text(encoding='utf-8'))
OLD=ROOT/'preliminary-presentation-20261008'
old_sources={r['url']:r for r in json.loads((OLD/'source-manifest.json').read_text(encoding='utf-8'))['sources']}
for r in old_sources.values():
 if r['role']=='municipal_constituency':
  m=re.search(r'/([RLK])/kvalkrets/([0-9]{2})/([0-9]{2})/([0-9]{2})/',r['url'])
  if m: expect.append(dict(relative=r['file'],url=r['url'],role=r['role'],election=m[1],code=m[2]+m[3]+m[4]))
records=[json.loads(s) for s in (SNAP/'retrieval.jsonl').read_text(encoding='utf-8').splitlines()]
sources={r['relative']:r for r in records if r.get('status')==200 and r.get('valid_result_page')}
for p,r in sources.items():
 b=(SNAP/p).read_bytes()
 assert len(b)==r['bytes'] and hashlib.md5(b).hexdigest()==r['md5'] and hashlib.sha256(b).hexdigest()==r['sha256']
 if r['role']=='collection_district':
  assert r['final_url']==r['url'] and '/prelresultat/' in r['final_url']
  headings=[x.text_content().lower() for x in html.fromstring(b).xpath('//h1|//h2|//h3')]
  assert any('preliminär' in x for x in headings),r['url']

def number(s):
 s=s.replace('\xa0','').replace(' ','').strip()
 return int(s) if re.fullmatch('[0-9]+',s) else None

def presentation(p):
 doc=html.fromstring(p.read_bytes()); votes=collections.Counter(); known=False
 for tr in doc.xpath('//table[contains(@class,"sorteringsbar_tabell")]//tr'):
  cells=[c.text_content().strip() for c in tr.xpath('./td')]
  if len(cells)!=8: continue
  n=number(cells[2])
  if n is None: continue
  label,desc=cells[:2]
  if desc=='Giltiga röster': votes['VALID']=n; known=True
  elif label in {'BLANK','OG','VDT'}: votes[label]=n
  elif desc=='Antal röstberättigade': votes['ELIGIBLE']=n
  elif label: votes['ÖVR' if label in {'ÖVR','ÖVRIGA'} else label]=n
 if known:
  assert sum(v for k,v in votes.items() if k not in {'VALID','BLANK','OG','VDT','ELIGIBLE'})==votes['VALID'],p
  total=votes['VALID']+votes['BLANK']+votes['OG']
  if 'VDT' in votes: assert votes['VDT']==total,p
  votes['VDT']=total
 return doc,votes,known

def xml_votes(n):
 out=collections.Counter()
 for c in n:
  if c.tag=='GILTIGA': out[c.get('PARTI')]+=int(c.get('RÖSTER'))
  elif c.tag=='ÖVRIGA_GILTIGA': out['ÖVR']+=int(c.get('RÖSTER'))
  elif c.tag=='OGILTIGA': out[c.get('TEXT')]+=int(c.get('RÖSTER'))
  elif c.tag=='VALDELTAGANDE':
   if c.get('SUMMA_RÖSTER'): out['VDT']=int(c.get('SUMMA_RÖSTER'))
   if c.get('RÖSTBERÄTTIGADE'): out['ELIGIBLE']=int(c.get('RÖSTBERÄTTIGADE'))
 if n.get('RÖSTER'): out['VALID']=int(n.get('RÖSTER'))
 return out

def coarse(counter):
 out=collections.Counter()
 for k,n in counter.items(): out[k if k in COMMON|{'VALID','BLANK','OG','VDT','ELIGIBLE'} else 'ÖVR']+=n
 return out

def overview(doc):
 for table in doc.xpath('//table[contains(@class,"sorteringsbar_tabell")]'):
  trs=table.xpath('.//tr')
  for tr in trs:
   cs=tr.xpath('./td|./th'); texts=[c.text_content().strip() for c in cs]
   if len(texts)==25 and texts[0]=='Sverige':
    labels=['M','C','FP','KD','S','V','MP','SD','ÖVR','BLANK','OG','VDT']
    out=collections.Counter({k:number(texts[2+2*i]) or 0 for i,k in enumerate(labels)})
    out['VALID']=sum(out[k] for k in COMMON|{'ÖVR'})
    return out
 return None

report={}; zf=zipfile.ZipFile(ROOT/'slutresultat.zip'); zn=zipfile.ZipFile(ROOT/'valnatt.zip')
for v in 'RLK':
 wanted=[e for e in expect if e['role']=='collection_district' and e['election']==v]
 assert len({e['code'] for e in wanted})==len(wanted)==(392 if v=='L' else 395)
 missing=[e for e in wanted if e['relative'] not in sources]
 collection=collections.Counter(); ordinary=collections.Counter(); units={}; districts=set(); unavailable=[]; rd_geography={}; comparisons=[]; differences=[]
 national=etree.fromstring(zf.read('slutresultat_00'+v+'.xml'))
 if v=='R':
  for n in national.xpath('.//KRETS_RIKSDAG'):
   for c in n.xpath('./KOMMUN'): rd_geography[c.get('KOD')]=n.get('KOD')
 for member in zn.namelist():
  match=re.fullmatch('valnatt_([0-9]{4})'+v+'[.]xml',member)
  if not match: continue
  municipal=match.group(1); doc=etree.fromstring(zn.read(member))
  # Final source is consulted for geographic codes ONLY, never vote fields.
  geo=etree.fromstring(zf.read(member.replace('valnatt_','slutresultat_')))
  for parent in doc.xpath('./KOMMUN/KRETS_KOMMUN'):
   c=parent.get('KOD'); matches=geo.xpath('./KOMMUN/KRETS_KOMMUN[@KOD="'+c+'"]')
   assert len(matches)==1
   rf=matches[0].get('KRETS_LANDSTING')
   for n in parent.xpath('./VALDISTRIKT'):
    key=n.get('KOD'); assert key not in districts; districts.add(key)
    counts=xml_votes(n)
    ordinary.update(counts)
    scopes=[('national','00'),('municipality',municipal),('municipal_constituency',c)]
    if v=='R': scopes.append(('constituency',rd_geography[municipal]))
    if v=='L': scopes += [('region',municipal[:2]),('regional_constituency',rf)]
    for scope in scopes: units.setdefault(scope,collections.Counter()).update(counts)
 for e in wanted:
  if e['relative'] not in sources: continue
  doc,counts,known=presentation(SNAP/e['relative'])
  normalized=e['municipality']+'00'+e['municipal_constituency']
  assert normalized not in districts; districts.add(normalized)
  if not known: unavailable.append(e)
  collection.update(counts)
  scopes=[('national','00'),('municipality',e['municipality']),('municipal_constituency',e['municipality']+e['municipal_constituency'])]
  if v=='R': scopes.append(('constituency',rd_geography[e['municipality']]))
  if v=='L':
   g=etree.fromstring(zf.read(e['geography_source']))
   c=e['municipality']+e['municipal_constituency']
   parent=g.xpath('./KOMMUN/KRETS_KOMMUN[@KOD="'+c+'"]')[0]
   scopes += [('region',e['municipality'][:2]),('regional_constituency',parent.get('KRETS_LANDSTING'))]
  for scope in scopes: units.setdefault(scope,collections.Counter()).update(counts)
 # No comparison is labelled complete while required collection pages are missing.
 if not missing:
  for e in expect:
   if e['election']!=v: continue
   file=SNAP/e['relative']
   if e['relative'] not in sources:
    old=old_sources.get(e['url'])
    if old is not None:
     file=OLD/old['file']; b=file.read_bytes()
     assert hashlib.md5(b).hexdigest()==old['md5'] and hashlib.sha256(b).hexdigest()==old['sha256']
    elif v=='R' and e['role']=='municipality':
     # Four entire RD constituencies are also single municipalities; the
     # presentation has the constituency page rather than a municipal alias.
     constituency=rd_geography[e['code']]
     nodes=national.xpath('.//KRETS_RIKSDAG[@KOD="'+constituency+'"]/KOMMUN')
     if len(nodes)!=1 or nodes[0].get('KOD')!=e['code']: continue
     relative='R/rvalkrets/'+constituency[2:]+'/index.html'
     if relative not in sources: continue
     file=SNAP/relative
    else: continue
   scope=(e['role'],e['code'])
   if scope not in units: continue
   doc,expected,known=presentation(file)
   actual=units[scope]
   if e['role']=='national':
    text=' '.join(doc.text_content().split())
    state=re.search(r'(?:Samtliga\s+(\d+)|(\d+)\s+av\s+(\d+))\s+valdistrikt\s+räknade',text,re.I)
    if state:
     counted=int(state[1] or state[2]); total=int(state[1] or state[3])
     assert total==len(districts) and counted==len(districts)-len(unavailable),(v,counted,total)
   if not known and e['role']=='national': expected=overview(doc); known=expected is not None
   if not known: continue
   if e['role']=='national' and v in 'LK': actual=coarse(actual)
   # Collection-page electorate is not available. Do not pretend its unknown
   # denominator is zero, or validate reconstructed electorate as complete.
   keys=set(expected)-{'ELIGIBLE'}
   delta={k:actual[k]-expected[k] for k in keys if actual[k]!=expected[k]}
   comparisons.append(dict(role=e['role'],code=e['code'],fields=len(keys),published=dict(expected),reconstructed={k:actual[k] for k in keys},source=str(file)))
   if delta: differences.append(dict(role=e['role'],code=e['code'],delta=delta,source=str(file)))
 report[v]=dict(expected_collections=len(wanted),retrieved_collections=len(wanted)-len(missing),missing_pages=missing,unreported_pages=unavailable,ordinary_districts=len(districts)-(len(wanted)-len(missing)),reported_districts=len(districts)-len(unavailable),ordinary=dict(ordinary),collection=dict(collection),combined=dict(ordinary+collection),comparison_count=len(comparisons),comparisons=comparisons,differences=differences)
 print(v,'collections',len(wanted)-len(missing),'/',len(wanted),'unreported',len(unavailable),'comparisons',len(comparisons),'differences',len(differences))
(SNAP/'validation.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
raw_inputs=[]
for name in ['valnatt.zip','slutresultat.zip']:
 p=ROOT/name; b=p.read_bytes()
 raw_inputs.append(dict(file=str(p),role='election_night_votes' if name=='valnatt.zip' else 'geography_only_no_vote_values',bytes=len(b),md5=hashlib.md5(b).hexdigest(),sha256=hashlib.sha256(b).hexdigest()))
manifest=dict(existing_validation_sources=[r for r in old_sources.values() if r['role']=='municipal_constituency'],raw_inputs=raw_inputs,election_year=2010,source='Official Valmyndigheten preliminary historical presentation',sources=[dict(r,file=r['relative']) for r in sources.values()],failures=[r for r in records if r.get('status')!=200],expected_collection_sources=[e for e in expect if e['role']=='collection_district'],retrieval_policy=dict(parallel=False,delay_seconds=1.5,timeout_seconds=90,attempts=3,rate_limit_backoff_seconds=[120,240],stop_after_rate_limits=3))
(SNAP/'source-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print('Sources',len(sources),'bytes',sum(s['bytes'] for s in sources.values()))
