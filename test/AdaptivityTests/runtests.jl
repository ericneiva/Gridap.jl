module AdaptivityTests

using Test

@testset "AdaptedGeometry" begin
  include("RefinementRulesTests.jl")
  include("AdaptedGeometryTests.jl")
end

@testset "Refinement" begin
  include("CartesianRefinementTests.jl")
  include("EdgeBasedRefinementTests.jl")
  include("FineToCoarseFieldsTests.jl")
end

@testset "CompositeQuadratures" begin
  include("CompositeQuadratureTests.jl")
end

@testset "MultiFields" begin
  include("MultifieldGridTransferTests.jl")
end

end # module