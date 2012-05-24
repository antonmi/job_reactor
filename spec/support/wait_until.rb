def wait_until(bool)
  max_wait_time = 5
  counter       = 0
  until bool || counter > max_wait_time
    sleep(1)
    counter = counter.succ
  end
end
