module EdgeBasedRefinementTests

using Test
using Gridap
using Gridap.Geometry
using Gridap.CellData
using Gridap.Adaptivity
using Gridap.ReferenceFEs
using FillArrays

function test_grid_transfers(D,parent,model)
  sol(x) = sum(x)

  # Triangulations
  trian = Triangulation(model)
  ctrian = Triangulation(parent)

  glue = get_adaptivity_glue(model)
  rrules = Adaptivity.get_old_cell_refinement_rules(glue)

  # Measures
  dΩ_f  = Measure(trian,qorder)
  dΩ_c  = Measure(ctrian,qorder)
  dΩ_cf = Measure(ctrian,trian,qorder)

  cell_quad = Gridap.CellData.get_cell_quadrature(dΩ_cf)
  dΩ_cf_bis = Measure(ctrian,trian,cell_quad)

  # FESpaces
  reffe = ReferenceFE(lagrangian,Float64,order)
  V_f = TestFESpace(model,reffe;dirichlet_tags="boundary")
  U_f = TrialFESpace(V_f,sol)
  V_c = TestFESpace(parent,reffe;dirichlet_tags="boundary")
  U_c = TrialFESpace(V_c,sol)
  V_c_fast = TestFESpace(parent,rrules,reffe;dirichlet_tags="boundary")
  U_c_fast = TrialFESpace(V_c,sol)

  # CellField: Coarse -> Fine
  cf_c_phy = CellField(sol,ctrian)
  cf_c_ref = change_domain(cf_c_phy,PhysicalDomain(),ReferenceDomain())
  cf_f_ref_ref = change_domain(cf_c_ref, trian, ReferenceDomain())
  cf_f_ref_phy = change_domain(cf_c_ref, trian, PhysicalDomain())
  cf_f_phy_ref = change_domain(cf_c_phy, trian, ReferenceDomain())
  cf_f_phy_phy = change_domain(cf_c_phy, trian, PhysicalDomain())

  pts = map(x -> VectorValue(rand(D)),1:10)
  v_r = map(p -> sol(p) , pts)
  v_c = map(p -> cf_c_ref(p), pts)
  v_f_ref_ref = map(p -> cf_f_ref_ref(p), pts)
  v_f_ref_phy = map(p -> cf_f_ref_phy(p), pts)
  v_f_phy_ref = map(p -> cf_f_phy_ref(p), pts)
  v_f_phy_phy = map(p -> cf_f_phy_phy(p), pts)
  @test v_r ≈ v_c
  @test v_r ≈ v_f_ref_ref
  @test v_r ≈ v_f_ref_phy
  @test v_r ≈ v_f_phy_ref
  @test v_r ≈ v_f_phy_phy

  # CellField: Fine -> Coarse
  cf_f_phy = CellField(sol,trian)
  cf_f_ref = change_domain(cf_f_phy,PhysicalDomain(),ReferenceDomain())
  cf_c_ref_ref = change_domain(cf_f_ref, ctrian, ReferenceDomain())
  cf_c_ref_phy = change_domain(cf_f_ref, ctrian, PhysicalDomain())
  cf_c_phy_ref = change_domain(cf_f_phy, ctrian, ReferenceDomain())
  cf_c_phy_phy = change_domain(cf_f_phy, ctrian, PhysicalDomain())

  pts = map(x -> VectorValue(rand(D)),1:10)
  v_r = map(p -> sol(p) , pts)
  v_f = map(p -> cf_f_ref(p), pts)
  v_c_ref_ref = map(p -> cf_c_ref_ref(p), pts)
  v_c_ref_phy = map(p -> cf_c_ref_phy(p), pts)
  v_c_phy_ref = map(p -> cf_c_phy_ref(p), pts)
  v_c_phy_phy = map(p -> cf_c_phy_phy(p), pts)
  @test v_r ≈ v_f
  @test v_r ≈ v_c_ref_ref
  @test v_r ≈ v_c_ref_phy
  @test v_r ≈ v_c_phy_ref
  @test v_r ≈ v_c_phy_phy

  # Coarse FEFunction -> Fine CellField
  uh_c = interpolate(sol,U_c)
  cf_f2 = change_domain(uh_c,trian,ReferenceDomain())
  v_f2 = map(p -> cf_f2(p), pts)
  @test v_r ≈ v_f2

  # Coarse FEBasis -> Fine CellField
  feb_c = get_fe_basis(V_c)
  feb_c2f = change_domain(feb_c,trian,ReferenceDomain())

  # Coarse FEFunction -> Fine FEFunction, by interpolation
  uh_f_inter  = interpolate(uh_c,U_f)
  uh_f_inter2 = interpolate_everywhere(uh_c,U_f)
  uh_f_inter3 = interpolate_dirichlet(uh_c,U_f)

  v_f_inter  = map(p -> uh_f_inter(p), pts)
  v_f_inter2 = map(p -> uh_f_inter2(p), pts)
  @test v_r ≈ v_f_inter
  @test v_r ≈ v_f_inter2

  # Fine FEFunction -> Coarse FEFunction, by interpolation
  uh_f = interpolate(sol,U_f)
  uh_c_inter  = interpolate(uh_f,U_c)
  uh_c_inter2 = interpolate_everywhere(uh_f,U_c)
  uh_c_inter3 = interpolate_dirichlet(uh_f,U_c)
  uh_c_inter4  = interpolate(uh_f,U_c_fast)

  v_c_inter  = map(p -> uh_c_inter(p), pts)
  v_c_inter2 = map(p -> uh_c_inter2(p), pts)
  v_c_inter4 = map(p -> uh_c_inter4(p), pts)
  @test v_r ≈ v_c_inter
  @test v_r ≈ v_c_inter2
  @test v_r ≈ v_c_inter4

  # Coarse FEFunction -> Fine FEFunction, by projection
  af(u,v)  = ∫(v⋅u)*dΩ_f
  lf(v)    = ∫(v⋅uh_c)*dΩ_f
  opf      = AffineFEOperator(af,lf,U_f,V_f)
  uh_f_pr = solve(opf)

  v_f_pr = map(p -> uh_f_pr(p), pts)
  @test v_r ≈ v_f_pr

  eh = sum(∫(uh_f-uh_f_pr)*dΩ_f)
  @test eh < 1.e8

  # Fine FEFunction -> Coarse FEFunction, by projection
  ac(u,v) = ∫(v⋅u)*dΩ_c
  lc(v)   = ∫(v⋅uh_f_inter)*dΩ_cf
  opc     = AffineFEOperator(ac,lc,U_c,V_c)
  uh_c_pr = solve(opc)

  v_c_pr = map(p -> uh_c_pr(p), pts)
  @test v_c_pr ≈ v_r

  eh = sum(∫(uh_f_inter-uh_c_pr)*dΩ_c)
  @test eh < 1.e8
end

visualize = false
model_pairs = []

# Refining meshes of QUADs
cart_model = CartesianDiscreteModel((0,1,0,1),(4,4))
model1     = UnstructuredDiscreteModel(cart_model)

## Homogeneous refinement
ref_model1 = refine(model1)
trian1 = Triangulation(ref_model1.model)
visualize && writevtk(trian1,"test/AdaptivityTests/ref_model1")
test_grid_transfers(2,model1,ref_model1)

## Propagate to all-red
ref_model2 = refine(model1;cells_to_refine=[1,6,11,16])
trian2 = Triangulation(ref_model2.model)
visualize && writevtk(trian2,"test/AdaptivityTests/ref_model2")
test_grid_transfers(2,model1,ref_model2)

## Red-Green refinement
ref_model3 = refine(model1;cells_to_refine=[1,6,16])
trian3 = Triangulation(ref_model3.model)
visualize && writevtk(trian3,"test/AdaptivityTests/ref_model3")
#test_grid_transfers(2,model1,ref_model3)

ref_model4 = refine(model1;cells_to_refine=[6,7,10,11])
trian4 = Triangulation(ref_model4.model)
visualize && writevtk(trian4,"test/AdaptivityTests/ref_model4")
#test_grid_transfers(2,model1,ref_model4)

# Refining meshes of TRIans
model2 = simplexify(model1)
visualize && writevtk(Triangulation(model2),"test/AdaptivityTests/base_model2")

ref_model5 = refine(model2)
trian5 = Triangulation(ref_model5.model)
visualize && writevtk(trian5,"test/AdaptivityTests/ref_model5")
test_grid_transfers(2,model2,ref_model5)

ref_model6 = refine(model2;cells_to_refine=[1,6,16])
trian6 = Triangulation(ref_model6.model)
visualize && writevtk(trian6,"test/AdaptivityTests/ref_model6")
test_grid_transfers(2,model2,ref_model6)


end