# Youth_Suicide_Deaths_in_Washington_State_by_Gender_Age_0-17_Years__from_2008-2012.csv
# State of Washington — Youth Suicide Deaths in Washington State by Gender Age 0-17 Years, from 2008-2012
# https://catalog.data.gov/dataset/youth-suicide-deaths-in-washington-state-by-gender-age-0-17-years-from-2008-2012
#
# CLEAN
# 1. Too much unnecessary data
#
# TIDY
# 1. Values are in the columns
# 2. Multiple values in the same column (after stack)
#
# VISUALIZE
# 1. Bar chart - King county male youth suicides
# 2. Grouped Bar chart - King county youth suicides
# 3. Line chart - five year suicide trend by gender
# 4. Heatmap - county/year suicides

using DataFrames, CSV, Pipe, TabularDisplay

df = DataFrame(CSV.File("data/youth_suicide.csv"))

# Examine column names
names(df)
displaytable(stdout, names(df); index = true)
df

# Both Male/Female and Year are encoded in the columns
# Normally, time series are represented in rows as they're separate observations.
# Let's convert to long form first.
sdf = stack(df, 2:19; variable_name = :type_year)

# Now, spread it into two separate columns
sdf.type = [split(x, " ")[1] for x in sdf.type_year]
sdf.year = [split(x, " ")[2] for x in sdf.type_year]
deletecols!(sdf, :type_year)

# Let's check if the Total type really contains the total
# Pick a county.
sdf[sdf.County .== "Yakima", :]

# Remove the multi-year data since they're derivable
sdf = @pipe sdf |>
    filter(:type => !=("Total"), _) |>
    filter(:year => !=("(2008-2012)"), _)

# Check Yakima again
sdf[sdf.County .== "Yakima", :]

# Check unique values of year again
unique(sdf.year)

# Convert the year column to integer
sdf.year = [parse(Int, replace(x, r"[()]" => "")) for x in sdf.year]
sdf[sdf.County .== "Yakima", :]

# Examine
describe(sdf, :eltype, :min, :max, :nunique, :nmissing)
sdf

# Male and Female variables can be put back as columns now
df = unstack(sdf, :type, :value)
df[df.County .== "Yakima", :]

# Now, it's all tidy!

using Plots, StatsPlots

# Plot King county's yearly rate

filter(:County => ==("King"), df)

@pipe df |>
    filter(:County => ==("King"), _) |>
    bar(_.year, _.Male, 
        title = "King County Youth Suicides (Male)",
        legend = :none,
        size = (300, 300))

# Prepare to plot both Male and Female together
df_stacked = stack(df, 3:4; variable_name = "gender")

filter(:County => ==("King"), df_stacked)

@pipe df_stacked |>
    filter(:County => ==("King"), _) |>
    groupedbar(    # StatsPlots.jl
        _.year,    # x-axis
        _.value;   # y-axis
        group = _.gender,
        bar_position = :stack,
        bar_width = 0.7,
        title = "King County Suicides",
        size = (300, 300),
        legend = :topleft)

# Let's try grouping function
df
@pipe df |>
    groupby(_, :County)

# 5 year totals
@pipe df |>
    groupby(_, :County) |>
    combine(_, :Female => sum, :Male => sum)

# 5 year totals with male/female combined
@pipe df |>
    groupby(_, :County) |>
    combine(_, :Female => sum, :Male => sum) |>
    select(_, :County, [:Female_sum, :Male_sum] => ByRow(+) => :Total)

# Just for fun, can we transpose the original data frame?
# @pipe df |>
#     groupby(_, :year) |>
#     combine(_, :Female => sum => :Female, :Male => sum => :Male) |>
#     stack(_, 2:3; variable_name = :gender) |>
#     unstack(_, :year, :value)

# Let's plot more charts

let 
    data = @pipe df |>
        groupby(_, :year) |>
        combine(_, :Female => sum => :Female, :Male => sum => :Male) |>
        stack(_, 2:3; variable_name = :gender, value_name = :suicides) 
    plot(data.year, data.suicides; groups = data.gender,
        title = "Youth Suicides Trend",
        legend = :topleft,
        linewidth = 3,
        size = (300, 300))
end

# Heatmap to show suicide stats by (year, county)
let
    data = @pipe df |>
        select(_, :County, :year, [:Female, :Male] => ByRow(+) => :total) |>
        unstack(_, :year, :total)
    values = Matrix(data[:, 2:6])'
    StatsPlots.heatmap(2008:2012, data.County, values;
        title = "Youth Suicide Heatmap",
        xticks = :all,
        yticks = :all,
        size = (400, 600))
end