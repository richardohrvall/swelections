"""Conservative, development-only preservation. No package/source rewrites.
Run from repository root; requests are sequential and successful cache is immutable.
"""
import datetime, hashlib, json, re, time, urllib.request, urllib.error, zipfile
from pathlib import Path
from lxml import etree, html
ROOT = Path('.local-data/rkl/2010/valresultat')
OUT = ROOT / 'preliminary-collection-preservation-20261009'
BASE = 'https://historik.val.se/val/val2010/prelresultat/'
DELAY = 1.5
OUT.mkdir(exist_ok=True)
records = OUT / 'retrieval.jsonl'
jobs = {}
with zipfile.ZipFile(ROOT / 'slutresultat.zip') as z:
    for member in z.namelist():
        match = re.fullmatch(r'slutresultat_([0-9]{4})([RLK])[.]xml', member)
        if not match: continue
        municipality, v = match.groups()
        doc = etree.fromstring(z.read(member))
        for node in doc.xpath('./KOMMUN/KRETS_KOMMUN/ONSDAGSDISTRIKT'):
            letter, municipal, constituency = node.get('KOD').split('-')
            assert letter == v and municipal == municipality
            rel = f'{v}/onsdagsdistrikt/{municipal[:2]}/{municipal[2:]}/{constituency}/index.html'
            assert rel not in jobs
            jobs[rel] = dict(role='collection_district', election=v, code=node.get('KOD'), municipality=municipal, municipal_constituency=constituency, geography_source=member)
        rel = f'{v}/kommun/{municipality[:2]}/{municipality[2:]}/index.html'
        jobs[rel] = dict(role='municipality', election=v, code=municipality)
    for v in 'RLK':
        jobs[f'{v}/rike/index.html'] = dict(role='national', election=v, code='00')
        d = etree.fromstring(z.read('slutresultat_00'+v+'.xml'))
        if v == 'R':
            for node in d.xpath('.//KRETS_RIKSDAG'):
                c=node.get('KOD')
                jobs[f'R/rvalkrets/{c[2:]}/index.html'] = dict(role='constituency', election=v, code=c)
        if v == 'L':
            for node in d.xpath('.//LÄN'):
                c=node.get('KOD')
                jobs[f'L/lan/{c}/index.html'] = dict(role='region', election=v, code=c)
            for node in d.xpath('.//KRETS_LANDSTING'):
                c=node.get('KOD')
                if c[2:] == '00': continue
                jobs[f'L/lvalkrets/{c[:2]}/{c[2:]}/index.html'] = dict(role='regional_constituency', election=v, code=c)
expected = [dict(relative=p,url=BASE+p,**j) for p,j in sorted(jobs.items())]
plan=OUT/'expected-sources.json'
if not plan.exists(): plan.write_text(json.dumps(expected,ensure_ascii=False,indent=2),encoding='utf-8')
else: assert json.loads(plan.read_text(encoding='utf-8')) == expected
prior = {}
old = ROOT/'preliminary-presentation-20261008'
for row in json.loads((old/'source-manifest.json').read_text(encoding='utf-8'))['sources']:
    prior[row['url']] = row
success = {}
if records.exists():
    for line in records.read_text(encoding='utf-8').splitlines():
        r=json.loads(line)
        if r.get('status') == 200 and r.get('valid_result_page'): success[r['relative']]=r

def log(row):
    with records.open('a',encoding='utf-8') as f: f.write(json.dumps(row,ensure_ascii=False)+'\n')

def valid(data, job):
    doc=html.fromstring(data)
    rows=doc.xpath('//table[contains(@class,"sorteringsbar_tabell")]//tr')
    if job['role']=='national' and job['election'] in 'LK':
        return bool(rows)
    return any(len(r.xpath('./td'))==8 for r in rows)

# Collection inventory first; no successful prior response is requested again.
ordered=sorted(jobs,key=lambda p:(jobs[p]['role']!='collection_district', p))
rate_limits=0
for i, rel in enumerate(ordered,1):
    j=jobs[rel]; file=OUT/rel; url=BASE+rel
    if rel in success:
        r=success[rel]; b=file.read_bytes()
        assert len(b)==r['bytes'] and hashlib.sha256(b).hexdigest()==r['sha256']
        continue
    if file.exists(): raise RuntimeError('Unregistered cache file: '+str(file))
    cached=prior.get(url)
    if cached:
        b=(old/cached['file']).read_bytes()
        assert hashlib.md5(b).hexdigest()==cached['md5'] and hashlib.sha256(b).hexdigest()==cached['sha256']
        file.parent.mkdir(parents=True,exist_ok=True)
        with file.open('xb') as f: f.write(b)
        row=dict(relative=rel,url=url,**j,status=200,valid_result_page=valid(b,j),bytes=len(b),md5=hashlib.md5(b).hexdigest(),sha256=hashlib.sha256(b).hexdigest(),retrieved_at_utc=cached['retrieved_at_utc'],cache_origin=str(old/cached['file']),preserved_at_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
        log(row); success[rel]=row
        continue
    for attempt in range(1,4):
        time.sleep(DELAY)
        now=datetime.datetime.now(datetime.timezone.utc).isoformat()
        req=urllib.request.Request(url,headers={'User-Agent':'swelections historical-source preservation (sequential research retrieval)'})
        try:
            with urllib.request.urlopen(req,timeout=90) as response:
                b=response.read(); headers=dict(response.headers); final=response.url; status=response.status
            if not b: raise ValueError('Empty HTTP response')
            file.parent.mkdir(parents=True,exist_ok=True)
            with file.open('xb') as f: f.write(b)
            row=dict(relative=rel,url=url,final_url=final,**j,status=status,valid_result_page=valid(b,j),bytes=len(b),md5=hashlib.md5(b).hexdigest(),sha256=hashlib.sha256(b).hexdigest(),retrieved_at_utc=now,response_headers=headers)
            log(row)
            if row['valid_result_page']: success[rel]=row
            else: print('INVALID RESULT PAGE',rel,flush=True)
            break
        except urllib.error.HTTPError as e:
            row=dict(relative=rel,url=url,**j,status=e.code,error=str(e),retrieved_at_utc=now,response_headers=dict(e.headers))
            log(row)
            if e.code == 429:
                rate_limits += 1
                if rate_limits >= 3:
                    print('STOP after three rate-limit responses; cache preserved',flush=True)
                    raise SystemExit(2)
                wait=max(120*rate_limits,int(e.headers.get('Retry-After','0')) if e.headers.get('Retry-After','0').isdigit() else 0)
                print('BACKOFF',wait,'seconds',rel,flush=True); time.sleep(wait)
            elif e.code < 500: break
            else: time.sleep(15*attempt)
        except (OSError,ValueError) as e:
            log(dict(relative=rel,url=url,**j,status=None,error=str(e),retrieved_at_utc=now))
            time.sleep(15*attempt)
    if i%25==0: print('PROGRESS',i,'/',len(ordered),'verified successes',len(success),flush=True)
print('COMPLETE retrieval',len(success),'/',len(ordered),flush=True)
