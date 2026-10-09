"""Assess preliminary-page information, without inferring candidate totals."""
import collections,json,re,hashlib
from pathlib import Path
from urllib.parse import urljoin
from lxml import html
p=Path('.local-data/rkl/2010/valresultat/preliminary-collection-preservation-20261009')
rows=[json.loads(r) for r in (p/'retrieval.jsonl').read_text(encoding='utf-8').splitlines()]
rows=[r for r in rows if r.get('status')==200 and r.get('valid_result_page')]
counts=collections.Counter(); examples=[]
for r in rows:
 doc=html.fromstring((p/r['relative']).read_bytes())
 links=[urljoin(r['url'],a.get('href')) for a in doc.xpath('//a[@href]') if a.text_content().strip()=='Personröster']
 counts['pages']+=1
 counts['pages_'+r['role']]+=1
 counts['preference_links_to_final']+=int(bool(links) and all('/slutresultat/' in u for u in links))
 counts['preference_links_to_preliminary']+=int(any('/prelresultat/' in u for u in links))
 headers=[c.text_content().lower() for c in doc.xpath('//table//th')]
 counts['candidate_specific_table_headers']+=int(any('kandidat' in x or 'personröst' in x for x in headers))
 counts['candidate_id_fields']+=int(b'KANDNR' in (p/r['relative']).read_bytes())
 if len(examples)<3 and not any(e['election']==r['election'] for e in examples):
  examples.append(dict(election=r['election'],source=r['url'],role=r['role'],preference_vote_links=links))
report=dict(counts=dict(counts),examples=examples,assessment='Preliminary vote pages contain party/category results, not candidate-identified preference votes. Their preference-vote navigation targets final-result pages. They do not by themselves establish a final candidate total or completeness. No candidate missing value is replaced.')
(p/'candidate-information-assessment.json').write_text(json.dumps(report,indent=2,ensure_ascii=False),encoding='utf-8')
print(json.dumps(report,ensure_ascii=False,indent=2))
