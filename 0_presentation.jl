using CSV, DataFrames, Pipe, Dates

df = DataFrame(CSV.File("data/zhvi.csv"))
select!(df, :RegionName, 294:297)

# Select by column
select(df, :RegionName, 4:5)

# Filter (note: the data frame is in the 2nd argument)
filter(:RegionName => ==("Abilene, TX"), df)
filter("2020-01-31" => >(400_000), df)

# Sort
sort(df, :RegionName)
sort(df, :RegionName, rev = true)

# Transform (add new columns)
transform(df, :RegionName => ByRow(length) => :RegionNameLength)

# Not tidy
#=
915×5 DataFrame
│ Row │ RegionName                         │ 2020-01-31 │ 2020-02-29 │ 2020-03-31 │ 2020-04-30 │
│     │ String                             │ Float64    │ Float64    │ Float64    │ Float64    │
├─────┼────────────────────────────────────┼────────────┼────────────┼────────────┼────────────┤
│ 1   │ United States                      │ 247060.0   │ 248046.0   │ 249140.0   │ 250271.0   │
│ 2   │ New York, NY                       │ 485111.0   │ 486070.0   │ 486979.0   │ 488002.0   │
│ 3   │ Los Angeles-Long Beach-Anaheim, CA │ 675561.0   │ 680734.0   │ 685911.0   │ 690062.0   │
│ 4   │ Chicago, IL                        │ 242376.0   │ 242743.0   │ 243262.0   │ 243627.0   │
⋮
│ 911 │ Lamesa, TX                         │ 73791.0    │ 73892.0    │ 73978.0    │ 74134.0    │
│ 912 │ Craig, CO                          │ 189339.0   │ 189215.0   │ 189224.0   │ 189312.0   │
│ 913 │ Pecos, TX                          │ 106328.0   │ 107507.0   │ 108640.0   │ 109261.0   │
│ 914 │ Vernon, TX                         │ 69788.0    │ 69656.0    │ 69520.0    │ 69430.0    │
│ 915 │ Ketchikan, AK                      │ 309378.0   │ 309427.0   │ 309458.0   │ 309240.0   │
=#

# Turn to long format
# These are all the same
stack(df, Not(:RegionName); variable_name = :Date)
stack(df, Not(1); variable_name = :Date)
stack(df, 2:5; variable_name = :Date)

# Let's assign to a variable
sdf = stack(df, Not(:RegionName); variable_name = :Date)

describe(sdf, :eltype)
# Interesting type for the Date column
#=
│ Row │ variable   │ eltype                          │
│     │ Symbol     │ DataType                        │
├─────┼────────────┼─────────────────────────────────┤
│ 1   │ RegionName │ String                          │
│ 2   │ Date       │ CategoricalValue{String,UInt32} │
│ 3   │ value      │ Float64                         │
=#

typeof(sdf.Date)
#=
CategoricalArray{String,1,UInt32,String,CategoricalValue{String,UInt32},Union{}}
=#

# Let's fix it.
using Dates
sdf.Date = [Date(get(x)) for x in sdf.Date]

# Convert to wide format again?
unstack(sdf, :Date, :value)

# Group the rows by certain column(s)
groupby(sdf, :Date)

# Summarize the grouped data
combine(groupby(sdf, :Date), :value => mean => :avg)
#=
│ Row │ Date       │ avg      │
│     │ Date       │ Float64  │
├─────┼────────────┼──────────┤
│ 1   │ 2020-01-31 │ 188880.0 │
│ 2   │ 2020-02-29 │ 189514.0 │
│ 3   │ 2020-03-31 │ 190150.0 │
│ 4   │ 2020-04-30 │ 190746.0 │
=#

# Using Pipe.jl to build a transformation pipeline
@pipe sdf |>
    groupby(_, :Date) |>
    combine(_, :value => mean => :avg)

# Row-wise computation
select(df,
    :RegionName,
    ["2020-01-31", "2020-02-29"] => ByRow(-) => :JanFebDiff)

# Joins

# Let’s say we have a reference data frame
country = DataFrame(Name = ["United States"])

# Joining data is easy
innerjoin(df, country, on = [:RegionName => :Name])
leftjoin(df, country, on = [:RegionName => :Name])
rightjoin(df, country, on = [:RegionName => :Name])
outerjoin(df, country, on = [:RegionName => :Name])

semijoin(df, country, on = [:RegionName => :Name])
antijoin(df, country, on = [:RegionName => :Name])
