# Lokala och fjärrbaserade rådatafiler ---------------------------------------

.check_source_update <- function(source, update) {
  if (source == "local" && isTRUE(update)) {
    stop('`source = "local"` kan inte kombineras med `update = TRUE`.', call. = FALSE)
  }
}


.resolve_val_file <- function(
    path,
    ar,
    samling,
    source = c("auto", "local", "remote"),
    data_dir = NULL,
    base_url = NULL,
    update = FALSE,
    archive = FALSE
) {
  source <- match.arg(source)
  .check_source_update(source, update)

  if (source == "local") {
    file <- val_file(path, ar, samling, source = source, data_dir = data_dir)
    if (archive) {
      archive_val_file(file, path, ar, samling, data_dir = data_dir)
    }
    return(file)
  }

  if (update || archive) {
    download_val_file(
      path = path, ar = ar, samling = samling, data_dir = data_dir,
      base_url = base_url, update = update, archive = archive
    )
  } else {
    val_file(
      path = path, ar = ar, samling = samling, source = source,
      data_dir = data_dir, base_url = base_url
    )
  }
}

val_data_dir <- function(data_dir = NULL) {

  if (!is.null(data_dir)) {
    .check_data_dir(data_dir)
    return(normalizePath(
      data_dir,
      winslash = "/",
      mustWork = FALSE
    ))
  }

  data_dir <- getOption("swelections.data_dir", getOption("valresultat.data_dir"))

  if (is.null(data_dir)) {
    return(NULL)
  }

  .check_data_dir(data_dir)

  normalizePath(
    data_dir,
    winslash = "/",
    mustWork = FALSE
  )
}


val_local_path <- function(
    path,
    ar,
    samling,
    data_dir = NULL
) {

  data_dir <- val_data_dir(data_dir)

  if (is.null(data_dir)) {
    stop(
      "Ingen lokal datamapp har angetts. ",
      "Ange `data_dir` eller s\u00e4tt optionen `swelections.data_dir`.",
      call. = FALSE
    )
  }

  file.path(
    data_dir,
    as.character(ar),
    samling,
    path
  )
}


val_archive_path <- function(
    path,
    ar,
    samling,
    data_dir = NULL,
    archive_date = Sys.Date()
) {

  data_dir <- val_data_dir(data_dir)

  if (is.null(data_dir)) {
    stop(
      "Ingen lokal datamapp har angetts. ",
      "Ange `data_dir` eller s\u00e4tt optionen `swelections.data_dir`.",
      call. = FALSE
    )
  }

  file.path(
    data_dir,
    as.character(ar),
    samling,
    "archive",
    as.character(archive_date),
    path
  )
}


val_remote_url <- function(
    path,
    samling,
    base_url = NULL
) {

  if (is.null(base_url)) {
    base_url <- paste0(
      "https://resultat.val.se/resultatfiler/",
      samling
    )
  }

  paste0(
    sub("/+$", "", base_url),
    "/",
    sub("^/+", "", path)
  )
}


val_file <- function(
    path,
    ar,
    samling,
    source = c("auto", "local", "remote"),
    data_dir = NULL,
    base_url = NULL
) {

  source <- match.arg(source)

  if (source == "remote") {
    return(
      val_remote_url(
        path = path,
        samling = samling,
        base_url = base_url
      )
    )
  }

  if (source == "auto" && is.null(val_data_dir(data_dir))) {
    return(
      val_remote_url(
        path = path,
        samling = samling,
        base_url = base_url
      )
    )
  }

  local_path <- val_local_path(
    path = path,
    ar = ar,
    samling = samling,
    data_dir = data_dir
  )

  if (source == "local") {

    if (!file.exists(local_path)) {
      stop(
        "Filen finns inte i det lokala arkivet: ",
        local_path,
        call. = FALSE
      )
    }

    return(local_path)
  }

  if (file.exists(local_path)) {
    local_path
  } else {
    val_remote_url(
      path = path,
      samling = samling,
      base_url = base_url
    )
  }
}


same_file_md5 <- function(path1, path2) {

  if (!file.exists(path1) || !file.exists(path2)) {
    return(FALSE)
  }

  unname(tools::md5sum(path1)) ==
    unname(tools::md5sum(path2))
}


archive_val_file <- function(
    local_path,
    path,
    ar,
    samling,
    data_dir = NULL,
    archive_date = Sys.Date()
) {

  archive_path <- val_archive_path(
    path = path,
    ar = ar,
    samling = samling,
    data_dir = data_dir,
    archive_date = archive_date
  )

  dir.create(
    dirname(archive_path),
    recursive = TRUE,
    showWarnings = FALSE
  )

  if (file.exists(archive_path) &&
      same_file_md5(local_path, archive_path)) {
    return(archive_path)
  }

  ok <- file.copy(
    local_path,
    archive_path,
    overwrite = TRUE
  )

  if (!ok) {
    stop(
      "Kunde inte arkivera filen till: ",
      archive_path,
      call. = FALSE
    )
  }

  archive_path
}


download_val_file <- function(
    path,
    ar,
    samling,
    data_dir = NULL,
    base_url = NULL,
    update = FALSE,
    archive = FALSE
) {

  local_path <- val_local_path(
    path = path,
    ar = ar,
    samling = samling,
    data_dir = data_dir
  )

  dir.create(
    dirname(local_path),
    recursive = TRUE,
    showWarnings = FALSE
  )

  remote_url <- val_remote_url(
    path = path,
    samling = samling,
    base_url = base_url
  )

  if (!file.exists(local_path)) {

    download.file(
      remote_url,
      local_path,
      mode = "wb",
      quiet = TRUE
    )

  } else if (update) {

    tmp <- tempfile(fileext = paste0(
      ".",
      tools::file_ext(local_path)
    ))

    on.exit(
      unlink(tmp),
      add = TRUE
    )

    download.file(
      remote_url,
      tmp,
      mode = "wb",
      quiet = TRUE
    )

    if (!same_file_md5(local_path, tmp)) {

      ok <- file.copy(
        tmp,
        local_path,
        overwrite = TRUE
      )

      if (!ok) {
        stop(
          "Kunde inte uppdatera den lokala filen: ",
          local_path,
          call. = FALSE
        )
      }
    }
  }

  if (archive) {
    archive_val_file(
      local_path = local_path,
      path = path,
      ar = ar,
      samling = samling,
      data_dir = data_dir
    )
  }

  local_path
}
