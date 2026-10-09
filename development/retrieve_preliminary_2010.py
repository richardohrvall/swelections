"""Development-only preservation of official preliminary presentation pages.
No Python runtime is used by the R package. Existing source files are not overwritten.
"""
import concurrent.futures, datetime, hashlib, json, time, urllib.request, zipfile
from pathlib import Path
from lxml import etree
root = Path('.local-data/rkl/2010/valresultat')
out = root / 'preliminary-presentation-20261008'
out.mkdir(exist_ok=True)
z = zipfile.ZipFile(root / 'slutresultat.zip')
base = 'https://historik.val.se/val/val2010/prelresultat/'
jobs = {}
for member in z.namelist():
    if not member.endswith('.xml'): continue
    v = member[-5]; doc = etree.fromstring(z.read(member))
    jobs[v+'/rike/index.html'] = 'national'
    for node in doc.xpath('.//ONSDAGSDISTRIKT'):
        c = node.get('KOD').replace('-', '')
        jobs[v+'/onsdagsdistrikt/'+c[:2]+'/'+c[2:4]+'/'+c[4:6]+'/index.html'] = 'collection_district'
    for node in doc.xpath('.//KOMMUN'):
        c=node.get('KOD'); jobs[v+'/kommun/'+c[:2]+'/'+c[2:4]+'/index.html']='municipality'
    for node in doc.xpath('.//KRETS_KOMMUN'):
        c=node.get('KOD'); jobs[v+'/kvalkrets/'+c[:2]+'/'+c[2:4]+'/'+c[4:6]+'/index.html']='municipal_constituency'
    for node in doc.xpath('.//KRETS_RIKSDAG'):
        c=node.get('KOD'); jobs[v+'/rvalkrets/'+c[2:4]+'/index.html']='constituency'
    for node in doc.xpath('.//KRETS_LANDSTING'):
        c=node.get('KOD'); jobs[v+'/lvalkrets/'+c[:2]+'/'+c[2:4]+'/index.html']='regional_constituency'
    for node in doc.xpath('.//LÄN'):
        c=node.get('KOD'); jobs[v+'/lan/'+c+'/index.html']='county'
def fetch(item):
    relative,role=item; file=out/relative; url=base+relative
    last=None
    for attempt in range(3):
        try:
            if file.exists(): data=file.read_bytes()
            else:
                with urllib.request.urlopen(url, timeout=120) as r: data=r.read()
                if not data: raise ValueError('Empty source')
                html=etree.HTML(data)
                if not html.xpath('//table[contains(@class,"sorteringsbar_tabell")]'): raise ValueError('No result table')
                file.parent.mkdir(parents=True,exist_ok=True)
                with file.open('xb') as f: f.write(data)
            return dict(file=relative,url=url,role=role,bytes=len(data),md5=hashlib.md5(data).hexdigest(),sha256=hashlib.sha256(data).hexdigest(),retrieved_at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
        except Exception as e:
            last=str(e)
            if 'HTTP Error 4' in last: break
            time.sleep(attempt+1)
    return dict(url=url,role=role,error=last)
rows=[]
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
    for i,row in enumerate(pool.map(fetch, sorted(jobs.items()))):
        rows.append(row)
        if i%100==0: print(i+1,'/',len(jobs),flush=True)
manifest={'election_year':2010,'source':'Official Valmyndigheten preliminary historical presentation','sources':[r for r in rows if 'error' not in r],'failures':[r for r in rows if 'error' in r]}
with (out/'source-manifest.json').open('x',encoding='utf-8') as f: json.dump(manifest,f,ensure_ascii=False,indent=2)
print('FINISHED',len(manifest['sources']),'failures',len(manifest['failures']),flush=True)
