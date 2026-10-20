program test_microstructure
  use microstructure_engine
  implicit none
  real(8) :: prices(3), qty(3), s1, s2, sched(5), gap1, gap2
  prices=[100d0,101d0,103d0]; qty=[1d0,2d0,10d0]
  s1=slippage_buy(prices,qty,1d0)
  s2=slippage_buy(prices,qty,6d0)
  if (s2 <= s1) error stop 'slippage monotonic'
  call almgren_chriss_schedule(100d0,5,0.01d0,0.05d0,0.02d0,1d0,sched)
  if (abs(sum(sched)-1d0)>1d-8) error stop 'schedule sums'
  if (minval(sched) < 0d0) error stop 'schedule nonnegative'
  gap1=arb_gap_decay(0.05d0,0d0,10d0); gap2=arb_gap_decay(0.05d0,20d0,10d0)
  if (gap2 >= gap1) error stop 'arb decays'
  print *, 'MICROSTRUCTURE TESTS PASSED'
end program
