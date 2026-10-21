# These fixtures are independent of production normalisation and do not require
# preserved election sources or generated canonical assets.
.auto_gate_eu2009_manifest <- function(full = TRUE) {
  assets <- paste0("eu2009-", c("results-final", "seats-final", "candidacies",
    "candidates", "elected", "substitutes", "candidate-base", "source-designations"))
  if (full) assets <- c(assets, paste0("eu2009-preference-base-", c("area", "national",
    "county", "municipality", "municipal-constituency", "district")))
  list(valserie = "eu", valar = 2009L, schema_version = 3L, format = "parquet",
    assets = data.frame(asset = assets),
    tables = data.frame(asset = assets, table = "national"))
}

test_that("central auto permissions are explicit for all twelve products", {
  all <- c("results", "seats", "candidacies", "candidates", "elected",
           "substitutes", "preference_votes")
  registry <- .canonical_release_registry()
  expect_equal(nrow(registry), 12L)
  expect_identical(registry$auto_eligible, rep(TRUE, 12L))
  for (i in seq_len(nrow(registry))) {
    entry <- .canonical_release(registry$year[i], registry$series[i])
    expected <- if (entry$series == "folkomr") "results" else
      if (entry$series == "rkl" && entry$year == 2002L) setdiff(all, "candidacies") else
      if (entry$series == "eu" && entry$year == 2009L) setdiff(all, "preference_votes") else all
    if (entry$series == "rkl" && entry$year %in% c(2014L, 2018L))
      expected <- c(expected, "mandate_history", "members_at", "vacant_seats_at")
    expect_identical(entry$auto_functions, expected)
    for (f in all) expect_identical(.canonical_auto_function_allowed(entry, f), f %in% expected)
  }
})

test_that("missing empty or malformed permission lists fail closed before manifest access", {
  local_mocked_bindings(.canonical_manifest_path = function(...) stop("must not inspect manifest"))
  for (allowed in list(NULL, character(), NA_character_, TRUE, list("results"))) {
    entry <- list(auto_eligible = TRUE, auto_functions = allowed)
    local_mocked_bindings(.canonical_release = function(...) entry)
    expect_identical(.select_public_source("auto", 2009L, "results", series = "eu"), "auto")
    expect_identical(.select_public_source("canonical", 2009L, "results", series = "eu"), "canonical")
    expect_identical(.select_public_source("local", 2009L, "results", series = "eu"), "local")
    expect_identical(.select_public_source("remote", 2009L, "results", series = "eu"), "remote")
  }
})

test_that("a full fourteen-asset EU2009 manifest cannot grant preference auto permission", {
  registry <- .canonical_release_registry()
  registry$auto_eligible[registry$series == "eu" & registry$year == 2009L] <- TRUE
  manifest <- .auto_gate_eu2009_manifest()
  expect_equal(nrow(manifest$assets), 14L)
  calls <- 0L
  local_mocked_bindings(.canonical_release_registry = function() registry,
    .canonical_manifest_path = function(...) { calls <<- calls + 1L; "full-prototype.json" },
    .canonical_manifest = function(...) manifest, .canonical_require_reader = function() NULL)
  en <- c("results", "seats", "candidacies", "candidates", "elected", "substitutes")
  sv <- c("valresultat", "mandat", "kandidaturer", "kandidater", "valda", "ersattare")
  for (f in c(en, sv))
    expect_identical(.select_public_source("auto", 2009L, f, series = "eu"), "canonical_auto")
  expect_identical(.select_public_source("auto", 2009L, "candidates", series = "eu",
    include_results = FALSE), "canonical_auto")
  before <- calls
  for (level in c("personvalsomrade", "riket", "lan", "kommun", "kommunvalkrets", "valdistrikt")) {
    # The full manifest genuinely covers this asset: permission is the blocker.
    expect_true(.canonical_view_covered(manifest, "preference_votes", niva = level))
    for (surface in c("preference_votes", "personroster"))
      expect_identical(.select_public_source("auto", 2009L, surface,
        series = "eu", niva = level), "auto")
  }
  expect_identical(calls, before)
  # Even a misleading coverage implementation cannot bypass the central gate.
  local_mocked_bindings(.canonical_view_covered = function(...) TRUE)
  expect_identical(.select_public_source("auto", 2009L, "preference_votes", series = "eu"), "auto")
  expect_identical(calls, before)
})

test_that("removing an approved function from the registry prevents auto even when an asset exists", {
  registry <- .canonical_release_registry()
  i <- registry$series == "eu" & registry$year == 2024L
  registry$auto_eligible[i] <- TRUE
  registry$auto_functions[[which(i)]] <- "results"
  local_mocked_bindings(.canonical_release_registry = function() registry,
    .canonical_manifest_path = function(...) stop("must not inspect candidate asset"))
  expect_identical(.select_public_source("auto", 2024L, "candidates", series = "eu"), "auto")
  expect_identical(.select_public_source("canonical", 2024L, "candidates", series = "eu"), "canonical")
})

test_that("approval cannot manufacture a missing geographic or counting-stage view", {
  registry <- .canonical_release_registry()
  registry$auto_eligible[registry$series == "eu" & registry$year == 2009L] <- TRUE
  m <- .auto_gate_eu2009_manifest()
  local_mocked_bindings(.canonical_release_registry = function() registry,
    .canonical_manifest_path = function(...) "fixture", .canonical_manifest = function(...) m,
    .canonical_require_reader = function() NULL)
  expect_identical(.select_public_source("auto", 2009L, "results", series = "eu",
    niva = "riket"), "canonical_auto")
  expect_identical(.select_public_source("auto", 2009L, "results", series = "eu",
    niva = "valdistrikt"), "auto")
  expect_identical(.select_public_source("auto", 2009L, "results", series = "eu",
    rakning = "preliminar"), "auto")
})

test_that("public EU2009 auto errors instead of selecting local despite a full configured prototype", {
  registry <- .canonical_release_registry()
  registry$auto_eligible[registry$series == "eu" & registry$year == 2009L] <- TRUE
  full <- .auto_gate_eu2009_manifest()
  local_mocked_bindings(.canonical_release_registry = function() registry,
    .canonical_manifest_path = function(...) "full-prototype.json",
    .canonical_manifest = function(...) full, .canonical_require_reader = function() NULL,
    .eu2009_canonical = function(table, args) {
      expect_false(table == "preference_votes")
      tibble::tibble(valar = 2009L, valtyp = "E")
    })
  root <- tempfile(); dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  writeLines("user raw snapshot", file.path(root, "slutresultat.zip"))
  withr::local_options(swelections.data_dir = root,
    swelections.canonical_manifest = "full-prototype.json")
  for (fn in list(results, seats, candidacies, candidates, elected, substitutes))
    expect_identical(fn(2009L, "E")$election_year, 2009L)
  for (level in c("preference_vote_area", "national", "county", "municipality",
                  "municipal_constituency", "district"))
    for (by_list in c(FALSE, TRUE)) for (zeros in c(FALSE, TRUE)) {
      expect_error(preference_votes(2009L, "E", level = level, by_list = by_list,
        include_zeros = zeros), 'source = "local"')
      expect_error(personroster(2009L, "E", niva = .english_argument_value(level, "level"),
        per_lista = by_list, komplettera_nollor = zeros), 'source = "local"')
    }
  local_mocked_bindings(.eu2009_read = function(table, args) {
    expect_identical(args$source, "local")
    tibble::tibble(valar = 2009L, valtyp = "E")
  })
  expect_identical(preference_votes(2009L, "E", source = "local", data_dir = root)$election_year, 2009L)
})

test_that("explicit canonical uses real manifest coverage independent of auto permission", {
  path <- tempfile(fileext = ".json"); writeLines("fixture", path)
  on.exit(unlink(path), add = TRUE)
  m <- .auto_gate_eu2009_manifest()
  # Exercise the real EU2009 canonical reader and missing-asset error. Only its
  # payload/presentation are isolated so this unit test needs no Parquet build.
  local_mocked_bindings(.canonical_manifest_path = function(...) path,
    .canonical_manifest = function(...) m,
    .canonical_fetcher = function(manifest, path) function(asset) {
      if (!asset %in% manifest$assets$asset) stop("Unknown canonical asset: ", asset)
      tibble::tibble(party_code = "0909", candidate_number = "source-column:36")
    },
    .canonical_table = function(...) tibble::tibble(partikod = "0909", kandidatnummer = "source-column:36"),
    .eu2009_preference_view = function(...) tibble::tibble(valar = 2009L, valtyp = "E", antal_personroster = 22L))
  expect_true(.canonical_release(2009L, "eu")$auto_eligible)
  expect_false(.canonical_auto_function_allowed(.canonical_release(2009L, "eu"), "preference_votes"))
  expect_identical(preference_votes(2009L, "E", source = "canonical")$preference_votes, 22L)
  m <- .auto_gate_eu2009_manifest(FALSE)
  expect_error(preference_votes(2009L, "E", source = "canonical"),
    "Unknown canonical asset: eu2009-preference-base-area")
})
