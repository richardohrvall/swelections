# Opt-in complete preserved sources: SWEELECTIONS_REF2003_ROOT and _CANONICAL.
test_that('complete 2003 final geography and official controls are preserved', {
 root<-Sys.getenv('SWEELECTIONS_REF2003_ROOT')
 skip_if(!nzchar(root)||!file.exists(file.path(root,'final.xml')), 'Preserved 2003 referendum archive not configured')
 x<-results(2003,election='referendum',level='district',source='local',data_dir=root,detail='full')
 units<-x[!duplicated(x$district_code),]
 expect_equal(nrow(units),6372L)
 expect_equal(sum(units$district_type=='ordinary'),5976L)
 expect_equal(sum(units$district_type=='wednesday'),396L)
 expect_equal(length(unique(units$municipality_code)),290L)
 expect_equal(sum(x$votes[x$voting_option_code=='JA']),2453899L)
 expect_equal(sum(x$votes[x$voting_option_code=='NEJ']),3265341L)
 expect_equal(sum(x$votes[x$voting_option_code=='BLANK']),121073L)
 expect_equal(sum(units$invalid_votes),3475L)
 expect_equal(sum(units$total_votes),5843788L)
 expect_true(all(is.na(units$turnout[units$district_type=='wednesday'])))
 expect_true(all(is.na(units$eligible_voters[units$district_type=='wednesday'])))
 expect_false(any(grepl('party',names(x))))
 expect_identical(x$valid_votes+x$invalid_votes,x$total_votes)
 counts<-c(national=1L,county=21L,parliamentary_constituency=29L,municipality=290L,municipal_constituency=185L)
 for(level in names(counts)){
  full<-results(2003,election='referendum',level=level,source='local',data_dir=root,detail='full')
  standard<-results(2003,election='referendum',level=level,source='local',data_dir=root)
  expect_equal(nrow(full),3L*counts[[level]])
  expect_identical(standard,full[names(standard)])
 }
})
