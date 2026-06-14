# The grain value library: a known band schedule must price a known outcome
# into the expected band, and a known payoff must drive the expected optimal
# decision. The library wraps decideR's grade_band_value, so these tests also
# confirm the wrapping preserves the band-edge convention.

test_that("wheat_protein_bands prices outcomes into the right grade", {
  v <- wheat_protein_bands()
  # default breaks c(10.5, 11.5, 13), values c(300, 330, 360, 400), left-closed
  expect_equal(v(9.5), 300)        # feed
  expect_equal(v(10.5), 330)       # on the break clears into ASW
  expect_equal(v(11.0), 330)       # ASW
  expect_equal(v(11.5), 360)       # clears into APW
  expect_equal(v(13.4), 400)       # AH/APH
  expect_s3_class(v, "grade_band_value")
})

test_that("wheat_protein_bands labels the default grid with grade names", {
  v <- wheat_protein_bands()
  labs <- attr(v, "labels")
  expect_true(any(grepl("ASW", labs)))
  expect_true(any(grepl("APW", labs)))
  expect_length(labs, 4L)
})

test_that("wheat_protein_bands rejects a mis-sized values vector", {
  expect_error(wheat_protein_bands(breaks = c(10.5, 11.5),
                                   values = c(300, 330, 360, 400)),
               "one more element")
  expect_error(wheat_protein_bands(breaks = c(11.5, 10.5)),
               "strictly increasing")
})

test_that("barley_malting_premium pays the premium only inside the window", {
  v <- barley_malting_premium(window = c(9.5, 12.5), feed_price = 280,
                              malting_premium = 60)
  expect_equal(v(8.0), 280)        # below window -> feed
  expect_equal(v(10.5), 340)       # in window -> feed + premium
  expect_equal(v(9.5), 340)        # on lower edge clears into malting
  expect_equal(v(13.0), 280)       # above window -> feed
  expect_equal(v(12.5), 280)       # on upper edge falls out of malting
})

test_that("barley_malting_premium validates its window and prices", {
  expect_error(barley_malting_premium(window = c(12.5, 9.5)), "increasing")
  expect_error(barley_malting_premium(window = 10), "length-two")
  expect_error(barley_malting_premium(feed_price = -1), "non-negative")
})

test_that("n_rate_economics builds the profit utility correctly", {
  e <- n_rate_economics(price_grain = 350, price_n = 1.3)
  expect_s3_class(e, "n_rate_economics")
  # profit = 350 * yield - 1.3 * rate
  expect_equal(e$utility(rate = 80, yield = c(4, 5)),
               c(350 * 4 - 1.3 * 80, 350 * 5 - 1.3 * 80))
  expect_error(n_rate_economics(price_grain = -1, price_n = 1),
               "non-negative")
})

test_that("a known payoff drives the expected optimal grade decision", {
  # Construct a deterministic-enough quality posterior where pushing the input
  # clearly clears a high-value band: a strong protein lift, a generous band
  # step, and a tiny cost, so the top action must win.
  set.seed(42L)
  protein <- stats::rnorm(4000L, mean = 10.6, sd = 0.2)
  v <- wheat_protein_bands(breaks = c(11.5), values = c(300, 500))
  gd <- plan_grade_target(
    protein, actions = c(0, 50), value = v,
    quality_shift = function(rate, p) p + 0.05 * rate,   # +2.5 protein at 50
    cost = 0.1, grounding = decideR::grounding_grounded())
  # action 50 lifts mean protein from ~10.6 to ~13.1, clearing the 11.5 break
  # for almost all draws -> the high band -> it must be chosen over 0.
  expect_false(gd@abstained)
  expect_equal(gd@action, 50)
})
