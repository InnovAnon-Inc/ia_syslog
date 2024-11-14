#! /usr/bin/env python
# cython: language_level=3
# distutils: language=c++

""" Syslog """

import asyncio
import os
import time
from typing                                  import List

import asyncpg
import dotenv
from structlog                               import get_logger

logger                                     = get_logger()

CREATE_TABLE_SystemEvents             :str = '''
CREATE TABLE IF NOT EXISTS SystemEvents
(
        ID serial not null primary key,
        CustomerID bigint,
        ReceivedAt timestamp without time zone NULL,
        DeviceReportedTime timestamp without time zone NULL,
        Facility smallint NULL,
        Priority smallint NULL,
        FromHost varchar(60) NULL,
        Message text,
        NTSeverity int NULL,
        Importance int NULL,
        EventSource varchar(60),
        EventUser varchar(60) NULL,
        EventCategory int NULL,
        EventID int NULL,
        EventBinaryData text NULL,
        MaxAvailable int NULL,
        CurrUsage int NULL,
        MinUsage int NULL,
        MaxUsage int NULL,
        InfoUnitID int NULL ,
        SysLogTag varchar(60),
        EventLogType varchar(60),
        GenericFileName VarChar(60),
        SystemID int NULL
);
'''
#) WITH (OIDS=FALSE) ENCODING 'UTF8';

GRANT_ON_SystemEvents                 :str = '''
GRANT SELECT, INSERT, UPDATE, DELETE ON SystemEvents TO rsyslog; -- Grant SELECT, INSERT, UPDATE, DELETE permissions on the SystemEvents table
'''

GRANT_ON_systemevents_id_seq          :str = '''
GRANT USAGE, SELECT ON SEQUENCE systemevents_id_seq TO rsyslog; -- https://stackoverflow.com/questions/9325017/error-permission-denied-for-sequence-cities-id-seq-using-postgres
'''

CREATE_TABLE_SystemEventsProperties   :str = '''
CREATE TABLE IF NOT EXISTS SystemEventsProperties
(
        ID serial not null primary key,
        SystemEventID int NULL ,
        ParamName varchar(255) NULL ,
        ParamValue text NULL
);
'''

GRANT_ON_SystemEventsProperties       :str = '''
GRANT SELECT, INSERT, UPDATE, DELETE ON SystemEventsProperties TO rsyslog; -- Grant SELECT, INSERT, UPDATE, DELETE permissions on the SystemEventsProperties table
'''

GRANT_ON_systemeventsproperties_id_seq:str = '''
GRANT USAGE, SELECT ON SEQUENCE systemeventsproperties_id_seq TO rsyslog; -- https://stackoverflow.com/questions/9325017/error-permission-denied-for-sequence-cities-id-seq-using-postgres
'''

async def execute(conn, query:str,)->None:
	await logger.adebug('query: %s', query,)
	await conn.execute(query,)

async def create_tables_with_conn(conn,)->None:
	queries:List[str] = [
		CREATE_TABLE_SystemEvents,
		GRANT_ON_SystemEvents,
		GRANT_ON_systemevents_id_seq,
		CREATE_TABLE_SystemEventsProperties,
		GRANT_ON_SystemEventsProperties,
		GRANT_ON_systemeventsproperties_id_seq,
	]
	for query in queries:
		await execute(conn=conn, query=query,)

async def create_tables_with_pool(pool,)->None:
	async with pool.acquire() as conn:
		await create_tables_with_conn(conn=conn,)

async def create_tables(
	user    :str,
	password:str,
	database:str,
	host    :str,
	port    :int,
)->None:
	async with asyncpg.create_pool(
		user=user, password=password, database=database,
		host=host, port=port,) as pool:
		await create_tables_with_pool(pool=pool,)

def main()->None:

	dotenv.load_dotenv()

	dbhost         :str             =     os.getenv('PGHOST',      'localhost')
	dbport         :int             = int(os.getenv('PGPORT',      '5432'))
	dbuser         :str             =     os.getenv('PGUSER',      'rsyslog')
	dbpassword     :str             =     os.environ['PGPASSWORD']
	dbname         :str             =     os.getenv('DBNAME',      'Syslog')
	logger.info('db host         : %s', dbhost,)
	logger.info('db port         : %s', dbport,)
	logger.info('db user         : %s', dbuser,)
	logger.info('db name         : %s', dbname,)

	asyncio.run(create_tables(
		user    =dbuser,
		password=dbpassword,
		database=dbname,
		host    =dbhost,
		port    =dbport, ))

if __name__ == '__main__':
	main()

__author__:str = 'you.com' # NOQA
