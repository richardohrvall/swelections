.libPaths(c(normalizePath(".r-lib"),.libPaths()))
pkgload::load_all(".",quiet=TRUE)
s <- swelections:::.sources_2010("local",".local-data/rkl")
for (v in c("RD","RF","KF")) {
 cat("START",v,"\n");flush.console()
 b <- swelections:::.xml2014_bundle(s,v,FALSE)
 cat("BUNDLE",v,nrow(b$kd),nrow(b$population),nrow(b$relations$valda),nrow(b$relations$ersattare),"\n");flush.console()
 x <- swelections:::.kandidater_2014(s,v,TRUE,FALSE,b)
 print(table(x$antal_personroster_totalt>0,useNA="always"));flush.console()
 saveRDS(list(b=b,candidates=x),paste0(".local-data/2010-smoke-",v,".rds"))
}
