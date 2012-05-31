JobReactor
==========

JobReactor is a library for creating and processing background jobs.
It is client-server distributed system based on [EventMachine][0].

Quick start
===========


Main features
=============
1. Client-server architecture
-----------------------------
You can run as many distributors and working nodes as you need. You are free to choose the strategy.
If you have many background tasks from each part of your application you can use, for example, 3 distributors (one in each process) and 10 working nodes.
If you don't have many jobs you can leave only one node which will be connected to 3 distributors.
2. High scalability
-------------------
Nodes and distributors are connected via TCP. So, you can run them on any machine you can connect to.
Nodes may use different storages or the same one. So, you can store vitally important jobs in relational database and
simple insignificant jobs in memory.
And more: your nodes may create jobs for others nodes and communicate with each other. See page [advance usage].
3. Full job control
-------------------
You can add callback and errbacks to the job which will be called on the node.
You also can add 'success feedback' and 'error feedback' which will be called in your main application.
When job is done on remote node, your application will receive the result inside corespondent 'feedback'.
If error occur in the job you can see it in errbacks and do what you want.
Inside the job you can get information about when it starts, which node execute job and etc.
You also can add some arguments to the job on-the-fly which will be used in the subsequent callbacks and errbacks. See [advance usage].
4. Reliability
--------------
You can run additional nodes and stop any nodes on-the-fly.
Distributor is smart enough to send jobs to another node if someone is stopped or crashed.
If no nodes are connected to distributor it will keep jobs in memory and send them when nodes start.
If node is stopped or crashed it will retry stored jobs after start.
5. EventMachine available
-------------------------
Remember, your jobs will be run inside EventMachine reactor! You can easily use the power of async nature of EventMachine.
Use asynchronous [http requests], [websockets], [etc.], [etc.], and [etc]. See page [advance usage].
6. Deferred and periodic jobs
-----------------------------
You can use deferred jobs which will run 'after' some time or 'run_at' given time.
You can create periodic jobs which will run every given time period and cancel them on condition.
7. No polling
-------------
There is no storage polling. Absolutely. When node receives job (no matter instant, periodic or deferred) there will be EventMachine timer created
which will start job at the right time.
8. Job retrying
--------------
If job fails it will be retried. You can choose global retrying strategy or manage separate jobs.
9. Predefined nodes
-------------------
You can specify node for jobs, so they will be executed in that node environment. And you can specify which node is forbidden for the job.
If no nodes are specified distributor will try to send the job to the first free node.
10. Node based priorities
-----------------------
There are no priorities like in Delayed::Job or Stalker. Bud there are flexible node-based priorities.
You can specify the node which should execute the job. You can reserve several nodes for high priority jobs.


Each node needs environment to be loaded.
But remember that distributor is in the same process with your application.
So if your application doesn't scale to many process there no reason to launch more than one distributor.


The main parts of JobReactor are:
---------------------------------
JobReactor module for creating jobs.
Distributor module for 'distributing' jobs between working nodes.
Node object for job processing.









How it works
------------






Links:
------
[0]: http://rubyeventmachine.com/