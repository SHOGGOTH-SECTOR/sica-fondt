module tokenomics_engine
  implicit none

  type :: token_state
    real(8) :: circulating
    real(8) :: staked
    real(8) :: locked
    real(8) :: burned
    real(8) :: total_minted
  end type token_state

contains

  subroutine token_state_step(state, emission, burn, stake_delta, lock_delta, next_state)
    type(token_state), intent(in) :: state
    real(8), intent(in) :: emission, burn, stake_delta, lock_delta
    type(token_state), intent(out) :: next_state
    real(8) :: available

    if (emission < 0d0 .or. burn < 0d0) error stop 'negative policy flow'

    next_state = state
    next_state%total_minted = state%total_minted + emission
    next_state%circulating = state%circulating + emission

    available = next_state%circulating
    if (burn > available) error stop 'burn exceeds circulating'
    next_state%circulating = next_state%circulating - burn
    next_state%burned = state%burned + burn

    if (stake_delta >= 0d0) then
      if (stake_delta > next_state%circulating) error stop 'stake exceeds circulating'
      next_state%circulating = next_state%circulating - stake_delta
      next_state%staked = state%staked + stake_delta
    else
      if (-stake_delta > state%staked) error stop 'unstake exceeds staked'
      next_state%staked = state%staked + stake_delta
      next_state%circulating = next_state%circulating - stake_delta
    end if

    if (lock_delta >= 0d0) then
      if (lock_delta > next_state%circulating) error stop 'lock exceeds circulating'
      next_state%circulating = next_state%circulating - lock_delta
      next_state%locked = state%locked + lock_delta
    else
      if (-lock_delta > state%locked) error stop 'unlock exceeds locked'
      next_state%locked = state%locked + lock_delta
      next_state%circulating = next_state%circulating - lock_delta
    end if
  end subroutine token_state_step

  pure real(8) function halving_emission_rate(base_rate, time, interval) result(rate)
    real(8), intent(in) :: base_rate, time, interval
    integer :: halvings
    if (base_rate <= 0d0) then
      rate = 0d0
      return
    end if
    if (interval <= 0d0) then
      rate = base_rate
      return
    end if
    halvings = int(floor(max(0d0,time) / interval))
    rate = base_rate * 0.5d0**halvings
  end function halving_emission_rate
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

  subroutine liquidation_cascade(collateral, borrowed, ltv, exposure, iterations, losses)
    real(8), intent(in) :: collateral(:), borrowed(:), ltv(:), exposure(:,:)
    integer, intent(in) :: iterations
    real(8), intent(out) :: losses(size(collateral))
    real(8) :: initial(size(collateral)), next_losses(size(collateral))
    integer :: step, n

    n = size(collateral)
    if (size(borrowed) /= n .or. size(ltv) /= n) error stop 'cascade vector shape'
    if (size(exposure,1) /= n .or. size(exposure,2) /= n) error stop 'cascade matrix shape'
    if (iterations < 0) error stop 'negative cascade iterations'
    if (any(collateral < 0d0) .or. any(borrowed < 0d0)) error stop 'negative balance'
    if (any(ltv < 0d0) .or. any(ltv > 1d0)) error stop 'invalid ltv'
    if (any(exposure < 0d0)) error stop 'negative exposure'

    initial = max(0d0, borrowed - collateral*ltv)
    losses = initial
    do step=1,iterations
      next_losses = initial + matmul(exposure, losses)
      losses = max(0d0, next_losses)
    end do
  end subroutine liquidation_cascade

  subroutine var_impulse_response(a, shock, steps, response)
    real(8), intent(in) :: a(:,:), shock(:)
    integer, intent(in) :: steps
    real(8), intent(out) :: response(size(shock),steps+1)
    integer :: t, n

    n = size(shock)
    if (size(a,1) /= n .or. size(a,2) /= n) error stop 'var matrix shape'
    if (steps < 0) error stop 'negative impulse steps'

    response(:,1) = shock
    do t=1,steps
      response(:,t+1) = matmul(a, response(:,t))
    end do
  end subroutine var_impulse_response

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
