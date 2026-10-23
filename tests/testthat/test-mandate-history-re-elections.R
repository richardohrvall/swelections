# Synthetic holder IDs exercise actual event scopes/seat counts, not historical persons.
mh_event_fixture <- function(event, omitted_original = FALSE) {
  y <- event$original_year[[1L]]; day <- .mh_election_date(y)
  cut <- as.Date(event$election_date[[1L]])
  sizes <- if (event$scope_level == "region") c(50L,31L,27L,18L,23L) else event$seats_expected
  co <- if (event$scope_level == "region") paste0("14",sprintf("%02d",1:5)) else
    if (event$scope_level == "municipal_constituency") event$scope_code else ""
  parties <- rep(names(event$verified_allocation[[1L]]), event$verified_allocation[[1L]])
  slots <- tibble::tibble(election_code = event$election_code,
    electoral_area_code = event$electoral_area_code, constituency = rep(co,sizes),
    party_abbreviation = parties, party_code = paste0("fixture-",parties))
  if (event$scope_level == "municipal_constituency") {
    kept <- slots[rep(1L,48L), ]; kept$constituency <- rep(c("188001","188002","188003"),each=16L)
    kept$party_code <- "fixture-kept"; kept$party_abbreviation <- "kept"
    slots <- dplyr::bind_rows(kept,slots)
  }
  # Include an unaffected region/municipality in every full-scope test.
  if (event$scope_level != "municipal_constituency") {
    kept <- slots[1L, ];kept$electoral_area_code <- "fixture-neighbour"; kept$constituency <- ""
    slots <- dplyr::bind_rows(slots,kept)
  }
  slots <- dplyr::group_by(slots,.data$election_code,.data$electoral_area_code,
    .data$constituency,.data$party_code,.data$party_abbreviation)
  slots <- dplyr::mutate(slots,seat_number=seq_len(dplyr::n()))
  slots <- dplyr::ungroup(slots)
  a <- dplyr::count(slots,.data$election_code,.data$electoral_area_code,
    .data$constituency,.data$party_code,.data$party_abbreviation,name="seats")
  slots$candidate_number <- paste0("original-",seq_len(nrow(slots)));slots$name<-slots$candidate_number
  original <- slots
  row <- function(z,date,kind) {
    z$start_date <- date;z$end_date <- as.Date(NA);z$successor_number <- NA_character_
    z$event_date <- date;z$election_kind<-kind;z$source_file<-"synthetic-fixture"
    z$source_md5<-"fixture";z$source_as_of<-cut+365L;z$source_row<-seq_len(nrow(z));z$source_kind<-"history"
    z
  }
  old <- row(slots,day,"ordinary");affected <- .mh_component_hit(old,event)
  old$end_date[affected] <- cut
  new <- row(slots[affected, ],cut,"re_election")
  new$candidate_number <- sub("original-","new-",new$candidate_number,fixed=TRUE)
  new$name <- new$candidate_number
  h <- dplyr::bind_rows(if(omitted_original)old[!affected, ]else old,new)
  u <- dplyr::bind_rows(old[!affected, ],new)
  list(year=y,a=a,e=original,h=h,u=u,event=event,cut=cut)
}
mh_event_build <- function(z) .mh_build(z$year,z$a,z$e,z$h,z$u,NULL,NULL)

test_that("all five event scopes replace only their allocated component", {
  events <- .re_elections()
  for (i in seq_len(nrow(events))) {
    z <- mh_event_fixture(events[i, ]);x <- mh_event_build(z)
    old <- x$election_kind=="ordinary" & .mh_component_hit(x,z$event)
    new <- x$election_kind=="re_election"
    expect_equal(sum(old),z$event$seats_expected,info=z$event$scope_name)
    expect_equal(sum(new),z$event$seats_expected)
    expect_true(all(x$end_date[old]==z$cut))
    expect_true(all(x$end_reason[old]=="re_election"))
    expect_true(all(x$end_date_basis[old]=="reported"))
    expect_true(all(x$reported_end_date[old]==z$cut))
    expect_true(all(x$start_date[new]==z$cut))
    expect_true(all(x$start_reason[new]=="re_election"))
    expect_true(all(x$component_end_date[old]==z$cut))
    expect_true(all(is.na(x$end_date[!old & !new])))
    expect_false(any(x$status=="vacant"))
    expect_false(any(x$end_reason %in% c("departure","resignation","death")))
    for (d in c(-1L,0L,1L)) {
      at <- .mh_at(x,z$cut+d)
      expect_equal(nrow(at),sum(z$a$seats))
      expect_false(anyDuplicated(at$chair_id)>0L)
      expect_true(all(at$candidate_number[.mh_component_hit(at,z$event)] %in%
        if(d<0L)z$e$candidate_number else z$u$candidate_number))
    }
    if (z$event$scope_code=="188004") {
      unaffected <- x[!old & !new, ]
      expect_equal(nrow(unaffected),48L)
      expect_setequal(unaffected$constituency,c("188001","188002","188003"))
      expect_true(all(is.na(unaffected$end_date)))
    }
    if (z$event$scope_level=="region")
      expect_equal(as.integer(table(x$constituency[new])),c(50L,31L,27L,18L,23L))
  }
})

test_that("partial replacement fails rather than broadening a missing constituency", {
  event <- .re_elections()[3, ];z <- mh_event_fixture(event)
  z$e$constituency[1]<-""
  expect_error(.mh_component_hit(z$e,event),"Missing constituency for partial")
})

test_that("Bastad omits artificial zero vacancies without assuming original continuity", {
  z <- mh_event_fixture(.re_elections()[4, ],omitted_original=TRUE)
  # Exercise the separate-current/departure path that fabricated the 41 rows.
  v <- z$a[0,setdiff(names(z$a),"seats")];v$vacancy_count<-integer()
  x <- .mh_build(z$year,z$a,z$e,NULL,z$u,z$h[0, ],v)
  expect_false(any(x$status=="vacant"))
  unknown <- x[x$status=="unknown", ]
  expect_equal(nrow(unknown),41L)
  expect_true(all(unknown$interval_coverage=="unverified_continuity"))
  expect_true(all(is.na(unknown$candidate_number)))
  expect_true(all(unknown$end_date==z$cut))
  expect_true(all(unknown$start_reason=="coverage_boundary"))
  expect_true(all(unknown$end_reason=="re_election"))
  expect_true(all(unknown$start_date==.mh_election_date(2014)+1L))
  expect_false(any(x$end_date==x$start_date,na.rm=TRUE))
  p <- .mh_present(x,"en","full")
  local_mocked_bindings(.mh_history=function(...)p)
  expect_error(members_at(z$cut-1L,year=2014),"unverified holder continuity")
  expect_error(vacant_seats_at(z$cut-1L,year=2014),"unverified holder continuity")
  expect_equal(nrow(members_at(z$cut,year=2014)),42L) # includes unaffected fixture neighbour
  expect_equal(nrow(vacant_seats_at(z$cut,year=2014)),0L)
  expect_equal(nrow(members_at(.mh_election_date(2014),year=2014)),42L)
})

test_that("event reasons and scopes localize without translating names or IDs", {
  x <- mh_event_build(mh_event_fixture(.re_elections()[5, ]))
  en<-.mh_present(x,"en","full");sv<-.mh_present(x,"sv","full")
  expect_true("slutorsak" %in% names(sv))
  expect_true("omval" %in% sv$slutorsak)
  expect_identical(en,.values_en(stats::setNames(sv,names(en))))
  expect_identical(en$name,sv$namn)
  expect_identical(.mh_present(x,"en","standard"),en[names(.mh_present(x,"en","standard"))])
})

test_that("model support does not advertise unpublished 2002 or 2010 histories", {
  for (y in c(2002,2010)) {
    expect_error(mandate_history(y),"must be 2014")
    expect_error(members_at("2011-05-15",year=y),"must be 2014")
    expect_error(vacant_seats_at("2011-05-15",year=y),"must be 2014")
  }
})

test_that("dated member and vacancy queries switch populations on the event day", {
  # Synthetic tables exercise the public snapshot helper, not published coverage.
  for (i in seq_len(nrow(.re_elections()))) {
    z <- mh_event_fixture(.re_elections()[i, ])
    x <- .mh_present(mh_event_build(z),"en","full")
    local_mocked_bindings(.mh_history=function(...)x)
    before <- members_at(z$cut-1L,year=z$year)
    after <- members_at(z$cut,year=z$year)
    expect_equal(nrow(before),sum(z$a$seats))
    expect_equal(nrow(after),sum(z$a$seats))
    expect_true(all(before$status=="occupied"))
    expect_true(all(after$status=="occupied"))
    expect_equal(nrow(vacant_seats_at(z$cut,year=z$year)),0L)
    expect_equal(sum(after$election_kind=="re_election"),z$event$seats_expected)
  }
})


test_that("successive replacements close earlier event components too", {
  e <- .re_elections()[5, ];z <- mh_event_fixture(e)
  second <- e;second$election_date <- "2020-04-07";second$election_year <- 2020L
  second$election_event <- sub("2019-04-07","2020-04-07",e$election_event,fixed=TRUE)
  events <- dplyr::bind_rows(e,second)
  later <- z$h[z$h$election_kind=="re_election", ]
  later$event_date <- later$start_date <- as.Date(second$election_date)
  later$candidate_number <- paste0("second-",later$candidate_number)
  later$source_as_of <- as.Date("2021-01-01")
  z$h$source_as_of <- z$u$source_as_of <- later$source_as_of[1]
  z$h <- dplyr::bind_rows(z$h,later)
  z$u <- dplyr::bind_rows(z$u[z$u$election_kind=="ordinary", ],later)
  local_mocked_bindings(.re_elections=function()events)
  x <- mh_event_build(z)
  first <- x$event_date==as.Date(e$election_date)
  expect_true(all(x$end_date[first]==as.Date(second$election_date)))
  expect_true(all(x$component_end_date[first]==as.Date(second$election_date)))
  expect_true(all(x$end_reason[first]=="re_election"))
  expect_equal(nrow(.mh_at(x,as.Date(second$election_date))),sum(z$a$seats))
  expect_false(any(x$status=="vacant"))
})
