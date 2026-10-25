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
or disappeared; users of published canonical data do not need a raw-data archive.

## What you can do

Retrieve votes at national, municipal or voting-district level; examine seat
allocations, candidacies and preference votes; or follow mandate holders and
vacancies during supported mandate periods. English and Swedish interfaces
are available.

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
canonical Parquet files directly in other tools. Direct file access may require
selecting stored tables or combining files.

## Explore the documentation

- [Get started](articles/swelections.html): results and geographic levels, seats,
  preference votes and re-elections.
- [Coverage](articles/coverage.html): available elections, functions and levels.
- [Sources & methodology](articles/sources-methodology.html): construction,
  data processing, validation and treatment of source differences.
- [Accessing the data](articles/accessing-data.html): source choices, data exports
  and direct use of Parquet files outside R.

## Citation

If you use swelections in research, cite the package and the version used.
For v0.4.1:

> Öhrvall, R. (2026). *swelections: Read and Harmonise Swedish Election Results*
> (R package version 0.4.1). [GitHub release](https://github.com/richardohrvall/swelections/releases/tag/v0.4.1).

Use `citation("swelections")` for citation information.
