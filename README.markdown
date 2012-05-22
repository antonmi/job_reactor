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
We recommend use Redis storage with JobReactor to save your task. Now there are thee types of storages in JobReactor: RedisStorage, ActiveRecordStorage and MemoryStorage.
But only RedisStore gives you persistance and asynchronous work with EventMachine. (As you see below, storages are very simple, so you can write your own easily)

JobReactor doesn't have such pretty monitoring solution as Resque, but we plan introduce similar solution in the future.


Delayed::Job:
-------------
If you want simple and easy integration, you can run JobReactor in one process with your application.
We provide ActiveRecordStorage so you can store your jobs in database like Delayed::Job does.

Stalker:
--------
Stalker is extremely fast. 


The main parts of JobReactor are:
---------------------------------
JobReactor module for creating jobs.
Distributor module for 'distribute' jobs between working nodes.
Node object fo job processing.


Main features
=============







How it works
------------






Links:
------
[0]: http://rubyeventmachine.com/