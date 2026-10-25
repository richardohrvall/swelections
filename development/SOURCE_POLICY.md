# Official results and source reconciliation

The legally established final result and official election protocols define the
final election outcome. Valmyndigheten's detailed machine-readable sources are
normally the primary construction inputs, but are not assumed infallible.

SCB is responsible for official election statistics. Its data are used for
validation and source-supported supplementation. A discrepancy requires investigation of definitions, populations, geography, versions,
corrections, aggregation and possible source errors. Use the value established
by the evidence and record the reasoning. Where the evidence cannot distinguish
the correct detailed value, preserve and describe that uncertainty. Never alter
raw sources or distribute an unexplained residual to force agreement.

Every deviation from an official published aggregate requires an explicit,
source-supported explanation. This rule also applies when reviewing a relevant
source discrepancy in an already implemented election.

## Snapshot preservation

When swelections is built or validated against a current official data
distribution, preserve a local snapshot of the relevant raw material and its
provenance even while that source remains publicly available. Public availability
does not guarantee that the same historical files will remain downloadable.

For indexed distributions retain the original index bytes, original file paths,
publisher-issued checksums, source URLs, acquisition times and independently
computed file hashes. Verify the index again after acquisition and report missing
files or a changing index explicitly; never substitute another source silently.
For unindexed auxiliary sources record observed hashes and retrieval metadata,
without presenting locally computed hashes as publisher-issued checksums.

Use one primary archived copy per source generation, retaining evidence needed
to explain corrections and differences. Remove derived or byte-identical working
copies only after verification; retain source-location/capture provenance when
consolidating copies. Preserve irreplaceable historical sources and useful future
inputs, including geography data. Snapshots remain outside Git.

A preserved snapshot is used through explicit local source selection. Archiving
does not turn remote into local or change automatic source selection.
