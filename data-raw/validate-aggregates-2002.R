# Independent final XML geography controls; sources are never changed.
# Rscript data-raw/validate-aggregates-2002.R RAW_ROOT
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop('Specify RAW_ROOT.')
pkgload::load_all('.', quiet = TRUE)
s <- swelections:::.sources_2002('local', args[[1]])
read <- function(f) xml2::read_xml(swelections:::.xml2002_source(s, f), options = 'NONET')
value <- function(n, field) as.double(xml2::xml_attr(n, field))
sum_known <- function(x) if (anyNA(x)) NA_real_ else sum(x)
checks <- differences <- unknown <- 0L
check <- function(a, b, label) {
  if (is.na(a) || is.na(b)) { unknown <<- unknown + 1L; cat('UNVERIFIABLE', label, a, b, '\n'); return() }
  checks <<- checks + 1L
  if (a != b) { differences <<- differences + 1L; cat('SOURCE DIFFERENCE', label, a, b, '\n') }
}
for (v in c('RD', 'RF', 'KF')) {
  letter <- c(RD = 'R', RF = 'L', KF = 'K')[[v]]
  national <- read(paste0('slutresultat_00', letter, '.xml'))
  municipalities <- xml2::xml_find_all(national, './NATION/LÄN/KRETS_RIKSDAG/KOMMUN')
  codes <- xml2::xml_attr(municipalities, 'KOD')
  files <- sort(s$sources$export[grepl(paste0('^slutresultat_[0-9]{4}', letter, '[.]xml$'), s$sources$export)])
  for (file in files) {
    doc <- read(file); municipality <- xml2::xml_find_first(doc, './KOMMUN')
    code <- xml2::xml_attr(municipality, 'KOD')
    aggregate <- municipalities[[match(code, codes)]]
    districts <- xml2::xml_find_all(doc, './KOMMUN/KRETS_KOMMUN/VALDISTRIKT|./KOMMUN/KRETS_KOMMUN/ONSDAGSDISTRIKT|./KOMMUN/ONSDAGSDISTRIKT')
    stopifnot(length(districts) > 0L, !anyDuplicated(xml2::xml_attr(districts, 'KOD')))
    check(value(municipality, 'RÖSTER'), value(aggregate, 'RÖSTER'), paste(v, code, 'municipal/national valid'))
    check(sum_known(value(districts, 'RÖSTER')), value(municipality, 'RÖSTER'), paste(v, code, 'district/municipal valid'))
    invalid <- xml2::xml_find_first(districts, './OGILTIGA[@TEXT="OG"]')
    check(sum_known(value(invalid, 'RÖSTER')), value(xml2::xml_find_first(municipality, './OGILTIGA[@TEXT="OG"]'), 'RÖSTER'), paste(v, code, 'district invalid'))
    turnout <- xml2::xml_find_first(districts, './VALDELTAGANDE')
    cast <- value(turnout, 'SUMMA_RÖSTER')
    missing <- is.na(cast)
    cast[missing] <- (value(districts, 'RÖSTER') + value(invalid, 'RÖSTER'))[missing]
    check(sum_known(cast), value(xml2::xml_find_first(municipality, './VALDELTAGANDE'), 'SUMMA_RÖSTER'), paste(v, code, 'district cast'))
    for (party in c('M', 'C', 'FP', 'KD', 'S', 'V', 'MP')) {
      path <- paste0('./GILTIGA[@PARTI="', party, '"]')
      p <- xml2::xml_find_first(districts, path)
      check(sum_known(value(p, 'RÖSTER')), value(xml2::xml_find_first(municipality, path), 'RÖSTER'), paste(v, code, party, 'district votes'))
    }
  }
  check(sum_known(value(municipalities, 'RÖSTER')), value(xml2::xml_find_first(national, './NATION'), 'RÖSTER'), paste(v, 'municipality/national valid'))
  cat('COVERAGE', v, length(files), '/', length(codes), 'municipal XML exports\n')
}
cat('COMPLETE', checks, 'comparisons;', differences, 'source differences;', unknown, 'unverifiable fields\n')
if (differences) stop('Source aggregate differences require review; no values reconciled.')
