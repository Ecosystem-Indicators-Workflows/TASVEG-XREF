read_membership_tbl <- function(data, ...) {
  if (is.data.frame(data)) {
    indata <- tibble::as_tibble(data)
    data_label <- "data frame supplied in session"
  } else {
    if (!is.character(data) || length(data) != 1) {
      stop("DATA_INPUT must be a file path or a data frame.")
    }
    if (!file.exists(data)) {
      stop("File not found: ", data)
    } else {
      data_label <- basename(data)

      ext <- tolower(tools::file_ext(data))
      indata <- switch(
        ext,
        csv = readr::read_csv(data, show_col_types = FALSE),
        xlsx = ,
        xls = readxl::read_excel(data),
        stop(
          "Unsupported file type '.",
          ext,
          "'; use .csv, .xlsx, or pass a data frame."
        )
      )
    }
  }
  outdata <- membership_tbl(indata, ...)
  msg <- sprintf("Read %s rows from %s", nrow(outdata), data_label)
  message(msg)
  return(outdata)
}


pairwise_dissimilarity <- function(x) {
  stopifnot(inherits(x, "membership_tbl"))

  i_col <- attr(x, "interpreter")
  s_col <- attr(x, "source_id")
  t_col <- attr(x, "target_id")
  m_col <- attr(x, "membership")

  interp <- rlang::sym(i_col)
  interp_a <- rlang::sym(paste(i_col, "a", sep = "_"))
  interp_b <- rlang::sym(paste(i_col, "b", sep = "_"))
  sid <- rlang::sym(s_col)
  tid <- rlang::sym(t_col)
  memb <- rlang::sym(m_col)
  memb_a <- rlang::sym(paste(m_col, "a", sep = "_"))
  memb_b <- rlang::sym(paste(m_col, "b", sep = "_"))

  profiles <- x |>
    dplyr::group_by(!!sid) |>
    tidyr::complete(!!interp, !!tid, fill = list(memb = 0)) |>
    dplyr::ungroup()

  pairwise <- profiles |>
    dplyr::inner_join(
      profiles,
      by = c(s_col, t_col),
      suffix = c("_a", "_b"),
      relationship = "many-to-many"
    ) |>
    dplyr::filter(!!interp_a < !!interp_b) |>
    dplyr::group_by(!!sid, !!interp_a, !!interp_b) |>
    dplyr::summarise(
      dissimilarity = 0.5 * sum(abs(!!memb_a - !!memb_b)),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      similarity = 1 - dissimilarity,
      pair = paste(!!interp_a, !!interp_b, sep = " – ")
    )
  structure(
    pairwise,
    source_id = s_col,
    interpreter_a = interp_a,
    interpreter_b = interp_b,
    class = c("pairwise_diss", class(pairwise))
  )
}

plot_pairwise_diss <- function(x) {
  stopifnot(inherits(x, "pairwise_diss"))
  ia_col <- attr(x, "interpreter_a")
  ib_col <- attr(x, "interpreter_b")
  ia <- rlang::sym(ia_col)
  ib <- rlang::sym(ib_col)
  gp <- ggplot(pd, aes(x = similarity)) +
    geom_histogram(binwidth = 0.2) +
    facet_grid(rows = vars(!!ia), cols = vars(!!ib))
  return(gp)
}
