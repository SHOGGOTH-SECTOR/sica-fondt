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

  subroutine kalman_scalar_update(prior_mean, prior_var, observation, observation_var, &
       process_var, posterior_mean, posterior_var)
    real(8), intent(in) :: prior_mean, prior_var, observation, observation_var, process_var
    real(8), intent(out) :: posterior_mean, posterior_var
    real(8) :: predicted_var, gain

    if (prior_var < 0d0 .or. observation_var <= 0d0 .or. process_var < 0d0) &
         error stop 'invalid kalman variance'

    predicted_var = prior_var + process_var
    gain = predicted_var / (predicted_var + observation_var)
    posterior_mean = prior_mean + gain*(observation-prior_mean)
    posterior_var = max(0d0,(1d0-gain)*predicted_var)
  end subroutine kalman_scalar_update

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
    real(8), intent(in) :: apy(:), vol(:), risk_aversion
    real(8), intent(out) :: weights(size(apy))
    real(8) :: denom(size(apy)), mu, inv_sum, return_sum
    logical :: active(size(apy)), changed
    integer :: i, iter, n, best

    n = size(apy)
    if (size(vol) /= n .or. n < 1) error stop 'yield vector shape'
    if (risk_aversion < 0d0 .or. any(vol < 0d0)) error stop 'invalid yield risk'

    weights = 0d0
    if (risk_aversion <= 1d-15) then
      best = maxloc(apy, dim=1)
      weights(best) = 1d0
      return
    end if

    denom = 2d0*risk_aversion*max(vol*vol,1d-12)
    active = .true.

    do iter=1,n
      inv_sum = 0d0
      return_sum = 0d0
      do i=1,n
        if (active(i)) then
          inv_sum = inv_sum + 1d0/denom(i)
          return_sum = return_sum + apy(i)/denom(i)
        end if
      end do
      if (inv_sum <= 0d0) exit

      mu = (return_sum-1d0)/inv_sum
      changed = .false.
      weights = 0d0
      do i=1,n
        if (active(i)) then
          weights(i) = (apy(i)-mu)/denom(i)
          if (weights(i) <= 0d0) then
            active(i) = .false.
            weights(i) = 0d0
            changed = .true.
          end if
        end if
      end do
      if (.not. changed) exit
    end do

    if (sum(weights) <= 1d-15) then
      best = maxloc(apy, dim=1)
      weights = 0d0
      weights(best) = 1d0
    else
      weights = weights/sum(weights)
    end if
  end subroutine

  pure real(8) function liquidation_shortfall(collateral,ltv,borrowed) result(shortfall)
    real(8), intent(in) :: collateral,ltv,borrowed
    shortfall=max(0d0,borrowed-collateral*ltv)
  end function

  pure real(8) function clamp_real(x, lo, hi) result(y)
    real(8), intent(in) :: x, lo, hi
    y = min(hi,max(lo,x))
  end function clamp_real

  subroutine tokenomics_prediction(kind, horizon_years, total_minted, circulating, staked, locked, burned, &
       supplied, borrowed, collateral, ltv, treasury, treasury_burn_rate, velocity, base_emission_rate, &
       halving_interval, policy_time, exposure_factor, apy, vol, uncertainty, value, lower, upper, detail)
    character(len=*), intent(in) :: kind
    real(8), intent(in) :: horizon_years, total_minted, circulating, staked, locked, burned
    real(8), intent(in) :: supplied, borrowed, collateral, ltv, treasury, treasury_burn_rate
    real(8), intent(in) :: velocity, base_emission_rate, halving_interval, policy_time, exposure_factor
    real(8), intent(in) :: apy(:), vol(:), uncertainty
    real(8), intent(out) :: value, lower, upper
    real(8), intent(out) :: detail(3)
    real(8) :: emission, days, width, denom, risk, ratio, weights(size(apy))
    logical :: unit_interval

    if (size(apy) /= size(vol) .or. size(apy) < 1) error stop 'yield shape'
    days = max(0d0,horizon_years)*365.25d0
    emission = halving_emission_rate(base_emission_rate,policy_time,halving_interval)
    detail = 0d0
    unit_interval = .false.

    select case (trim(kind))
    case ('supply_trajectory')
      value = max(0d0,total_minted + emission*days)
      width = max(1d-9,uncertainty*max(value,1d0))
    case ('inflation_rate')
      value = 100d0*emission*365.25d0/max(circulating,1d-12)
      width = max(1d-9,uncertainty*max(abs(value),0.1d0))
    case ('staking_ratio')
      denom = max(total_minted-burned,1d-12)
      value = clamp_real(staked/denom,0d0,1d0)
      width = max(1d-6,uncertainty)
      unit_interval = .true.
    case ('velocity_estimate')
      value = max(0d0,velocity)
      width = max(1d-9,uncertainty*max(value,0.1d0))
    case ('halving_impact')
      if (base_emission_rate <= 1d-15) then
        value = 0d0
      else
        value = clamp_real(1d0-emission/base_emission_rate,0d0,1d0)
      end if
      width = max(1d-6,0.5d0*uncertainty)
      unit_interval = .true.
    case ('treasury_runway')
      if (treasury_burn_rate <= 1d-15) then
        value = 1d12
      else
        value = max(0d0,treasury/treasury_burn_rate)
      end if
      width = max(1d-9,uncertainty*max(value,1d0))
    case ('utilization_rate')
      denom = max(supplied+borrowed,1d-12)
      value = clamp_real(borrowed/denom,0d0,1d0)
      width = max(1d-6,uncertainty)
      unit_interval = .true.
    case ('liquidation_cascade_risk')
      denom = max(borrowed,1d-12)
      risk = liquidation_shortfall(collateral,clamp_real(ltv,0d0,1d0),borrowed)/denom
      value = clamp_real(risk*(1d0+max(0d0,exposure_factor)),0d0,1d0)
      width = max(1d-6,uncertainty)
      unit_interval = .true.
    case ('systemic_contagion_index')
      ratio = borrowed/max(collateral*max(ltv,1d-12),1d-12)
      value = clamp_real(max(0d0,exposure_factor)*ratio,0d0,1d0)
      width = max(1d-6,1.25d0*uncertainty)
      unit_interval = .true.
    case ('optimal_yield_allocation')
      call yield_weights(apy,vol,2d0,weights)
      value = maxval(weights)
      detail = 0d0
      detail(1:min(3,size(weights))) = weights(1:min(3,size(weights)))
      width = max(1d-6,uncertainty)
      unit_interval = .true.
    case default
      error stop 'unknown prediction type'
    end select

    lower = value-width
    upper = value+width
    if (unit_interval) then
      lower = clamp_real(lower,0d0,1d0)
      upper = clamp_real(upper,0d0,1d0)
    else
      lower = max(0d0,lower)
    end if
    if (lower > value) lower = value
    if (upper < value) upper = value
  end subroutine tokenomics_prediction

end module
