# R-only, source-preserving preparation; sourced by build-canonical-2022.R.
# Development dependencies: jsonlite, digest and zip (existing R toolchain).
# See development/R_ONLY_WORKFLOW.md for source and byte-level rules.
canonical2022_bytes <- function(path) readBin(path, "raw", file.info(path)$size)
canonical2022_digest <- function(bytes, algorithm) {
  digest::digest(bytes, algo = algorithm, serialize = FALSE)
}
canonical2022_json <- function(bytes) {
  text <- rawToChar(bytes)
  text <- sub("^\ufeff", "", text)
  jsonlite::fromJSON(text, simplifyVector = FALSE)
}
canonical2022_member <- function(path, member) {
  con <- unz(path, member, open = "rb")
  on.exit(close(con))
  size <- utils::unzip(path, list = TRUE)$Length[
    utils::unzip(path, list = TRUE)$Name == member]
  stopifnot(length(size) == 1L)
  readBin(con, "raw", size)
}
canonical2022_correct <- function(raw, kind) {
  stopifnot(identical(raw$valtyp, "RF"),
    identical(raw$valtillfalle, "Val_20220911"))
  if (kind == "mandatfordelning") stopifnot(raw$valomrade$kod == "25") else
    stopifnot(all(vapply(raw$valdistrikt, function(x) x$valomradeskod == "25", TRUE)))
  changes <- character()
  visit <- function(node, path = "", party = NULL, ballot = NULL) {
    if (!is.list(node)) return(node)
    object <- !is.null(names(node))
    if (object) {
      if (!is.null(node$partikod)) party <- node$partikod
      if (!is.null(node$listnummer)) ballot <- node$listnummer
    }
    for (i in seq_along(node)) {
      field <- if (object) names(node)[[i]] else as.character(i - 1L)
      child <- paste0(path, "/", field)
      value <- node[[i]]
      if (object && field %in% c("kandidatNummer", "kandidatnummer") &&
          length(value) == 1L && as.character(value) == "50975") {
        stopifnot(as.character(party) == "0110")
        if (field == "kandidatNummer") stopifnot(ballot == "0110-03652")
        node[i] <- list(if (is.character(value)) "488" else 488L)
        changes <<- c(changes, child)
      } else if (is.list(value)) node[i] <- list(visit(value, child, party, ballot))
    }
    node
  }
  result <- visit(raw)
  stopifnot(length(changes) == if (kind == "mandatfordelning") 2L else 95L)
  list(raw = result, changes = changes)
}
canonical2022_zip <- function(path, members) {
  # Fixed UTC mtime and member order, including the candidate CSV. Original
  # files are never passed to Sys.setFileTime: only new staging copies are.
  folder <- tempfile("zip-members-")
  dir.create(folder)
  on.exit(unlink(folder, recursive = TRUE))
  for (name in names(members)) {
    stopifnot(identical(basename(name), name))
    target <- file.path(folder, name)
    writeBin(members[[name]], target)
    Sys.setFileTime(target, as.POSIXct("2022-09-11 00:00:00", tz = "UTC"))
    Sys.chmod(target, "0600")
  }
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  old_tz <- Sys.getenv("TZ", unset = NA_character_)
  on.exit(if (is.na(old_tz)) Sys.unsetenv("TZ") else Sys.setenv(TZ = old_tz), add = TRUE)
  Sys.setenv(TZ = "UTC")
  zip::zipr(path, names(members), root = folder, include_directories = FALSE,
    compression_level = 6L)
  # ZIP stores a timezone-free DOS calendar, whereas Windows ZIP libraries may
  # interpret mtime in the system timezone despite TZ. Set both header copies
  # directly to midnight 2022-09-11; compressed data and CRC are untouched.
  bytes <- canonical2022_bytes(path)
  unsigned <- function(at, n) sum(as.numeric(bytes[at + seq_len(n) - 1L]) * 256^(0:(n - 1L)))
  ending <- length(bytes) - 21L
  stopifnot(identical(bytes[ending + 0:3], as.raw(c(80, 75, 5, 6))))
  position <- unsigned(ending + 16L, 4L) + 1L
  date <- (2022L - 1980L) * 512L + 9L * 32L + 11L
  stamp <- as.raw(c(0L, 0L, date %% 256L, date %/% 256L))
  for (i in seq_along(members)) {
    stopifnot(identical(bytes[position + 0:3], as.raw(c(80, 75, 1, 2))))
    local <- unsigned(position + 42L, 4L) + 1L
    bytes[local + 10:13] <- stamp
    bytes[position + 12:15] <- stamp
    position <- position + 46L + unsigned(position + 28L, 2L) +
      unsigned(position + 30L, 2L) + unsigned(position + 32L, 2L)
  }
  writeBin(bytes, path)
}
canonical2022_pairs <- function(source) {
  sort(list.files(file.path(source, "valresultat", "filer"),
    pattern = "^Val_.*_mandatfordelning_.*[.]json$", full.names = TRUE), method = "radix")
}
canonical2022_validate <- function(source, stage, corrections) {
  counts <- c(preserved = 0L, corrected = 0L, reconstructed = 0L)
  paths <- canonical2022_pairs(source)
  stopifnot(length(paths) == 622L)
  for (md in paths) {
    bits <- strsplit(tools::file_path_sans_ext(basename(md)), "_", fixed = TRUE)[[1]]
    count <- bits[[3]]; area <- bits[[5]]; election <- bits[[6]]
    name <- paste("Val", bits[[2]], count, area, election, sep = "_")
    path <- file.path(stage, "2022", "val2022", if (count == "slutlig") "s" else "p",
      tolower(election), paste0(name, ".zip"))
    for (file in c(md, sub("mandatfordelning", "rostfordelning", md, fixed = TRUE))) {
      actual <- canonical2022_member(path, basename(file))
      original <- canonical2022_bytes(file)
      if (count == "slutlig" && election == "KF" && area %in% c("0136", "1439", "1860", "2506")) {
        stopifnot(identical(actual, canonical2022_member(
          file.path(corrections, paste0(name, ".zip")), basename(file))))
        counts[["corrected"]] <- counts[["corrected"]] + 1L
      } else if (count == "slutlig" && election == "RF" && area == "25") {
        kind <- if (file == md) "mandatfordelning" else "rostfordelning"
        expected <- canonical2022_correct(canonical2022_json(original), kind)$raw
        # JSON has one numeric type. A serializer may spell 1.0 as 1;
        # compare exact numeric values, still checking structure and attributes.
        stopifnot(isTRUE(all.equal(canonical2022_json(actual), expected, tolerance = 0)))
        counts[["reconstructed"]] <- counts[["reconstructed"]] + 1L
      } else {
        stopifnot(identical(actual, original))
        counts[["preserved"]] <- counts[["preserved"]] + 1L
      }
    }
  }
  stopifnot(identical(counts, c(preserved = 1234L, corrected = 8L, reconstructed = 2L)))
  candidate <- canonical2022_member(file.path(stage, "2022", "val2022", "parti",
    "kandidaturer.zip"), "kandidaturer.csv")
  stopifnot(canonical2022_digest(candidate, "md5") == "639daa9630a1f2554f1c6839473448ee")
  counts
}
canonical2022_prepare <- function(source, stage, corrections) {
  for (dependency in c("jsonlite", "digest", "zip"))
    if (!requireNamespace(dependency, quietly = TRUE)) stop("Install build dependency: ", dependency)
  source <- normalizePath(source, winslash = "/", mustWork = TRUE)
  stage <- normalizePath(stage, winslash = "/", mustWork = TRUE)
  candidate <- file.path(source, "kandidater", "kandidaturer_20241218.csv")
  stopifnot(canonical2022_digest(canonical2022_bytes(candidate), "md5") ==
    "639daa9630a1f2554f1c6839473448ee")
  sources <- transformations <- list(); original <- list(); index <- character()
  record <- function(path, bytes, classification, selected, url = NULL) {
    hash <- canonical2022_digest(bytes, "sha256")
    sources[[length(sources) + 1L]] <<- list(source = path,
      md5 = canonical2022_digest(bytes, "md5"), sha256 = hash,
      bytes = length(bytes), classification = classification, selected = selected, url = url)
    if (file.exists(path)) original[[path]] <<- hash
  }
  for (path in sort(list.files(file.path(source, "kandidater"),
      pattern = "^kandidaturer.*[.]csv$", full.names = TRUE), method = "radix"))
    record(path, canonical2022_bytes(path), "official_historical_candidate_snapshot", path == candidate)
  paths <- canonical2022_pairs(source)
  stopifnot(length(paths) == 622L)
  for (md in paths) {
    bits <- strsplit(tools::file_path_sans_ext(basename(md)), "_", fixed = TRUE)[[1]]
    count <- bits[[3]]; area <- bits[[5]]; election <- bits[[6]]
    corrected <- count == "slutlig" && election == "KF" && area %in% c("0136", "1439", "1860", "2506")
    members <- list()
    for (path in c(md, sub("mandatfordelning", "rostfordelning", md, fixed = TRUE))) {
      bytes <- canonical2022_bytes(path)
      record(path, bytes, "preserved_official_result_snapshot", !corrected)
      signature <- sub("[.]json$", "_sign.sha256", path)
      if (file.exists(signature)) record(signature, canonical2022_bytes(signature), "rsa_signature_not_text_checksum", FALSE)
      kind <- if (path == md) "mandatfordelning" else "rostfordelning"
      if (count == "slutlig" && election == "RF" && area == "25") {
        pin <- c(mandatfordelning = "ea31f87d4172ad787258cfe5790b4ff6",
          rostfordelning = "8ae8a7f37467daee7c5fcd408dcaa10b")[[kind]]
        stopifnot(canonical2022_digest(bytes, "md5") == pin)
        corrected_json <- canonical2022_correct(canonical2022_json(bytes), kind)
        bytes <- charToRaw(enc2utf8(as.character(jsonlite::toJSON(corrected_json$raw,
          auto_unbox = TRUE, null = "null", digits = NA))))
        transformations[[length(transformations) + 1L]] <- list(
          rule = "RF25_Bo_Larsson_50975_to_488", source = path, original_md5 = pin,
          fields = corrected_json$changes, derived_sha256 = canonical2022_digest(bytes, "sha256"),
          decision = "Lansstyrelsen Norrbotten 201-11278-2022, 2022-11-14",
          decision_url = "https://resultat.val.se/protokoll/protokoll_Val_20220911_25_RF.pdf",
          semantics = paste("Original election-time elected/substitute relations retained;",
            "no subsequent mandate-period replacements incorporated."))
      }
      members[[basename(path)]] <- bytes
    }
    name <- paste0(paste("Val", bits[[2]], count, area, election, sep = "_"), ".zip")
    relative <- paste(if (count == "slutlig") "s" else "p", tolower(election), name, sep = "/")
    if (corrected) {
      official <- file.path(corrections, name)
      stopifnot(all(names(members) %in% utils::unzip(official, list = TRUE)$Name))
      for (member in names(members)) {
        members[[member]] <- canonical2022_member(official, member)
        record(member, members[[member]], "official_corrected_election_result", TRUE,
          paste0("https://resultat.val.se/resultatfiler/val2022/", relative))
      }
      record(official, canonical2022_bytes(official), "official_zip_verified_against_index", TRUE,
        paste0("https://resultat.val.se/resultatfiler/val2022/", relative))
    }
    destination <- file.path(stage, "2022", "val2022", relative)
    canonical2022_zip(destination, members)
    index <- c(index, paste0(unname(tools::md5sum(destination)), "  ./", relative))
  }
  writeBin(charToRaw(paste0(paste(index, collapse = "\n"), "\n")), file.path(stage, "2022", "val2022", "index.md5"))
  canonical2022_zip(file.path(stage, "2022", "val2022", "parti", "kandidaturer.zip"),
    list(kandidaturer.csv = canonical2022_bytes(candidate)))
  jsonlite::write_json(list(sources = sources, harmonisation = transformations,
    original_source_sha256 = original, input_archive = stage, source_root = source),
    file.path(stage, "provenance.json"), auto_unbox = TRUE, pretty = TRUE, null = "null")
  canonical2022_validate(source, stage, corrections)
}
