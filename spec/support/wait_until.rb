def wait_until(max_wait_time = 10, raise_exception = false)
  counter = 0
  period = 0.01
  max_wait_counter = max_wait_time.to_f / period

  while !yield && counter < max_wait_counter
    sleep(period)
    counter = counter.succ
  end

  raise WaitUntilException if raise_exception && !yield
end

class WaitUntilException < Exception; end