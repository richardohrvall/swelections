# Sequential R-only historical acquisition. Successful cached bytes are immutable.
# Rscript development/preserve_preliminary_2010_conservative.R ROOT OUT [--verify-cache]
# ROOT is the 2010 valresultat directory. OUT is new or a resumable R preservation.
source("development/source_tools.R")
preliminary2010_plan <- function(root) {
  archive <- file.path(root, "slutresultat.zip"); jobs <- list()
  add <- function(relative, entry) {
    jobs[[relative]] <<- c(list(relative = relative,
      url = paste0("https://historik.val.se/val/val2010/prelresultat/", relative)), entry)
  }
  for (member in utils::unzip(archive, list = TRUE)$Name) {
    match <- stringr::str_match(member, "^slutresultat_([0-9]{4})([RLK])[.]xml$")
    if (is.na(match[[1]])) next
    municipality <- match[[2]]; v <- match[[3]]; doc <- audit_xml(archive, member)
    for (node in xml2::xml_find_all(doc, "./KOMMUN/KRETS_KOMMUN/ONSDAGSDISTRIKT")) {
      code <- xml2::xml_attr(node, "KOD"); pieces <- strsplit(code, "-", fixed = TRUE)[[1]]
      stopifnot(pieces[[1]] == v, pieces[[2]] == municipality)
      add(paste0(v, "/onsdagsdistrikt/", substr(municipality, 1, 2), "/", substr(municipality, 3, 4), "/", pieces[[3]], "/index.html"),
        list(role = "collection_district", election = v, code = code, municipality = municipality,
          municipal_constituency = pieces[[3]], geography_source = member))
    }
    add(paste0(v, "/kommun/", substr(municipality, 1, 2), "/", substr(municipality, 3, 4), "/index.html"),
      list(role = "municipality", election = v, code = municipality))
  }
  for (v in c("R", "L", "K")) {
    add(paste0(v, "/rike/index.html"), list(role = "national", election = v, code = "00"))
    doc <- audit_xml(archive, paste0("slutresultat_00", v, ".xml"))
    if (v == "R") for (node in xml2::xml_find_all(doc, ".//KRETS_RIKSDAG")) {
      code <- xml2::xml_attr(node, "KOD")
      add(paste0("R/rvalkrets/", substr(code, 3, nchar(code)), "/index.html"), list(role = "constituency", election = v, code = code))
    }
    if (v == "L") {
      for (node in xml2::xml_find_all(doc, ".//LÄN")) {
        code <- xml2::xml_attr(node, "KOD")
        add(paste0("L/lan/", code, "/index.html"), list(role = "region", election = v, code = code))
      }
      for (node in xml2::xml_find_all(doc, ".//KRETS_LANDSTING")) {
        code <- xml2::xml_attr(node, "KOD"); if (endsWith(code, "00")) next
        add(paste0("L/lvalkrets/", substr(code, 1, 2), "/", substr(code, 3, nchar(code)), "/index.html"),
          list(role = "regional_constituency", election = v, code = code))
      }
    }
  }
  # Capture municipal-constituency aggregate pages too. This removes dependence
  # on the retired initial parallel retriever when acquiring a new collection.
  for (member in utils::unzip(archive, list = TRUE)$Name) {
    if (!grepl("^slutresultat_[0-9]{4}[RLK][.]xml$", member)) next
    v <- substr(member, nchar(member) - 4, nchar(member) - 4)
    for (node in xml2::xml_find_all(audit_xml(archive, member), "./KOMMUN/KRETS_KOMMUN")) {
      code <- xml2::xml_attr(node, "KOD")
      add(paste0(v, "/kvalkrets/", substr(code, 1, 2), "/", substr(code, 3, 4), "/", substr(code, 5, 6), "/index.html"),
        list(role = "municipal_constituency", election = v, code = code))
    }
  }
  unname(jobs[sort(names(jobs), method = "radix")])
}
preliminary2010_valid <- function(bytes, job) {
  if (!length(bytes)) return(FALSE)
  doc <- xml2::read_html(bytes, options = "NONET")
  rows <- audit_rows(doc)
  if (job$role == "national" && job$election %in% c("L", "K")) return(length(rows) > 0L)
  any(lengths(rows) == 8L)
}
preliminary2010_accept <- function(response, job) {
  grepl("/prelresultat/", response$url, fixed = TRUE) &&
    preliminary2010_valid(response$content, job)
}
preliminary2010_request <- function(url, fetch = function(url) curl::curl_fetch_memory(url,
    curl::new_handle(followlocation = TRUE, timeout = 90, useragent = "swelections sequential historical-source preservation")),
    sleep = Sys.sleep, rate_limit = function(wait) sleep(wait), clock = function() format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")) {
  last <- NULL
  for (attempt in 1:3) {
    sleep(1.5)
    response <- tryCatch(fetch(url), error = function(e) e)
    if (inherits(response, "error")) {
      last <- conditionMessage(response); sleep(15 * attempt); next
    }
    status <- response$status_code
    if (status == 200L && length(response$content)) return(list(response = response, retrieved_at_utc = clock()))
    last <- if (status == 200L) paste("Empty response", url) else paste("HTTP", status, url)
    if (status == 429L) {
      headers <- curl::parse_headers_list(response$headers)
      retry <- suppressWarnings(as.numeric(headers[["retry-after"]]))
      if (!length(retry) || is.na(retry)) retry <- 0
      rate_limit(max(120 * attempt, retry))
    } else if (status >= 400L && status < 500L) break else sleep(15 * attempt)
  }
  stop(last, call. = FALSE)
}
preliminary2010_preserve <- function(root, out, verify = FALSE) {
  jobs <- preliminary2010_plan(root)
  caches <- list.dirs(root, recursive = FALSE, full.names = TRUE)
  caches <- caches[grepl("^preliminary-(collection-preservation|presentation)-", basename(caches))]
  prior <- list()
  for (cache in caches) {
    manifest <- file.path(cache, "source-manifest.json")
    if (!file.exists(manifest)) next
    for (row in audit_json(manifest)$sources) {
      row$cache_file <- file.path(cache, row$file)
      old <- prior[[row$url]]
      if (!is.null(old) && !identical(old$sha256, row$sha256))
        stop("Conflicting preserved snapshots for ", row$url)
      if (is.null(old)) prior[[row$url]] <- row
    }
  }
  collection <- jobs[vapply(jobs, function(x) x$role == "collection_district", TRUE)]
  stopifnot(sum(vapply(collection, function(x) x$election == "R", TRUE)) == 395L,
    sum(vapply(collection, function(x) x$election == "L", TRUE)) == 392L,
    sum(vapply(collection, function(x) x$election == "K", TRUE)) == 395L)
  if (verify) {
    for (job in collection) {
      row <- prior[[job$url]]; stopifnot(!is.null(row))
      audit_pin(row$cache_file, row$bytes, row$md5, row$sha256)
      stopifnot(preliminary2010_valid(audit_bytes(row$cache_file), job))
    }
    cat("PASS immutable collection cache: 395 RD, 392 RF, 395 KF; no HTTP calls\n")
    return(invisible(jobs))
  }
  previous <- file.path(out, "source-manifest.json")
  sources <- failures <- list()
  if (dir.exists(out) && length(list.files(out, all.files = TRUE, no.. = TRUE))) {
    if (!file.exists(previous) || !identical(audit_json(previous)$retrieval_tool, "R sequential preservation"))
      stop("Existing source snapshots are immutable; only resume an R preservation directory.")
    sources <- audit_json(previous)$sources
    for (row in sources) audit_pin(file.path(out, row$file), row$bytes, row$md5, row$sha256)
  }
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  audit_write(jobs, file.path(out, "expected-sources.json"))
  rate_limits <- 0L
  save_manifest <- function() {
    raw <- lapply(c("valnatt.zip", "slutresultat.zip"), function(name) {
      path <- file.path(root, name)
      list(file = path, role = if (name == "valnatt.zip") "election_night_votes" else "geography_only_no_vote_values",
        bytes = file.info(path)$size, md5 = audit_hash(path, "md5"), sha256 = audit_hash(path))
    })
    audit_write(list(election_year = 2010L, retrieval_tool = "R sequential preservation",
      source = "Official Valmyndigheten preliminary historical presentation",
      raw_inputs = raw, existing_validation_sources = list(), sources = sources, failures = failures,
      expected_collection_sources = collection, retrieval_policy = list(parallel = FALSE, delay_seconds = 1.5,
        timeout_seconds = 90L, attempts = 3L, rate_limit_backoff_seconds = c(120L, 240L), stop_after_rate_limits = 3L)),
      file.path(out, "source-manifest.json"))
  }
  on.exit(save_manifest())
  order <- order(!vapply(jobs, function(x) x$role == "collection_district", TRUE), vapply(jobs, `[[`, "", "relative"))
  for (job in jobs[order]) {
    if (job$url %in% vapply(sources, `[[`, "", "url")) next
    cached <- prior[[job$url]]
    result <- tryCatch({
      if (!is.null(cached)) {
        audit_pin(cached$cache_file, cached$bytes, cached$md5, cached$sha256)
        list(response = list(content = audit_bytes(cached$cache_file), url = job$url, status_code = 200L,
          headers = NULL), retrieved_at_utc = cached$retrieved_at_utc)
      } else preliminary2010_request(job$url, rate_limit = function(wait) {
        rate_limits <<- rate_limits + 1L
        if (rate_limits >= 3L) stop("HTTP 429 limit reached; successful sources preserved, stop and retry later.")
        Sys.sleep(wait)
      })
    }, error = function(e) e)
    if (inherits(result, "error")) {
      failures <- c(failures, list(c(job, list(error = conditionMessage(result)))))
      if (rate_limits >= 3L) stop(conditionMessage(result), call. = FALSE)
      next
    }
    response <- result$response
    if (!preliminary2010_accept(response, job)) {
      failures <- c(failures, list(c(job, list(error = "Invalid preliminary page or redirect")))); next
    }
    file <- file.path(out, job$relative); dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
    if (file.exists(file)) stop("Unregistered existing response; refusing to overwrite ", file)
    con <- file(file, "wb"); writeBin(response$content, con); close(con)
    row <- c(job, list(file = job$relative, status = 200L, valid_result_page = TRUE,
      final_url = response$url, bytes = length(response$content), md5 = audit_hash(file, "md5"),
      response_headers = if (is.null(response$headers)) NULL else curl::parse_headers_list(response$headers),
      cached_from = if (is.null(cached)) NULL else cached$cache_file,
      sha256 = audit_hash(file), retrieved_at_utc = result$retrieved_at_utc,
      preserved_at_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")))
    sources <- c(sources, list(row))
    cat(as.character(jsonlite::toJSON(row, auto_unbox = TRUE, null = "null")), "\n",
      file = file.path(out, "retrieval.jsonl"), append = TRUE, sep = "")
  }
  missing <- setdiff(vapply(collection, `[[`, "", "url"), vapply(sources, `[[`, "", "url"))
  if (length(missing)) stop("Incomplete collection source: ", paste(missing, collapse = ", "))
  cat("PASS complete collection acquisition; aggregate failures remain documented\n")
}
if (!isTRUE(getOption("swelections.source_tools_only"))) {
  args <- commandArgs(trailingOnly = TRUE); stopifnot(length(args) >= 2L)
  preliminary2010_preserve(args[[1]], args[[2]], "--verify-cache" %in% args)
}
