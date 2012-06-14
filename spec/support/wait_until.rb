def wait_until(max_wait_time = 500)
  counter = 0
  period = 0.01
  max_wait_counter = max_wait_time.to_f / period
  until (block_given? && yield) || counter > max_wait_counter
    sleep(period)
    counter = counter.succ
  end
end
