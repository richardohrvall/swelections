"""Read-only trace of area/district arithmetic differences to preserved JSON."""
import json
from pathlib import Path
from collections import defaultdict

root = Path('.local-data/rkl/2022/valresultat/filer')
report_dir = Path('.local-data/canonical-build')
audit = json.loads((report_dir / '2022-aggregate-audit.json').read_text(encoding='utf-8'))
differences = audit[0]['differences']
targets = {(x['preference_vote_area_code'], x['party_code'], x['candidate_number']) for x in differences}

def parties(value):
    if isinstance(value, dict):
        if 'partikod' in value and 'listRoster' in value:
            yield value
        else:
            for child in value.values():
                yield from parties(child)
    elif isinstance(value, list):
        for child in value:
            yield from parties(child)

observed = {'area': defaultdict(list), 'district': defaultdict(list)}
party_records = {'area': defaultdict(list), 'district': defaultdict(list)}
target_parties = {(area, party) for area, party, candidate in targets}
area_names = {}
target_lists = set()
list_records = {'area': defaultdict(list), 'district': defaultdict(list)}
metadata = {}
for kind, level in [('mandatfordelning', 'area'), ('rostfordelning', 'district')]:
    file = root / f'Val_20220911_slutlig_{kind}_00_RD.json'
    raw = json.loads(file.read_text(encoding='utf-8-sig'))
    metadata[level] = {key: raw.get(key) for key in
        ['senasteUppdateringstid', 'antalUppdateringar']}
    owner = raw['valomrade'] if level == 'area' else raw
    metadata[level].update({key: owner.get(key) for key in
        ['antalValdistriktRaknade', 'antalValdistriktSomSkaRaknas']})
    nodes = raw['valomrade']['valkretsLista'] if level == 'area' else raw['valdistrikt']
    for node in nodes:
        area = str(node['kod'] if level == 'area' else node['kretskod'])
        if level == 'area':
            area_names[area] = node['namnValkrets']
        for party in parties(node['rostfordelning']):
            party_key = (area, str(party['partikod']))
            if party_key in target_parties:
                party_records[level][party_key].append(dict(
                    votes=party.get('antalRoster'),
                    district_code=node.get('valdistriktskod')))
            for ballot in party.get('listRoster') or []:
                list_key = (area, str(party['partikod']), ballot['listnummer'])
                persons = ballot.get('personroster') or []
                if level == 'area' and any((area, str(party['partikod']),
                    str(p['kandidatNummer'])) in targets for p in persons):
                    target_lists.add(list_key)
                if list_key in target_lists:
                    list_records[level][list_key].append(dict(
                        votes=ballot['antalRoster'],
                        votes_with_preference=ballot['antalRosterMedPersonrost'],
                        identified_candidate_votes=sum(p['antalPersonroster'] for p in persons)))
                for person in ballot.get('personroster') or []:
                    key = (area, str(party['partikod']), str(person['kandidatNummer']))
                    if key in targets:
                        observed[level][key].append(dict(
                            list_number=ballot['listnummer'], name=person['namn'],
                            votes=person['antalPersonroster'],
                            ballot_order=person.get('kandidatNummerPaListan'),
                            district_code=node.get('valdistriktskod'),
                            district_type=node.get('valdistriktstyp')))
    del raw

traces = []
for row in differences:
    key = (row['preference_vote_area_code'], row['party_code'], row['candidate_number'])
    trace = dict(row,
        preference_vote_area_name=area_names[key[0]],
        raw_area_list_sum=sum(x['votes'] for x in observed['area'][key]),
        raw_district_list_sum=sum(x['votes'] for x in observed['district'][key]),
        area_party_records=party_records['area'][key[:2]],
        district_party_records_count=len(party_records['district'][key[:2]]),
        observed_district_party_votes=sum(x['votes'] or 0 for x in party_records['district'][key[:2]]),
        area_posts=observed['area'][key], district_posts=observed['district'][key])
    assert trace['raw_area_list_sum'] == row['preference_votes']
    assert trace['raw_district_list_sum'] == row['district_sum']
    trace['list_checks'] = []
    for list_number in sorted({p['list_number'] for p in observed['area'][key]}):
        list_key = key[:2] + (list_number,)
        trace['list_checks'].append(dict(list_number=list_number,
            area=list_records['area'][list_key],
            district_totals={field: sum(p[field] for p in list_records['district'][list_key])
                for field in ['votes', 'votes_with_preference', 'identified_candidate_votes']}))
    traces.append(trace)
result = dict(metadata=metadata, differences=traces,
    count=len(traces), excess_area_votes=sum(x['raw_area_list_sum']-x['raw_district_list_sum'] for x in traces))
result['within_list_counter_differences'] = [dict(level=level, key=key, record=post)
    for level, records in list_records.items() for key, posts in records.items()
    for post in posts if post['votes_with_preference'] != post['identified_candidate_votes']]
(report_dir / '2022-rd-person-vote-source-traces.json').write_text(
    json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(dict(count=result['count'], excess_area_votes=result['excess_area_votes'],
    within_list_counter_differences=len(result['within_list_counter_differences']),
    conclusion='All differences reproduced directly from raw list personroster, without the package parser')))
