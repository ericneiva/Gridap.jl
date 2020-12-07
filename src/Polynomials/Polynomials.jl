"""
This module provides a collection of multivariate polynomial bases.

The exported names are:

$(EXPORTS)
"""
module Polynomials

using DocStringExtensions
using LinearAlgebra: mul!
using PolynomialBases: jacobi, jacobi_and_derivative
using Gridap.Helpers
using Gridap.Arrays
using Gridap.TensorValues
using Gridap.Fields

import Gridap.Fields: evaluate!
import Gridap.Fields: return_cache
import Gridap.Arrays: return_type

export MonomialBasis
export ModalC0Basis
export ModifiedModalC0Basis
export QGradMonomialBasis
export QCurlGradMonomialBasis
export get_exponents

export get_order
export get_orders
export num_terms

include("MonomialBases.jl")

include("ModalC0Bases.jl")

include("ModifiedModalC0Bases.jl")

include("QGradMonomialBases.jl")

include("QCurlGradMonomialBases.jl")

end # module
