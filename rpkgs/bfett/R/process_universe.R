#' Process universe
#'
#' Takes PDF from Lang & Schwarz, i.e. https://www.ls-x.de/media/lsx/stammdaten20250418.pdf
#' and converts it to data.frame
#'
#' @param univ_pdf path to LS trade universum
#' @param seeds character, path to seeds folder of the dbt project, default dirname(transactions)
#' @param verbose, logical, print diagnostic messages
#' @return NULL, used for its side effects
#' @export
process_universe <- function(univ_pdf, seeds, verbose=FALSE) {
	stopifnot(file.exists(univ_pdf), dir.exists(seeds))
	
	all_pages <- pdftools::pdf_text(univ_pdf)
	
	j <- 1
	one_page <- function(pg) {
		if(verbose) message("page=", j)
		j <<- j + 1
		pg <- strsplit(pg, "\n")[[1]]
		i <- which(grepl("^WKN", pg))
		if(length(i)==0) return(data.table::data.table())
		
		# header vs. content
		content <- utils::tail(pg, -i)
		content <- content[!grepl("^\\S*$", content)]
		header <- pg[i]
		start_pos <- gregexpr("\\S+", header)[[1]]
		end_pos <- c(utils::tail(start_pos, -1)-1, 300)
		n_col <- length(start_pos)
		header <- sapply(1:n_col, \(i) tolower(trimws(substr(header, start_pos[i], end_pos[i]))))
		
		# make it data.frame
		one_row <- function(r) sapply(1:n_col, \(i) trimws(substr(r, start_pos[i], end_pos[i])))	
		ans <- sapply(content, one_row)
		ans <- as.data.frame(t(ans))
		colnames(ans) <- header
		rownames(ans) <- NULL
		ans <- ans[,header[1:6]] |>
			subset(nchar(isin)>0) 
			
		# some problems with wkn
		wkn <- strsplit(ans[,"wkn"], " ") 
		fixed_wkn <- sapply(wkn, \(s) if(length(s)==1) s else s[1])
		fixed_isin <- sapply(1:length(wkn),	\(i) {
			if(length(wkn[[i]])==1) ans[i,"isin"]
			else paste0(wkn[[i]][2], ans[i,"isin"])
		})
		ans[,"wkn"] <- fixed_wkn
		ans[,"isin"] <- fixed_isin
		if(verbose && j==96) browser()
		
		# fix indexzugehoerigkeit
		i <- which(grepl("^indexzugeh", colnames(ans)))
		stopifnot(length(i)>0)
		colnames(ans)[i] <- "index_membership"
		ans <- transform(ans, 
			index_membership=ifelse(index_membership %in% c("null", "2"), NA, index_membership)
		)
		
		ans
		
	}
	
	lapply(all_pages, one_page) |>
	data.table::rbindlist() |>
	utils::write.csv(file=file.path(seeds, "isin_info.csv"), na="", row.names=FALSE)

}

	
