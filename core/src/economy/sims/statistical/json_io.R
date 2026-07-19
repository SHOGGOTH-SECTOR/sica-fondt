# json_io.R — hand-rolled JSON for the M3 Hub stdin/stdout protocol.
# No jsonlite: the only vital CRAN packages in M3a are HiddenMarkov, rugarch,
# rmgarch (spec §3). Recursive-descent parser + emitter over base R strings.

json_parse <- function(txt) {
  env <- new.env()
  env$s <- txt
  env$i <- 1L
  env$n <- nchar(txt)
  val <- .jp_value(env)
  .jp_ws(env)
  if (env$i <= env$n) stop("json_parse: trailing garbage at ", env$i)
  val
}

.jp_peek <- function(env) substr(env$s, env$i, env$i)

.jp_ws <- function(env) {
  while (env$i <= env$n && .jp_peek(env) %in% c(" ", "\t", "\n", "\r"))
    env$i <- env$i + 1L
}

.jp_expect <- function(env, ch) {
  if (.jp_peek(env) != ch)
    stop("json_parse: expected '", ch, "' at ", env$i, ", got '", .jp_peek(env), "'")
  env$i <- env$i + 1L
}

.jp_value <- function(env) {
  .jp_ws(env)
  ch <- .jp_peek(env)
  if (ch == "{") return(.jp_object(env))
  if (ch == "[") return(.jp_array(env))
  if (ch == "\"") return(.jp_string(env))
  if (ch == "t") { .jp_lit(env, "true");  return(TRUE) }
  if (ch == "f") { .jp_lit(env, "false"); return(FALSE) }
  if (ch == "n") { .jp_lit(env, "null");  return(NULL) }
  .jp_number(env)
}

.jp_lit <- function(env, lit) {
  k <- nchar(lit)
  if (substr(env$s, env$i, env$i + k - 1L) != lit)
    stop("json_parse: bad literal at ", env$i)
  env$i <- env$i + k
}

.jp_object <- function(env) {
  .jp_expect(env, "{")
  out <- list()
  .jp_ws(env)
  if (.jp_peek(env) == "}") { env$i <- env$i + 1L; return(out) }
  repeat {
    .jp_ws(env)
    key <- .jp_string(env)
    .jp_ws(env)
    .jp_expect(env, ":")
    out[[key]] <- .jp_value(env)
    .jp_ws(env)
    if (.jp_peek(env) == ",") { env$i <- env$i + 1L; next }
    .jp_expect(env, "}")
    return(out)
  }
}

.jp_array <- function(env) {
  .jp_expect(env, "[")
  out <- list()
  .jp_ws(env)
  if (.jp_peek(env) == "]") { env$i <- env$i + 1L; return(out) }
  repeat {
    out[[length(out) + 1L]] <- .jp_value(env)
    .jp_ws(env)
    if (.jp_peek(env) == ",") { env$i <- env$i + 1L; next }
    .jp_expect(env, "]")
    return(out)
  }
}

.jp_string <- function(env) {
  .jp_expect(env, "\"")
  chars <- character(0)
  repeat {
    ch <- .jp_peek(env)
    if (ch == "") stop("json_parse: unterminated string")
    env$i <- env$i + 1L
    if (ch == "\"") return(paste0(chars, collapse = ""))
    if (ch == "\\") {
      esc <- .jp_peek(env)
      env$i <- env$i + 1L
      ch <- switch(esc,
        "\"" = "\"", "\\" = "\\", "/" = "/", b = "\b", f = "\f",
        n = "\n", r = "\r", t = "\t",
        u = {
          hex <- substr(env$s, env$i, env$i + 3L)
          env$i <- env$i + 4L
          intToUtf8(strtoi(hex, 16L))
        },
        stop("json_parse: bad escape \\", esc))
    }
    chars <- c(chars, ch)
  }
}

.jp_number <- function(env) {
  m <- regmatches(
    substr(env$s, env$i, env$n),
    regexpr("^-?(0|[1-9][0-9]*)(\\.[0-9]+)?([eE][+-]?[0-9]+)?",
            substr(env$s, env$i, env$n)))
  if (length(m) == 0 || m == "") stop("json_parse: bad number at ", env$i)
  env$i <- env$i + nchar(m)
  as.numeric(m)
}

# --- emitter ----------------------------------------------------------------

json_emit <- function(x) {
  if (is.null(x)) return("null")
  if (is.list(x)) {
    if (!is.null(names(x)) && all(nzchar(names(x)))) {
      pairs <- vapply(names(x), function(k)
        paste0(.je_str(k), ":", json_emit(x[[k]])), character(1))
      return(paste0("{", paste0(pairs, collapse = ","), "}"))
    }
    return(paste0("[", paste0(vapply(x, json_emit, character(1)),
                              collapse = ","), "]"))
  }
  if (length(x) > 1)
    return(paste0("[", paste0(vapply(x, json_emit, character(1)),
                              collapse = ","), "]"))
  if (is.character(x)) return(.je_str(x))
  if (is.logical(x)) return(if (x) "true" else "false")
  if (is.numeric(x)) {
    if (!is.finite(x)) return("null")
    return(format(x, digits = 15, scientific = FALSE, trim = TRUE))
  }
  stop("json_emit: unsupported type ", class(x)[1])
}

.je_str <- function(s) {
  s <- gsub("\\", "\\\\", s, fixed = TRUE)
  s <- gsub("\"", "\\\"", s, fixed = TRUE)
  s <- gsub("\n", "\\n", s, fixed = TRUE)
  s <- gsub("\r", "\\r", s, fixed = TRUE)
  s <- gsub("\t", "\\t", s, fixed = TRUE)
  paste0("\"", s, "\"")
}
