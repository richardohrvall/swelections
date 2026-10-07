"""Immutable snapshot selection and derived ZIP staging, never raw overwrite.

Invoked by build-canonical-2022.R after downloading the official index and
the four approved corrected KF ZIPs. Python's stdlib provides deterministic
ZIP creation, hashes and a precisely scoped candidate-ID transformation.
"""
import hashlib
import json
from pathlib import Path
import sys
import zipfile


def digest(data, algorithm):
    return hashlib.new(algorithm, data).hexdigest()


def correct_norrbotten(raw, kind):
    assert raw['valtyp'] == 'RF' and raw['valtillfalle'] == 'Val_20220911'
    if kind == 'mandatfordelning':
        assert raw['valomrade']['kod'] == '25'
    else:
        assert all(n['valomradeskod'] == '25' for n in raw['valdistrikt'])
    changes = []

    def visit(node, path='', party=None, ballot=None):
        if isinstance(node, dict):
            party = node.get('partikod', party)
            ballot = node.get('listnummer', ballot)
            for field, value in node.items():
                child = path + '/' + field
                if field in ('kandidatNummer', 'kandidatnummer') and str(value) == '50975':
                    assert str(party) == '0110', (child, party)
                    if field == 'kandidatNummer':
                        assert str(ballot) == '0110-03652', (child, ballot)
                    node[field] = '488' if isinstance(value, str) else 488
                    changes.append(child)
                elif isinstance(value, (dict, list)):
                    visit(value, child, party, ballot)
        elif isinstance(node, list):
            for i, value in enumerate(node):
                visit(value, path + '/' + str(i), party, ballot)

    visit(raw)
    assert len(changes) == (2 if kind == 'mandatfordelning' else 95), len(changes)
    return changes


def validate_staging(source, stage, corrections):
    """Compare every staged JSON to its pinned, immutable source generation."""
    files = source / 'valresultat' / 'filer'
    counts = dict(preserved=0, corrected=0, reconstructed=0)
    for md in sorted(files.glob('Val_*_mandatfordelning_*.json')):
        _, date, count, _, area, election = md.stem.split('_')
        zip_name = f'Val_{date}_{count}_{area}_{election}.zip'
        relative = f'{"s" if count == "slutlig" else "p"}/{election.lower()}/{zip_name}'
        with zipfile.ZipFile(stage / '2022' / 'val2022' / relative) as z:
            for path in (md, files / md.name.replace('mandatfordelning', 'rostfordelning')):
                actual = z.read(path.name)
                original = path.read_bytes()
                if count == 'slutlig' and election == 'KF' and area in {'0136', '1439', '1860', '2506'}:
                    with zipfile.ZipFile(corrections / zip_name) as official:
                        assert actual == official.read(path.name), path
                    counts['corrected'] += 1
                elif count == 'slutlig' and election == 'RF' and area == '25':
                    expected = json.loads(original.decode('utf-8-sig'))
                    kind = 'mandatfordelning' if path == md else 'rostfordelning'
                    correct_norrbotten(expected, kind)
                    assert json.loads(actual) == expected, path
                    counts['reconstructed'] += 1
                else:
                    assert actual == original, path
                    counts['preserved'] += 1
    assert counts == dict(preserved=1234, corrected=8, reconstructed=2), counts
    with zipfile.ZipFile(stage / '2022' / 'val2022' / 'parti' / 'kandidaturer.zip') as z:
        assert digest(z.read('kandidaturer.csv'), 'md5') == '639daa9630a1f2554f1c6839473448ee'
    return counts


def prepare(source, stage, corrections):
    files = source / 'valresultat' / 'filer'
    candidate = source / 'kandidater' / 'kandidaturer_20241218.csv'
    assert digest(candidate.read_bytes(), 'md5') == '639daa9630a1f2554f1c6839473448ee'
    index = []
    sources = []
    transformations = []
    original = {}
    selected_corrected = {'0136', '1439', '1860', '2506'}

    def record(path, data, classification, selected, url=None):
        entry = dict(source=str(path), md5=digest(data, 'md5'),
                     sha256=digest(data, 'sha256'), bytes=len(data),
                     classification=classification, selected=selected, url=url)
        sources.append(entry)
        if Path(path).is_file():
            original[str(path)] = entry['sha256']

    for candidate_snapshot in sorted((source / 'kandidater').glob('kandidaturer*.csv')):
        record(candidate_snapshot, candidate_snapshot.read_bytes(),
               'official_historical_candidate_snapshot', candidate_snapshot == candidate)
    for md in sorted(files.glob('Val_*_mandatfordelning_*.json')):
        _, date, count, _, area, election = md.stem.split('_')
        rd = files / md.name.replace('mandatfordelning', 'rostfordelning')
        use_corrected = count == 'slutlig' and election == 'KF' and area in selected_corrected
        members = {}
        for path in (md, rd):
            data = path.read_bytes()
            record(path, data, 'preserved_official_result_snapshot', not use_corrected)
            signature = path.with_name(path.stem + '_sign.sha256')
            if signature.exists():
                record(signature, signature.read_bytes(), 'rsa_signature_not_text_checksum', False)
            kind = 'mandatfordelning' if path == md else 'rostfordelning'
            if count == 'slutlig' and election == 'RF' and area == '25':
                pin = {'mandatfordelning': 'ea31f87d4172ad787258cfe5790b4ff6',
                       'rostfordelning': '8ae8a7f37467daee7c5fcd408dcaa10b'}[kind]
                assert digest(data, 'md5') == pin
                raw = json.loads(data.decode('utf-8-sig'))
                changed = correct_norrbotten(raw, kind)
                data = json.dumps(raw, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
                transformations.append(dict(rule='RF25_Bo_Larsson_50975_to_488',
                    source=str(path), original_md5=pin, fields=changed,
                    derived_sha256=digest(data, 'sha256'),
                    decision='Lansstyrelsen Norrbotten 201-11278-2022, 2022-11-14',
                    decision_url='https://resultat.val.se/protokoll/protokoll_Val_20220911_25_RF.pdf',
                    semantics='Original election-time elected/substitute relations retained; '
                              'no subsequent mandate-period replacements incorporated.'))
            members[path.name] = data
        name = f'Val_{date}_{count}_{area}_{election}.zip'
        relative = f'{"s" if count == "slutlig" else "p"}/{election.lower()}/{name}'
        destination = stage / '2022' / 'val2022' / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        if use_corrected:
            official = corrections / name
            with zipfile.ZipFile(official) as z:
                assert set(members) <= set(z.namelist())
                members = {name: z.read(name) for name in members}
            for name2, data in members.items():
                record(name2, data, 'official_corrected_election_result', True,
                       'https://resultat.val.se/resultatfiler/val2022/' + relative)
            record(official, official.read_bytes(), 'official_zip_verified_against_index', True,
                   'https://resultat.val.se/resultatfiler/val2022/' + relative)
        # Deterministic, explicitly derived input container; no invalid signature
        # is attached to reconstructed JSON. Original signature files are retained.
        with zipfile.ZipFile(destination, 'w', compression=zipfile.ZIP_DEFLATED) as z:
            for name2, data in members.items():
                entry = zipfile.ZipInfo(name2, date_time=(2022, 9, 11, 0, 0, 0))
                entry.compress_type = zipfile.ZIP_DEFLATED
                z.writestr(entry, data)
        index.append(digest(destination.read_bytes(), 'md5') + '  ./' + relative)
    assert len(index) == 622
    (stage / '2022' / 'val2022' / 'index.md5').write_text('\n'.join(index) + '\n', encoding='utf-8')
    destination = stage / '2022' / 'val2022' / 'parti' / 'kandidaturer.zip'
    destination.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(destination, 'w', compression=zipfile.ZIP_DEFLATED) as z:
        z.writestr('kandidaturer.csv', candidate.read_bytes())
    provenance = dict(sources=sources, harmonisation=transformations,
                      original_source_sha256=original,
                      input_archive=str(stage), source_root=str(source))
    (stage / 'provenance.json').write_text(json.dumps(provenance, indent=2,
                                          ensure_ascii=False), encoding='utf-8')
    validate_staging(source, stage, corrections)
    print('Prepared 622 derived ZIP containers; original sources unchanged.')


if __name__ == '__main__':
    if sys.argv[1] == '--validate':
        print(validate_staging(*(Path(x).resolve() for x in sys.argv[2:5])))
    else:
        prepare(*(Path(x).resolve() for x in sys.argv[1:4]))
