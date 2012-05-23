JobReactor
==========

JobReactor is a library for creating and processing background jobs.
It is client-server distributed system based on [EventMachine][0].

Main features
=============
1. Client-server architecture
-----------------------------
You can run as many distributors and working nodes as you need. You are free to choose the strategy.
If you have many background tasks from each part of your application you can use, for example, 3 distributors (one in each process) and 10 working nodes.
If you don't have many jobs you can leave only one node which will be connected to 3 distributors.
2. High scalability
-------------------
Nodes and distributors are connected via TCP. So, you can run them on any machine you can connect.
Nodes may use different storages or the same one. So, you can store vitally important jobs in relational database and
simple innsignificant jobs in memory.
And more: your nodes may create jobs for others nodes and communicate with each other. See page [advance usage].
3. Reliability
--------------
You can run additional nodes and stop any nodes on-the-fly.
Distributor is smart enough to send jobs to another node if someone is stopped or crashed.
If no nodes are connected to distributor it will keep jobs in memory and send them when nodes start.
If node is stopped or crashed it will retry stored jobs after start.
4. EventMachine available
-------------------------
Remember, your jobs will be run inside EventMachine reactor! You can easily use the power of async nature of EventMachine.
Use asynchronous [http requests], [websockets], [etc.], [etc.], and [etc]. See page [advance usage].
5. Deferred and periodic jobs
-----------------------------
You can use deferred jobs which will run 'after' some time or 'start_at' given time.
You can create periodic jobs which will every given time period and cancel them with condition.
6. No polling
-------------
There is no storage polling. Absolutely. When node receives job (no matter instant, periodic or deferred) there will be EventMachine timer created
which will give job at the right time.
7. Full job control
-------------------
If error occur in the job you can see it in errbacks and do what you want.
You can control job itself! Inside the job you can get information about when it starts, which node execute job and etc.
You also can add some arguments to the job on-the-fly which will be used in the subsequent callbacks and errbacks. See [advance usage].
8. Job retrying
--------------
If job fails it will be retried. You can choose global retrying strategy or manage separate jobs.
9. Predefined nodes
-------------------
You can specify node for jobs, so they will be executed in that node environment. And you can specify which node is forbidden for the job.
If no nodes are specified distributor will try to sen the job to the first free node.
10. Node based priorities
-----------------------
There are no priorities like in Delayed::Job or Stalker. Bud there are flexible node-based priorities.
You can specify the node wich should execute the job. You can reserve several nodes for high priority jobs.




Inspired by:
============
JobReactor is inspired by classical background worker systems such as [Resque][1], [Delayed::Job][2], [Stalker][3], and etc.
The main goal is to get the best and to give more.

Resque
------
- JobReactor likes Redis as Resque does. We recommend use Redis storage with JobReactor to save your tasks. Now there are thee types of storages in JobReactor: RedisStorage, ActiveRecordStorage and MemoryStorage.
But only RedisStore gives you persistance and asynchronous work with EventMachine. (As you see below, storages are very simple, so you can write your own easily)
- JobReactor doesn't have such pretty monitoring solution as Resque, but we plan introduce similar solution in the future.


Delayed::Job
------------
- If you want simple and easy integration, you can run JobReactor in one process with your application.
We provide ActiveRecordStorage so you can store your jobs in database like Delayed::Job does.

Stalker
-------
- Stalker is extremely fast. JobReactor is fast enough too. One distributor can serve more than 1000 jobs per second.
And remember: JobReactor is extremely scalable, so you can run distributor for each part of your application.
- We offer you to use the same job defenition and quering syntax as in Stalker.








Each node needs environment to be loaded.
But remember that distributor is in the same process with your application.
So if your application doesn't scale to many process there no reason to launch more than one distributor.


The main parts of JobReactor are:
---------------------------------
JobReactor module for creating jobs.
Distributor module for 'distribute' jobs between working nodes.
Node object fo job processing.









How it works
------------






Links:
------
[0]: http://rubyeventmachine.com/