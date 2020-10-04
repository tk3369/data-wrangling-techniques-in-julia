# TIPS Yield Curve and Inflation Compensation
# https://www.federalreserve.gov/data/tips-yield-curve-and-inflation-compensation.htm
#
# READ
# 1. File is compressed with gzip
# 2. Header information at the top of the csv file
# 3. Missing data represetned as "NA"
#
# CLEAN
# 1. Some dates are completely missing data
# 2. Two model parameters have no value until a certain date
# 3. Using heatmap to see missing data pattern
#
# ANALYSIS
# 1. Correlation analysis
# 2. Time series analysis
#
# VISUALIZATION
# 1. Plot time series line chart for a single variable (BETA3)
# 2. Overlay plot with another line chart for a second variable
# 3. Histogram for a single time series variable
# 4. Margin histogram for two variables
# 5. Heatmap for a correlation matrix
# 6. Heatmap for finding missing data

using CSV, DataFrames, Pipe, CodecZlib, Mmap

# Decompress into a byte array first
bytes = transcode(GzipDecompressor, Mmap.mmap("data/feds200805.csv.gz"))

# this doesn't work
df = DataFrame(CSV.File(bytes))

# Let's examine the decompressed text
str = String(bytes);
split(str, "\n")[1:5]
split(str, "\n")[15:20]

# Skip the header comments
bytes = transcode(GzipDecompressor, Mmap.mmap("data/feds200805.csv.gz"))
df = DataFrame(CSV.File(bytes; header = 19))

# Why do all columns have String types?
describe(df)
show(describe(df), allrows = true)

# Let's read the file again and parse those NA's correctly
bytes = transcode(GzipDecompressor, Mmap.mmap("data/feds200805.csv.gz"))
df = DataFrame(CSV.File(bytes; header = 19, missingstring = "NA"))

# How much data is missing?
describe(df)

# Let's check all rows where BETA0 is missing
filter(:BETA0 => ismissing, df)

# How many mising values in those rows?
df240 = filter(:BETA0 => ismissing, df)
count(ismissing, Matrix(df240[:, 2:127]))
126 * 240

# Let's drop those 240 rows.
df
dropmissing!(df, :BETA0)
# filter!(:BETA0 => !ismissing, df)

# See what else is missing
meta = describe(df)
meta[meta.nmissing .> 0, :]  # see https://github.com/JuliaData/DataFrames.jl/pull/2360

# Avoid the `nothing` problem
meta[something.(meta.nmissing, 0) .> 0, :] 

sort(meta[something.(meta.nmissing, 0) .> 0, :], :nmissing; rev = true)

# BETA3 and TAU2 have more missing values
select(df, :BETA3, :TAU2)

# Confirm by plotting BETA3 over time
using Plots

plot(df.Date, df.BETA3;
    label = "BETA3", legend = :bottomleft, xrotation = 45,
    title = "BETA Observations", size = (350,250))

plot!(df.Date, df.BETA2; label = "BETA2")

# More analysis

# Check data distribution using histogram
histogram(df.TIPSPY02; bins = 50, size = (300,300), label = "TIPSPY02")

# StatsPlots has a recipe to plot the correlated distribution
using StatsPlots
@df df marginalhist(:TIPSPY02, :TIPSPY20; bins = 50, size = (300,300))

# Any correlation among the TIPS measures?
using Statistics

displaytable(stdout, names(df); index = true)

let cols = 90:108   # TIPSPY02 to TIPSPY20
    m = Matrix(df[:, cols])
    variable = names(df)[cols]
    vcv = cor(m)
    heatmap(variable, variable, vcv; 
        xticks = :all,
        yticks = :all,
        title = "Correlation Matrix (TIPSPY02 - TIPSPY20)",
        size = (600, 600),
        xrotation = 45
    )
end

# Heatmap is a great way to find patterns
# let's try to find the missing values again from beginning
df = DataFrame(CSV.File(bytes; header = 19, missingstring = "NA"))

heatmap(df.Date, names(df)[2:end], Matrix(df[:, 2:end])'; 
    yticks = :all, size=(700,1500))

# Conclusion about BETA3 and TAU2.
# There must be a model change on that date and BETA3 and TAU3 got introduced.