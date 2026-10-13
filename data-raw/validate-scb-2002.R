# SCB is an independent control, not canonical build input.
# Rscript data-raw/validate-scb-2002.R RAW_ROOT
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop('Specify RAW_ROOT.')
pkgload::load_all('.', quiet = TRUE)
if (!requireNamespace('haven', quietly = TRUE)) stop('Install haven for development validation.')
s <- swelections:::.sources_2002('local', args[[1]])
root <- file.path(args[[1]], '2002')
checks <- 0L
equal <- function(a, b, label) {
  if (!identical(as.double(a), as.double(b))) stop(label, ': ', a, ' versus ', b)
  checks <<- checks + 1L
}
number <- function(n, f) as.double(xml2::xml_attr(n, f))
for (v in c('RD', 'RF', 'KF')) {
  long <- haven::read_dta(file.path(root, 'scb', paste0('valres_parti_valdistr2002_',
    c(RD = 'ri', RF = 'lt', KF = 'ko')[[v]], '.dta')))
  doc <- xml2::read_xml(swelections:::.xml2002_source(s, swelections:::.xml2002_files(s, v)), options = 'NONET')
  list_nodes <- xml2::xml_find_all(doc, './/GILTIGA/VALSEDEL')
  list_party <- xml2::xml_attr(xml2::xml_find_first(list_nodes, 'parent::*'), 'PARTI')
  list_codes <- sub('-.*', '', xml2::xml_attr(list_nodes, 'LISTNUMMER'))
  party_map <- split(list_codes, list_party)
  party_map <- lapply(party_map, unique)
  stopifnot(all(lengths(party_map) == 1L))
  areas <- xml2::xml_find_all(doc, './NATION/LÄN/KRETS_RIKSDAG/KOMMUN')
  stopifnot(length(areas) == if (v == 'RF') 289L else 290L,
    !anyDuplicated(xml2::xml_attr(areas, 'KOD')))
  for (a in areas) {
    code <- xml2::xml_attr(a, 'KOD')
    x <- long[long$llkk == code, ]
    # Current KF SCB contains the March 2003 rerun, not ordinary Orsa 2002.
    if (v == 'KF' && code == '2034') {
      equal(number(a, 'RÖSTER'), 4009, 'ordinary Orsa valid')
      equal(number(xml2::xml_find_first(a, './VALDELTAGANDE'), 'SUMMA_RÖSTER'), 4070, 'ordinary Orsa cast')
      equal(sum(x$antrost[!x$partikod %in% c('9998', '9999')]), 4303, 'SCB rerun Orsa valid')
      cat('EXPLAINED KF Orsa: ordinary 4009 valid; SCB rerun 4303 valid\n')
      next
    }
    equal(number(a, 'RÖSTER'), sum(x$antrost[!x$partikod %in% c('9998', '9999')]), paste(v, code, 'valid'))
    equal(number(xml2::xml_find_first(a, './OGILTIGA[@TEXT="OG"]'), 'RÖSTER'),
      sum(x$antrost[x$partikod %in% c('9998', '9999')]), paste(v, code, 'combined invalid'))
    for (p in xml2::xml_find_all(a, './GILTIGA|./GILTIGA/VARAV_ÖVRIGA')) {
      alias <- xml2::xml_attr(p, 'PARTI')
      party_code <- if (grepl('^[0-9]{4}$', alias)) alias else party_map[[alias]]
      if (length(party_code) == 1L && !is.na(party_code) && party_code %in% x$partikod)
        equal(number(p, 'RÖSTER'), sum(x$antrost[x$partikod == party_code]), paste(v, code, alias, 'votes'))
    }
  }
  cat('PASS', v, 'SCB municipality/party controls\n')
}
cat('PASS', checks, 'independent SCB comparisons; Orsa occasions remain separate\n')
