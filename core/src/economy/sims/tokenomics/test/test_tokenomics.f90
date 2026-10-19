program test_tokenomics
  use tokenomics_engine
  implicit none
  real(8) :: shock(3), exposure(3,3), propagated(3), w(3), apy(3), vol(3)
  if (abs(lending_rate(0.80d0,0.02d0,0.04d0,0.60d0,0.80d0)-0.052d0) > 1d-9) error stop 'below kink'
  if (lending_rate(0.90d0,0.02d0,0.04d0,0.60d0,0.80d0) <= lending_rate(0.80d0,0.02d0,0.04d0,0.60d0,0.80d0)) error stop 'kink slope'
  if (.not. stock_flow_conserved(100d0,50d0,20d0,30d0,200d0,1d-9)) error stop 'conservation'
  exposure = 0d0; exposure(2,1)=0.5d0; shock=[1d0,0d0,0d0]
  call contagion_step(exposure, shock, propagated)
  if (propagated(2) <= 0d0 .or. abs(propagated(3)) > 1d-12) error stop 'directional contagion'
  apy=[0.04d0,0.08d0,0.06d0]; vol=[0.01d0,0.10d0,0.03d0]
  call yield_weights(apy,vol,4d0,w)
  if (abs(sum(w)-1d0)>1d-9) error stop 'weights normalize'
  print *, 'TOKENOMICS TESTS PASSED'
end program
