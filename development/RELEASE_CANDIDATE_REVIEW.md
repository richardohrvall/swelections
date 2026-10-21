# Release candidate review: package 0.4.0 / data-v0.4.0

Final scope approved on 21 October 2026: 190 Parquet assets and 12 manifests. No tag, push or GitHub publication is authorized in this step. This report supersedes earlier 188-asset planning counts; their original findings remain historical evidence.

| Product | Parquet assets | Approved canonical functions |
| --- | ---: | --- |
| RKL 2002 | 14 | results, seats, candidates, elected, substitutes, preference_votes |
| RKL 2006 | 15 | all seven main functions |
| RKL 2010 | 24 | all seven main functions |
| RKL 2014 | 25 | all seven + mandate_history, members_at, vacant_seats_at |
| RKL 2018 | 21 | all seven + mandate_history, members_at, vacant_seats_at |
| RKL 2022 | 24 | all seven; mandate history remains remote |
| Referendum 2003 | 1 | results only |
| EU 2004 | 14 | all seven main functions |
| EU 2009 | 8 | all seven except preference_votes |
| EU 2014 | 14 | all seven main functions |
| EU 2019 | 15 | all seven main functions |
| EU 2024 | 15 | all seven main functions |

The twelve products are the only activated ordinary-election entries. Permission comes from the central function list as well as the activation flag; a private full manifest cannot expand it. Auto never chooses a user local archive. Explicit canonical still requires actual manifest coverage. Newer supported elections without canonical use remote. EU 2009 preference votes require explicit local input; all six preference bases remain excluded.

The two history assets are shared interval populations, not duplicated member and vacancy tables. 2022 history remains remote with verified source-date limits. There is no 2022 history asset and no new mandate-period identity rule.

The corrected RKL 2018 generation uses schema 3, value/storage contract 1/1 and the Ragunda correction. The old published data-v0.1.0 generation is not the active target and is not overwritten. No preliminary 2018 data are fabricated.

Remote raw files are cached only with current official MD5-index verification, separate from canonical storage and user archives. Unindexed candidate/member CSVs remain fresh remote requests. No parsed/result persistence has been added.

Pre-commit review verifies all 202 inventory checksums and unique filenames/URLs; twelve portable manifests; approved history/EU 2009 subsets; no absolute machine paths in distribution JSON; no tracked local raw files, Python, Parquet, Stata, research crosswalk or exploratory notebook. Small tracked extdata lookups/test fixtures and source inventory/checksum CSVs remain intentional public reproducibility material.

Release documentation fixes are confined to already approved behavior: language values, canonical-first selection, history source routing, remote cache, the 190/12 scope, and package version 0.4.0. The metadata validator now checks that the copied dirty flag equals its input rather than requiring the earlier dirty review state. No election-data decision changes.

After the release-candidate commit, rebuild into new ignored output directories using the committed production builders and pinned sources. Compare every in-scope Parquet hash with the approved upload inventory; stop at the first difference. Current-build commit/time/code hashes and dirty=false necessarily change manifest checksums; those provenance changes are expected and must be checked separately. Original source manifests and reviewed prototypes remain unchanged.

Then prepare the portable 190+12 distribution, validate all source/asset/checksum/schema/round-trip metadata, run the full normal-auto and explicit-canonical API matrix with real local HTTP transport standing in for unpublished GitHub assets, and run all tests and R CMD check. This transport substitution does not change registry flags or sources. No public live URLs can be certified before publication.

Validation results and the final clean build receipt will remain under an ignored final-release audit directory and be reported after the commit. No post-commit data edits, manifest stamping, manual corrections or new source decisions are permitted; any discrepancy stops the release process.

Known source limitations remain in the completeness/readiness reports, including 2002 candidacy/source gaps and aggregate preferences, 2006 source-observation identity and preference controls, unreported 2010 preliminary units, historical source missingness, EU 2004 aggregate handwritten votes, EU 2009 open 91/34/102 questions, EU 2014 handwritten votes without a reported designation, and EU 2024 candidate 1203 snapshot differences.

The tracked CANONICAL_RELEASE_UPLOADS.csv freezes the approved working-tree reference. Clean manifest checksums will necessarily differ because build commit/time/status and source-manifest identities change. The release-preparation command generates the final upload-inventory.csv beside the clean distribution; that generated receipt is not written back into tracked files during the clean rebuild. Parquet hashes must remain identical to the tracked reference.
