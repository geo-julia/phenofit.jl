using DataFrames, CSV
using phenofit
using Lazy, Query
using Printf
using Dates
# TabularDisplay, DataFramesMeta
# Pipe

# replace()
set_value!(x, con, value) = begin
    x[con] .= value
    Nothing
end

begin
    df = DataFrame(CSV.File("/mnt/n/Research/phenology/fluxtidy2/data-raw/RS_VI/flux212_Terra-LAI_MOD15A2_raw (20200827).csv"))
    df = df[!, [:site, :date, :Lai_500m, :FparLai_QC, :FparExtra_QC]] |> 
        @rename(:Lai_500m => :y, :FparLai_QC => :QC, :FparExtra_QC => :QC_Extra) |> 
        @mutate(y = _.y/10) |> 
        @replacena(:y => -0.1) |> 
        @replacena(:QC_Extra => 127) |> 
        @filter(_.date >= Date("2015-01-01")) |> 
        DataFrame
    # df = df |> 
    df.QC_Extra = convert.(UInt8, df.QC_Extra);
    set_value!(df.y, df.y .> 10, -0.1)
end
# clamp!(df.y, -1, 10.0);
# set_value!(df.QC_Extra, )
# df[df.Lai_500m .=== missing, :]
describe(df) # summary(df)

# df[df.y .=== missing, :Lai_500m] = -10
# df[df.Lai_500m .=== missing, :Lai_500m] = 0
sites = unique(df.site)
sitename = sites[1]

# df |> @filter(_.site == sitename)
using Plots
pyplot()

res = []
# for sitename = sites
for i in 1:length(sites)
    # println(i)
    sitename = sites[i]    
    # 1. Interp NA values first
    d = df[df.site .== sitename, Not([:site])]

    prefix = @sprintf("[%03d_%s]", i, sitename)
    outfile = "Figures/$prefix flux166-LAI.pdf"
    println(outfile)
    y2 = smooth_whit(d[:, :y], d.QC_Extra, d.date; 
        outfile = outfile, title = prefix, 
        trs_high = 0.7, trs_low = 0.4, trs_bg = 0.2, 
        step = 0.3)
    push!(res, y2)
end
merge_pdf("Figures/*.pdf", "flux166_Terra-LAI phenofit-v0.1.2.pdf", is_del = true)

# using FileIO
# save("LAI_smoothed.jld", Dict("res" => res))
# save("LAI_smoothed2.jld", res)
# 
# mat = hcat(res)
# CSV.write(mat, "flux166_LAI-smoothed.csv")
