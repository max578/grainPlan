# Print nitrogen-rate economics

Print nitrogen-rate economics

## Usage

``` r
# S3 method for class 'n_rate_economics'
print(x, ...)
```

## Arguments

- x:

  An
  [n_rate_economics](https://max578.github.io/grainPlan/reference/n_rate_economics.md)
  object.

- ...:

  Ignored, for compatibility with
  [`print()`](https://rdrr.io/r/base/print.html).

## Value

`x`, invisibly.

## Examples

``` r
print(n_rate_economics(price_grain = 350, price_n = 1.3))
#> $price_grain
#> [1] 350
#> 
#> $price_n
#> [1] 1.3
#> 
#> $utility
#> function (rate, yield) 
#> price_grain * yield - price_n * rate
#> <bytecode: 0x56007338f648>
#> <environment: 0x560076d7f1a8>
#> 
#> attr(,"class")
#> [1] "n_rate_economics"
```
