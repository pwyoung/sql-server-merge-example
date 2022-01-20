
-- SQL Server MERGE statement
--   https://docs.microsoft.com/en-us/sql/t-sql/statements/merge-transact-sql?view=sql-server-ver15
-- Better example
--   https://www.sqlshack.com/sql-server-merge-statement-overview-and-examples/
-- VERY simple example
--   https://riptutorial.com/sql-server/example/15957/merge-using-cte-source

--------------------------------------------------------------------------------
-- dbo.thing_events
--------------------------------------------------------------------------------

-- DROP TABLE IF EXISTS dbo.thing_events;
-- still no modern syntax...
IF EXISTS(SELECT * FROM sys.tables WHERE SCHEMA_NAME(schema_id) LIKE 'dbo' AND name = 'thing_events')
   DROP TABLE [dbo].[thing_events];
GO

CREATE TABLE dbo.thing_events
(
  thing_id BIGINT NOT NULL
  ,event_time DATETIME NOT NULL
  ,idur INT
  ,fdur FLOAT
  ,CONSTRAINT pk_thing_events PRIMARY KEY (thing_id,event_time)
);

SELECT COUNT(*) as cnt FROM dbo.thing_events;

/*
SELECT TABLE_NAME , COLUMN_NAME, DATA_TYPE
FROM information_schema.columns
WHERE table_name = 'thing_events';
*/


INSERT INTO dbo.thing_events (thing_id, event_time, idur ,fdur)
--
SELECT 1, '2021-11-01T01:01:01', 1, 1.1
UNION ALL SELECT 1, '2021-12-01T01:01:01', 1, 11.11
UNION ALL SELECT 1, '2021-12-02T01:01:01', 1, 111.111
UNION ALL SELECT 1, '2022-01-01T01:01:01', 1, 1111.1111
--
UNION ALL SELECT 2, '2021-12-01T01:01:01', 2, 2.2
UNION ALL SELECT 2, '2022-01-01T01:01:01', 22, 22.22
;


select 'initial thing_events';

SELECT * FROM dbo.thing_events;

--------------------------------------------------------------------------------
-- dbo.thing_aggs_by_month
--------------------------------------------------------------------------------

IF EXISTS(SELECT * FROM sys.tables WHERE SCHEMA_NAME(schema_id) LIKE 'dbo' AND name = 'thing_aggs_by_month')
   DROP TABLE [dbo].[thing_aggs_by_month];
GO

CREATE TABLE dbo.thing_aggs_by_month
(
  thing_id BIGINT NOT NULL
  ,event_time DATETIME NOT NULL
  ,idur INT
  ,fdur FLOAT
  ,CONSTRAINT pk_thing_aggs_by_month PRIMARY KEY (thing_id,event_time)
);

SELECT COUNT(*) as cnt FROM dbo.thing_aggs_by_month;

--------------------------------------------------------------------------------
-- Insert initial agg values
--------------------------------------------------------------------------------

select 'Insert initial agg values';

INSERT INTO dbo.thing_aggs_by_month(thing_id, event_time, idur ,fdur)
SELECT
  thing_id,
  --DATEFROMPARTS(YEAR(event_time), MONTH(event_time), 1) as event_time, -- first day of month
  EOMONTH(event_time) as event_time, -- last day of month
  SUM(idur) as idur,
  SUM(fdur) as fdur
FROM dbo.thing_events
GROUP BY
  thing_id,
  --DATEFROMPARTS(YEAR(event_time), MONTH(event_time), 1)
  EOMONTH(event_time) -- last day of month
;

SELECT * FROM dbo.thing_aggs_by_month ORDER BY thing_id, event_time;

--------------------------------------------------------------------------------
-- Add new events
--------------------------------------------------------------------------------

select 'Add new events';

INSERT INTO dbo.thing_events (thing_id, event_time, idur ,fdur)
-- additional data for thing 2
SELECT 2, '2022-01-03T01:01:01', 2, 222.222
-- new data for thing 3
UNION ALL SELECT 3, '2022-01-03T01:01:01', 3, 3.3
UNION ALL SELECT 3, '2022-01-04T01:01:01', 3, 33.33
;

SELECT * FROM dbo.thing_events ORDER BY thing_id, event_time;

--------------------------------------------------------------------------------
-- Simulate the monthly job that will update the counts for the latest month
--------------------------------------------------------------------------------

--
-- Show new data
--

select 'Simulate the monthly job: show new data';

IF EXISTS(SELECT * FROM sys.tables WHERE SCHEMA_NAME(schema_id) LIKE 'dbo' AND name = 'new_agg_data')
   DROP TABLE [dbo].[new_agg_data];
GO

select t.thing_id, t.event_time, t.idur, t.fdur
into dbo.new_agg_data
from (
     SELECT
      thing_id,
      EOMONTH(event_time) as event_time,
      SUM(idur) as idur,
      SUM(fdur) as fdur
    FROM dbo.thing_events
    GROUP BY
      thing_id,
      EOMONTH(event_time)
  ) t
;

SELECT * FROM dbo.new_agg_data ORDER BY thing_id, event_time;



--
-- Add new data
--
select 'Simulate the monthly job: add new data';

MERGE dbo.thing_aggs_by_month t
USING dbo.new_agg_data s ON t.thing_id=S.thing_id and t.event_time=S.event_time
WHEN MATCHED THEN
    UPDATE SET idur = s.idur, fdur = s.fdur
WHEN NOT MATCHED BY TARGET THEN
    INSERT (thing_id, event_time, idur, fdur)
    VALUES(s.thing_id, s.event_time, s.idur, s.fdur)
;

select 'Show new agg data';

SELECT * FROM dbo.thing_aggs_by_month ORDER BY thing_id, event_time;

--------------------------------------------------------------------------------
-- Simulate the monthly job that will update the counts for the latest month
-- Using a single SQL statement
--------------------------------------------------------------------------------

select 'Simulate the monthly job: add new data via one statement';

WITH new_agg_data_cte AS
(
     SELECT
      thing_id,
      EOMONTH(event_time) as event_time,
      SUM(idur) as idur,
      SUM(fdur) as fdur
    FROM dbo.thing_events
    GROUP BY
      thing_id,
      EOMONTH(event_time)
)
MERGE dbo.thing_aggs_by_month t
USING new_agg_data_cte AS s
ON t.thing_id=s.thing_id and t.event_time=s.event_time
WHEN MATCHED THEN
    UPDATE SET idur = s.idur, fdur = s.fdur
WHEN NOT MATCHED BY TARGET THEN
    INSERT (thing_id, event_time, idur, fdur)
    VALUES(s.thing_id, s.event_time, s.idur, s.fdur)
;

select 'Show new agg data';

SELECT * FROM dbo.thing_aggs_by_month
ORDER BY thing_id, event_time;
