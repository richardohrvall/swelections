# swelections

`swelections` is an R package for Swedish election results, candidates and mandate
histories. It brings together and harmonises data from two main official sources.
The Swedish Election Authority is responsible for planning and coordinating the
implementation of elections. Statistics Sweden (SCB) is responsible for official
election statistics. The package draws on data from both.

Swedish election data are spread across election years, source files, formats
and geographic levels. The package makes these data easier to find and use
through a consistent R interface. Preserved official sources also support
historical results when files or their original web addresses have changed
or disappeared.

## What you can do

Depending on the election and function, you can retrieve votes and vote shares,
aggregate counts of eligible voters and electorate composition, turnout, seat
allocations, candidacies and candidate characteristics such as age and sex where
reported. You can also examine preference votes, elected candidates and
substitutes, or follow mandate holders and vacancies during supported periods.
English and Swedish interfaces are available.

The current release covers ordinary parliamentary, regional and municipal
elections, European Parliament elections, the 2003 euro referendum and five
re-elections. The available functions, geographic levels and counting stages
vary between elections. See [Coverage](articles/coverage.html) for the current
version's coverage and limitations.

The default `source = "auto"` is recommended for most users: it chooses approved
canonical data first, otherwise a supported current official source. Choose a
source explicitly when you need a particular input.

## Consistent tables, preserved distinctions

The package standardises table structures and technical categories across
supported data, while preserving differences in counting stage, geographic scope
and source detail. It does not currently harmonise historical voting-district
boundaries or establish person identities across elections.

Use the R functions for documented output tables, or read the published
canonical data — the versioned Parquet files distributed by `swelections` —
directly in other tools such as Python. The published files provide a stable
data basis for the corresponding release. Direct file access may require
selecting stored tables or combining files.

## Explore the documentation

- [Get started](articles/swelections.html): results and geographic levels, seats,
  mandate-period changes, preference votes and re-elections.
- [Coverage](articles/coverage.html): available elections, functions and levels.
- [Understanding Swedish elections](articles/understanding-elections.html):
  electoral geography, seat allocation, personal voting and historical changes.
- [Sources & methodology](articles/sources-methodology.html): construction,
  data processing, validation and treatment of source differences.
- [Accessing the data](articles/accessing-data.html): source choices, data exports
  and direct use of Parquet files outside R.

## Citation

If you use swelections in research, cite the package and the version used.
For v0.4.1:

> Öhrvall, R. (2026). *swelections: Swedish Election Data*
> (R package version 0.4.1). [GitHub release](https://github.com/richardohrvall/swelections/releases/tag/v0.4.1).

Use `citation("swelections")` for citation information.
