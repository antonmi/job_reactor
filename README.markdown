JobReactor
==========

JobReactor is a library for creating and processing background jobs.
It is client-server distributed system based on [EventMachine][0].

Inspired by:
============
JobReactor is inspired by classical background worker systems such as [Resque][1], [Delayed::Job][2], [Stalker][3], and etc.
The main goal is to get the best and to give more.

Resque:
-------
JobReactor likes Redis as Resque do. We recommend use Redis storage with JobReactor to save your task. Now there are thee types of storages in JobReactor: RedisStorage, ActiveRecordStorage and MemoryStorage.
But only RedisStore gives you persistance and asynchronous work with EventMachine. (As you see below, storages are very simple, so you can write your own easily)

JobReactor doesn't have such pretty monitoring solution as Resque, but we plan introduce similar solution in the future.


Delayed::Job:
-------------
If you want simple and easy integration, you can run JobReactor in one process with your application.
We provide ActiveRecordStorage so you can store your jobs in database like Delayed::Job does.

Stalker:
--------
Stalker is extremely fast. One JobReactor distributor can serve more than 1000 jobs per second.
And remember: JobReactor is extremely scalable, so you can run own distributor for each part of your application.
We also use the same job defenition and quering syntax.


Main features
=============
- Client-server architecture.
-----------------------------
You can run as many distributors and working nodes as you need. You are free to choose the strategy.
If you have many background tasks from each part of your application you can use, for example, 3 distributors (one in each process) and 10 working nodes.
If you don't have many jobsm you can leave only one node which will be connected to 3 distributors.
Nodes are connected to distributor via TCP. So, you can run them on any machine you can connect.
Nodes may use different storages or the same one. So, you can store vitally important jobs in relational database and 
simple innsignificant jobs in memory.
And more: your nodes may create jobs for others nodes and communicate with each other. See page [advance usage].



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