# Frequently Asked Questions (FAQ)

- [Frequently Asked Questions (FAQ)](#frequently-asked-questions-faq)
  - [Q: What makes an enterprise queue?](#q-what-makes-an-enterprise-queue)
  - [Q: Why use Postgres?](#q-why-use-postgres)

## Q: What makes an enterprise queue?

An entprise queue:
* Enforces leasing
* Limits the message TTL
* Encourages the Unit-Of-Work (UoW) Pattern with explicit message outcomes
* Keeps its tables clean
* Has an audit trail

## Q: Why use Postgres?

* It has all the features we need, look at the code for [dequeue](../data/sql/420_dequeue.sql), especially the use of a Common-Table-Expression (CTE) with `FOR UPDATE SKIP LOCKED` clause which is the magic that exclusively allows the selection of one message via `LIMIT 1`.

