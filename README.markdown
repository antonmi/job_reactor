JobReactor
==========

JobReactor is a library for creating, scheduling and processing background jobs.
It is asynchronous client-server distributed system based on [EventMachine][0].
Inspired by [Resque][1], [Beanstalkd][2] ([Stalker][3]), [DelayedJob][4], and etc.

JobReactor has not 'rails' integration for the time being.
But it is very close. We need to test the system with different servers (clusters) and automate the initialization and re-start processes.
Collaborators, you are welcome!

So, read the 'features' section and try JobReactor. You can do a lot with it.

Note
====
JobReactor is based on [EventMachine][0]. Jobs are launched in EM reactor loop in one thread.
There are advantages and disadvantages. The main benefit is fast scheduling, saving and loading.
The weak point is the processing of heavy background jobs when each job takes minutes and hours.
They will block the reactor and break normal processing.

If you can't divide 'THE BIG JOB' into 'small pieces' you shouldn't use JobReactor. See alternatives such [DelayedJob][4] or [Resque][1].

__JobReactor is the right solution if you have thousands, millions, and, we hope:), billions relatively small jobs.__

Quick start
===========
```gem install job_reactor```

__You should install [Redis][5] if you want to persist your jobs.__
```$ sudo apt-get install redis-server```

In your main application:
`application.rb`
``` ruby
require 'job_reactor'
JR.run do
  JR.start_distributor('localhost', 5000)
end
sleep(1) until(JR.ready?)

# The application
loop do
  sleep(3) #Your application is working
  JR.enqueue 'my_job', {arg1: 'Hello'}
end
```
Define the 'my_job' in separate directory (files with job's definitions **must** be in separate directory):
`reactor_jobs/my_jobs.rb`
``` ruby
include JobReactor
job 'my_job' do |args|
  puts args[:arg1]
end
```
And the last file - 'the worker code':
`worker.rb`
``` ruby
require 'job_reactor'
JR.config[:job_directory] = 'reactor_jobs' #this default config, so you can omit this line
JR.run! do
  JR.start_node({
  :storage => 'memory_storage',
  :name => 'worker_1',
  :server => ['localhost', 5001],
  :distributors => [['localhost', 5000]]
  })
end
```
Run 'application.rb' in one terminal window and 'worker.rb' in another.
Node connects to distributor, receives the job and works.
Cool! But it was the simplest example. See 'examples' directory and read 'advanced usage'(coming soon).

Features
=============
1. Client-server architecture
-----------------------------
You can run as many distributors and working nodes as you need. You are free to choose the strategy.
If you have many background tasks from each part of your application you can use, for example, 3 distributors (one in each process) and 10 working nodes.
If you don't have many jobs you can leave only one node which will be connected to 3 distributors.
2. High scalability
-------------------
Nodes and distributors are connected via TCP. So, you can run them on any machine you can connect to.
Nodes may use different storage or the same one. You can store vitally important jobs in database and
simple insignificant jobs in memory.
And more: your nodes may create jobs for others nodes and communicate with each other. See page [advanced usage].
3. Full job control
-------------------
You can add 'callback' and 'errbacks' to the job which will be called on the node.
You also can add 'success feedback' and 'error feedback' which will be called in your main application.
When job is done on remote node, your application will receive the result inside corespondent 'feedback'.
If error occur in the job you can see it in 'errbacks' and the in 'error feedback' and do what you want.
4. Reflection and modifying
---------------------------
Inside the job you can get information about when it starts, when it fails, which node execute job and etc.
You also can add some arguments to the job on-the-fly which will be used in the subsequent callbacks and errbacks.
These arguments then can be sent back to the distibutor.
5. Reliability
--------------
You can run additional nodes and stop any nodes on-the-fly.
Distributor is smart enough to send jobs to another node if someone is stopped or crashed.
If no nodes are connected to distributor it will keep jobs in memory and send them when nodes start.
If node is stopped or crashed it will retry stored jobs after start.
6. EventMachine available
-------------------------
Remember, your jobs will be run inside EventMachine reactor! You can easily use the power of async nature of EventMachine.
Use asynchronous [em-http-request][6], [em-websocket][7], [etc.], [etc.], and [etc].
7. Thread safe
Eventmachine reactor loop runs in one thread. So the code in jobs executed in the given node is absolutely threadsafe.  
8. Deferred and periodic jobs
-----------------------------
You can use deferred jobs which will run 'after' some time or 'run_at' given time.
You can create periodic jobs which will run every given time period and cancel them on condition.
9. No polling
-------------
There is no storage polling. Absolutely. When node receives job (no matter instant, periodic or deferred) there will be EventMachine timer created
which will start job at the right time.
10. Job retrying
--------------
If job fails it will be retried. You can choose global retrying strategy or manage separate jobs.
11. Predefined nodes
-------------------
You can specify node for jobs, so they will be executed in that node environment. And you can specify which node is forbidden for the job.
If no nodes are specified distributor will try to send the job to the first free node.
12. Node based priorities
-----------------------
There are no priorities like in Delayed::Job or Stalker. But there are flexible node-based priorities.
You can specify the node which should execute the job and the node is forbidden for given job. You can reserve several nodes for high priority jobs.

How it works
============
1. You run JobReactor::Distributor in your application initializer
-----------------------------------------------------
``` ruby
JR.run do
  JR.start_distributor('localhost', 5000)
end
```
This code runs EventMachine reactor loop in the new thread and call the block given.
JR.start_distributor starts EventMachine TCP server on given host and port.
And now JobReactor is ready to work.

2. You run JobReactor::Node in the different process or different machine
------------------------------------------------------------------------

``` ruby
JR.run! do
  JR.start_node({
    :storage => 'redis_storage',
    :name => 'redis_node1',
    :server => ['localhost', 5001],
    :distributors => [['localhost', 5000]] 
})
end
```

This code runs EventMachine reactor loop (in the main thread: this is the difference between `run` and `run!`).
And start the Node inside the reactor.
When node starts it:
* parses the 'reactor jobs' files (recursively parse all files specified in JR.config[:job_directory] directory, default is 'reactor_jobs' directory) and create hash of jobs callbacks and errbacs (see [JobReator jobs]);
* tries to 'retry' the job (if you use 'redis_storage' and `JR.config[:retry_jobs_at_start]` is true) 
* starts it's own TCP server;
* connects to Distributor server and sends the information about needed to establish the connection;
When distributor receives the credentials it connects to Node server. And now there is a full duplex-connection between Distributor and Node.

3. You enqueue the job in your application
------------------------------------------

```ruby
JR.enqueue('my_job',{arg1: 1, arg2: 2}, {after: 20}, success, error)
```

The first argument is the name of the job, the second is the arguments hash for the job.
The third is the options hash. If you don't specify any option job will be instant job and will be sent to any free node. You can use the following options:
* `after: seconds` - node will try run the job after  `seconds` seconds;
* `run_at: time` - node will try run the job at given time;
* `period: seconds` - node will run job periodically, each `seconds` seconds;
You can add `node: 'node_name'` and `not_node: 'node_name'` to the options. This specify the node on which the job should or shouldn't be run. For example:

```ruby
JR.enqueue('my_job', {arg1: 1}, {period: 100, node: 'my_favourite_node', not_node: 'do_not_use_this_node'})
```

The rule to use specified node is not strict if `JR.config[:always_use_specified_node]` is false (default).
This means that distributor will try to send the job to the given node at first. But if the node is `locked` (maybe you have just sent another job to it and it is very busy) distributor will look for other node.
The last two arguments are optional too. The first is 'success feedback' and the last is 'error feedback'. We use term 'feedback' to distinguish from 'callbacks' and 'errbacks'. 'feedback' is executed on the main application side while 'callbacks' on the node side. 'feedbacks' are the procs which will be called when node sent message that job is completed (successfully or not). The argunments for the 'feedback' are the arguments of the initial job plus all added on the node side.
Example:

```ruby
#in your 'job_file'
job 'my_job' do |args|
#do smth
args.merge!(result: 'Yay!')
#in your application
#success feedback
success = proc {|args| puts args}
#enqueue job
JR.enqueue('my_job', {arg1: 1}, {}, success)
```

The 'success' proc args will be {arg1: 1, result: 'Yay!'}.
The same story is with 'error feedback'. Note that error feedback will be launched after all attempts failed on the node side.
See config: `JR.config[:max_attempt] = 10` and `JR.config[:retry_multiplier]`

4. You disconnect node (stop it manually or node fails itself)
--------------------------------------------------------------
* distributor will send jobs to any other nodes if present
* distributor will store in memory enqueued jobs if there is no connected node (or specified node)
* when node starts again, then distributor will send jobs to the node

5. You stop the main application.
---------------------------------
* Nodes will continue to work, but you won't be able to receive the results from node when you start the application again because all feedbacks are stored in memory.

Job Storage
==========
Now you can store your job in [Redis][5] storage (`'redis_storage`') or in memory (`'memory_storage'`).
Only the first, of course, 'really' persists the jobs. You can use the last one if you don't want install Redis, don't need retry jobs and need more speed (by the way, the difference in performance is not so great - Redis is very fast).

The default host and port for Redis server are:

```ruby
JR.config[:redis_host] = 'localhost'
JR.config[:redis_port] = 6379
```

JobReactor works asynchronously with Redis using [em-redis][8] library to increase the speed.
Several nodes can use one Redis storage.

The informaion about jobs is saved several times during processing. This information includes:
* id - the unique job id;
* name - job name which 'defines' the job;
* args - serialized arguments for the job;
* run_at - the time when job was launched;
* failed_at - the time when job was failed;
* last_error - the error occured;
* period - period (for periodic jobs);
* status - job status ('new', 'in progress', 'queued', 'complete', 'error', 'failed', 'cancelled');
* attempt - the number of attempt;
* make_after - when to start job again (in seconds after last save);
* distributor - host and port of distributor server which sent the job (used for 'feedbacks');
* on_success - the unique id of success feedback on the distributor side;
* on_error - the unique id of error feedback on the distributor side;

By default JobReactor delete all completed and cancelled jobs, but you can configure it:
The default options are:

```ruby
JR.config[:remove_done_jobs] = true
JR.config[:remove_cancelled_jobs] = true
JR.config[:remove_failed_jobs] = false
JR.config[:retry_jobs_at_start] = true
```

We provide simple `JR::RedisMonitor` module to check the Redis storage from irb console (or from your app).
See methods:

```ruby
JR::RedisMonitor.jobs_for(node_name)
JR::RedisMonitor.load(job_id)
JR::RedisMonitor.destroy(job_id)
JR::RedisMonitor.destroy_all_jobs_for(node_name)
```


License
=======
The MIT License - Copyright (c) 2012 Anton Mishchuk

[0]: http://rubyeventmachine.com
[1]: https://github.com/defunkt/resque
[2]: http://kr.github.com/beanstalkd/
[3]: https://github.com/han/stalker
[4]: https://github.com/tobi/delayed_job
[5]: http://redis.io
[6]: https://github.com/igrigorik/em-http-request
[7]: https://github.com/igrigorik/em-websocket
[8]: https://github.com/madsimian/em-redis
