program test_tokenomics
  use tokenomics_engine
  implicit none
  real(8) :: shock(3), exposure(3,3), propagated(3), w(3), apy(3), vol(3)
  real(8) :: collateral(4), borrowed(4), ltv(4), cascade_exposure(4,4), losses(4)
  real(8) :: var_a(3,3), impulse(3,4)
  real(8) :: opt_apy(3), opt_vol(3), opt_w(3), marginal(3)
  type(token_state) :: state0, state1
  real(8) :: e_before, e_half, e_quarter
  if (abs(lending_rate(0.80d0,0.02d0,0.04d0,0.60d0,0.80d0)-0.052d0) > 1d-9) error stop 'below kink'
  if (lending_rate(0.90d0,0.02d0,0.04d0,0.60d0,0.80d0) <= lending_rate(0.80d0,0.02d0,0.04d0,0.60d0,0.80d0)) error stop 'kink slope'
  if (.not. stock_flow_conserved(100d0,50d0,20d0,30d0,200d0,1d-9)) error stop 'conservation'
  exposure = 0d0; exposure(2,1)=0.5d0; shock=[1d0,0d0,0d0]
  call contagion_step(exposure, shock, propagated)
  if (propagated(2) <= 0d0 .or. abs(propagated(3)) > 1d-12) error stop 'directional contagion'
  apy=[0.04d0,0.08d0,0.06d0]; vol=[0.01d0,0.10d0,0.03d0]
  call yield_weights(apy,vol,4d0,w)
  if (abs(sum(w)-1d0)>1d-9) error stop 'weights normalize'

  state0 = token_state(600d0,250d0,100d0,50d0,1000d0)
  call token_state_step(state0,20d0,5d0,10d0,-4d0,state1)
  if (abs(state1%total_minted-1020d0)>1d-9) error stop 'minted supply'
  if (abs(state1%burned-55d0)>1d-9) error stop 'burn accounting'
  if (abs(state1%staked-260d0)>1d-9) error stop 'stake flow'
  if (abs(state1%locked-96d0)>1d-9) error stop 'unlock flow'
  if (.not. stock_flow_conserved(state1%circulating,state1%staked,state1%locked, &
       state1%burned,state1%total_minted,1d-9)) error stop 'state conservation'

  e_before = halving_emission_rate(20d0,99d0,100d0)
  e_half = halving_emission_rate(20d0,100d0,100d0)
  e_quarter = halving_emission_rate(20d0,200d0,100d0)
  if (abs(e_before-20d0)>1d-12) error stop 'pre-halving emission'
  if (abs(e_half-10d0)>1d-12) error stop 'first halving'
  if (abs(e_quarter-5d0)>1d-12) error stop 'second halving'


  collateral = [100d0,100d0,100d0,100d0]
  borrowed = [90d0,50d0,20d0,20d0]
  ltv = [0.80d0,0.80d0,0.80d0,0.80d0]
  cascade_exposure = 0d0
  cascade_exposure(2,1) = 0.50d0
  cascade_exposure(3,2) = 0.50d0
  call liquidation_cascade(collateral,borrowed,ltv,cascade_exposure,3,losses)
  if (abs(losses(1)-10d0)>1d-9) error stop 'initial liquidation'
  if (losses(2) <= 0d0) error stop 'first contagion hop'
  if (losses(3) <= 0d0) error stop 'second contagion hop'
  if (abs(losses(4)) > 1d-12) error stop 'isolated protocol'

  var_a = 0d0
  var_a(2,1) = 0.40d0
  var_a(3,2) = 0.50d0
  call var_impulse_response(var_a,[1d0,0d0,0d0],3,impulse)
  if (abs(impulse(1,1)-1d0)>1d-12) error stop 'impulse origin'
  if (abs(impulse(2,2)-0.40d0)>1d-12) error stop 'var first hop'
  if (abs(impulse(3,3)-0.20d0)>1d-12) error stop 'var second hop'
  if (abs(impulse(1,4))+abs(impulse(2,4))+abs(impulse(3,4)) > 1d-12) &
       error stop 'impulse decay'


  opt_apy = [0.06d0,0.08d0,0.07d0]
  opt_vol = [0.10d0,0.12d0,0.08d0]
  call yield_weights(opt_apy,opt_vol,2d0,opt_w)
  if (abs(sum(opt_w)-1d0)>1d-10) error stop 'optimal weights normalize'
  if (minval(opt_w) <= 0d0) error stop 'expected active set'
  marginal = opt_apy - 4d0*opt_vol*opt_vol*opt_w
  if (maxval(marginal)-minval(marginal) > 1d-8) error stop 'yield KKT stationarity'
  print *, 'TOKENOMICS TESTS PASSED'
end program
