module tokenomics_engine
  implicit none
contains
  pure real(8) function lending_rate(utilization, r0, slope1, slope2, uopt) result(r)
    real(8), intent(in) :: utilization,r0,slope1,slope2,uopt
    real(8) :: u
    u=min(1d0,max(0d0,utilization))
    if (u<=uopt) then
      r=r0+slope1*u
    else
      r=r0+slope1*uopt+slope2*(u-uopt)
    end if
  end function

  pure logical function stock_flow_conserved(circulating,staked,locked,burned,total,tol) result(ok)
    real(8), intent(in) :: circulating,staked,locked,burned,total,tol
    ok = abs((circulating+staked+locked+burned)-total) <= tol
  end function

  subroutine euler_maruyama(x0, drift, sigma, dt, shocks, path)
    real(8), intent(in) :: x0,drift,sigma,dt,shocks(:)
    real(8), intent(out) :: path(size(shocks)+1)
    integer :: i
    path(1)=x0
    do i=1,size(shocks)
      path(i+1)=path(i)+drift*dt+sigma*sqrt(max(dt,0d0))*shocks(i)
    end do
  end subroutine

  subroutine contagion_step(exposure, shock, propagated)
    real(8), intent(in) :: exposure(:,:), shock(:)
    real(8), intent(out) :: propagated(size(shock))
    propagated = shock + matmul(exposure, shock)
  end subroutine

  subroutine yield_weights(apy, vol, risk_aversion, weights)
    real(8), intent(in) :: apy(:),vol(:),risk_aversion
    real(8), intent(out) :: weights(size(apy))
    real(8) :: score(size(apy)), total
    score = max(0d0, apy-risk_aversion*vol*vol)
    total=sum(score)
    if (total<=1d-15) then
      weights = 1d0/real(size(apy),8)
    else
      weights = score/total
    end if
  end subroutine

  pure real(8) function liquidation_shortfall(collateral,ltv,borrowed) result(shortfall)
    real(8), intent(in) :: collateral,ltv,borrowed
    shortfall=max(0d0,borrowed-collateral*ltv)
  end function
end module
