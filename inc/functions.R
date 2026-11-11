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

# method to use different formulas, preferably jaccard
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

clean_membership <- function(x, source, target) {
  stopifnot(inherits(x, "membership_tbl"))
  stopifnot(inherits(source, "lookup_tbl"))
  stopifnot(inherits(target, "lookup_tbl"))

  membership <- attr(x, "membership")

  m <- x[[membership]]
  f1 <- is.na(m)
  f2 <- !f1 & (m < 0 | m > 1)

  source_id <- attr(x, "source_id")
  sid <- x[[source_id]]
  vid <- rlang::sym(attr(source, "id"))
  elig <- rlang::sym(attr(source, "eligible"))
  eid <- dplyr::filter(source, !!elig) |> dplyr::pull(!!vid)
  f3 <- !(sid %in% eid)

  target_id <- attr(x, "target_id")
  tid <- x[[target_id]]
  vid <- attr(target, "id")
  elig <- attr(target, "eligible")
  eid <- target[[vid]][target[[elig]]]
  f4 <- !(tid %in% eid)

  if (any(f1)) {
    message(sprintf("Flagged %s records with `NA`", sum(f1)))
  }
  if (any(f2)) {
    message(sprintf("Flagged %s records outside bounds [0,1]", sum(f2)))
  }
  if (any(f3)) {
    message(sprintf("Flagged %s records with not eligible source ids", sum(f3)))
  }
  if (any(f4)) {
    message(sprintf("Flagged %s records with invalid target ids", sum(f4)))
  }
  if (any(f1 | f2 | f3 | f4)) {
    message(sprintf(
      "Removed %s records with one or more flags",
      sum(f1 | f2 | f3 | f4)
    ))
  } else {
    message("No records removed")
  }
  res <- dplyr::filter(x, !f1 & !f2 & !f3 & !f4)
  res
}

pivot_wide_membership_table <- function(
  xref,
  original_names,
  target_names,
  membership_values,
  expert_name = NULL,
  round_nr = NULL
) {
  memb_table <- xref |>
    dplyr::select(
      dplyr::any_of(original_names),
      dplyr::any_of(target_names),
      dplyr::any_of(membership_values)
    ) |>
    tidyr::pivot_longer(
      dplyr::any_of(c(target_names, membership_values)),
      cols_vary = "slowest",
      names_to = c(".value"),
      names_pattern = "([[:alpha:]]+)"
    )

  if (!is.null(expert_name)) {
    memb_table <- mutate(memb_table, expert = expert_name)
  }
  if (!is.null(round_nr)) {
    memb_table <- mutate(memb_table, round = round_nr)
  }
  return(memb_table)
}

pivot_membership_matrix <- function(
  xref,
  original_names,
  target_names,
  expert_name = NULL,
  round_nr = NULL
) {
  memb_table <- xref |>
    tidyr::pivot_longer(
      dplyr::any_of(target_names),
      names_to = "EFG",
      values_to = "memb"
    )
  if (!is.null(expert_name)) {
    memb_table <- mutate(memb_table, expert = expert_name)
  }
  if (!is.null(round_nr)) {
    memb_table <- mutate(memb_table, round = round_nr)
  }
  return(memb_table)
}

summary_disagreement <- function(x) {
  sid <- rlang::sym(attr(x, "source_id"))

  out <- x |>
    dplyr::group_by(!!sid) |>
    dplyr::summarise(
      mean_dissimilarity = mean(dissimilarity),
      min_dissimilarity = min(dissimilarity),
      max_dissimilarity = max(dissimilarity),
      n_pairs = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::arrange(dplyr::desc(mean_dissimilarity), !!sid)

  msg <- "%s of %s units have identical profiles from every interpreter."

  message(
    sprintf(
      msg,
      sum(out$max_dissimilarity < 0.001),
      nrow(out)
    )
  )
  return(out)
}


qml_styler <- function(cat_table, attribute, output_file) {
  ## based on Kay Cichini's qml-styler.R
  ## https://github.com/gimoya/theBioBucket-Archives/blob/master/R/qml_styler.R
  base <- newXMLNode("qgis")
  addAttributes(
    base,
    version = "3.34.0",
    styleCategories = "Symbology|Labeling",
    labelsEnabled = "0"
  )
  trans <- newXMLNode("transparencyLevelInt", 255)
  rend <- newXMLNode(
    "renderer-v2",
    attrs = c(attr = attribute, symbollevels = "0", type = "categorizedSymbol")
  )

  # sort the categories
  categories <- newXMLNode("categories")
  category <- lapply(seq_along(cat_table$value), function(x) {
    newXMLNode(
      "category",
      attrs = c(
        symbol = as.character(x - 1),
        value = cat_table$value[x],
        label = cat_table$label[x],
        render = "true",
        type = "string"
      )
    )
  })
  addChildren(categories, category)

  # sort the symbols
  symbols <- newXMLNode("symbols")
  symbol <- lapply(seq_along(cat_table$value), function(x) {
    dum.sym <- newXMLNode(
      "symbol",
      attrs = c(
        alpha = cat_table$alpha[x],
        type = "fill",
        name = as.character(x - 1),
        clip_to_extent = "1",
        force_rhr = "0"
      )
    )
    layer <- newXMLNode(
      "layer",
      attrs = c(
        pass = "0",
        class = "SimpleFill",
        locked = "0"
      )
    )
    prop <- newXMLNode("Option", attrs = c(type = "Map"))
    addChildren(
      prop,
      newXMLNode(
        "Option",
        attrs = c(type = "QString", name = "color", value = cat_table$colour[x])
      )
    )
    addChildren(
      prop,
      newXMLNode(
        "Option",
        attrs = c(
          type = "QString",
          name = "outline_color",
          value = "250,250,230,255"
        )
      )
    )

    addChildren(
      prop,
      newXMLNode(
        "Option",
        attrs = c(type = "QString", name = "outline_style", value = "solid")
      )
    )
    addChildren(
      prop,
      newXMLNode(
        "Option",
        attrs = c(type = "QString", name = "outline_width", value = "0.26")
      )
    )
    addChildren(layer, prop)
    addChildren(dum.sym, layer)
  })

  addChildren(symbols, symbol)

  # add categories and symbols to rend
  addChildren(rend, list(categories, symbols))
  addChildren(base, list(trans, rend))

  # save to qml-file
  writeLines(saveXML(base), output_file)
  #return(base)
}
