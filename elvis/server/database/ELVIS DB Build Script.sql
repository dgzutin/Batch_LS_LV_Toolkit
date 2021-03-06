/****** Object:  Database ELVIS_LS    Script Date: 1/11/2007 4:18:46 PM ******/
/*CREATE DATABASE [ELVIS_LS]  ON (NAME = N'ELVIS_LS_dat', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL\data\ELVIS_LS.mdf' , SIZE = 314, FILEGROWTH = 10%) LOG ON (NAME = N'ELVIS_LS_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL\data\ELVIS_LS.ldf' , SIZE = 10, FILEGROWTH = 10%)
 COLLATE SQL_Latin1_General_CP1_CI_AS 
GO */

exec sp_dboption N'ELVIS_LS', N'autoclose', N'false'
GO

exec sp_dboption N'ELVIS_LS', N'bulkcopy', N'true'
GO

exec sp_dboption N'ELVIS_LS', N'trunc. log', N'true'
GO

exec sp_dboption N'ELVIS_LS', N'torn page detection', N'true'
GO

exec sp_dboption N'ELVIS_LS', N'read only', N'false'
GO

exec sp_dboption N'ELVIS_LS', N'dbo use', N'false'
GO

exec sp_dboption N'ELVIS_LS', N'single', N'false'
GO

exec sp_dboption N'ELVIS_LS', N'autoshrink', N'false'
GO

exec sp_dboption N'ELVIS_LS', N'ANSI null default', N'false'
GO

exec sp_dboption N'ELVIS_LS', N'recursive triggers', N'false'
GO

exec sp_dboption N'ELVIS_LS', N'ANSI nulls', N'false'
GO

exec sp_dboption N'ELVIS_LS', N'concat null yields null', N'false'
GO

exec sp_dboption N'ELVIS_LS', N'cursor close on commit', N'false'
GO

exec sp_dboption N'ELVIS_LS', N'default to local cursor', N'false'
GO

exec sp_dboption N'ELVIS_LS', N'quoted identifier', N'false'
GO

exec sp_dboption N'ELVIS_LS', N'ANSI warnings', N'false'
GO

exec sp_dboption N'ELVIS_LS', N'auto create statistics', N'true'
GO

exec sp_dboption N'ELVIS_LS', N'auto update statistics', N'true'
GO

if( ( (@@microsoftversion / power(2, 24) = 8) and (@@microsoftversion & 0xffff >= 724) ) or ( (@@microsoftversion / power(2, 24) = 7) and (@@microsoftversion & 0xffff >= 1082) ) )
	exec sp_dboption N'ELVIS_LS', N'db chaining', N'false'
GO

use [ELVIS_LS]
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.qm_CheckQueue    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.qm_CheckQueue    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION qm_CheckQueue () 
RETURNS varchar(5) AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 3/7/2003
--
BEGIN 
	DECLARE @hasJobs varchar(5)
	SET @hasJobs = (SELECT 'true' WHERE EXISTS(SELECT * FROM JobRecord WHERE job_status = 'QUEUED'))

	IF (@hasJobs = 'true')
		BEGIN
			RETURN 'TRUE'
		END
	ELSE
		BEGIN
			RETURN 'FALSE'
		END
	Return 'FALSE'
END


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.qm_ExperimentStatusByLocalID    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.qm_ExperimentStatusByLocalID    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION qm_ExperimentStatusByLocalID (@expID int)
RETURNS @exp_status TABLE (
	queuePosition int,
	estTimeToRun int,
	estExecTime int)
 AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 3/10/2003
--
BEGIN 

	IF (SELECT 'true' WHERE EXISTS(SELECT * FROM JobRecord WHERE exp_id = @expID)) = 'true'
	BEGIN
		DECLARE @exp_stat int
		DECLARE stat_cursor CURSOR
		FOR SELECT stat_code = CASE job_status
				WHEN 'QUEUED' THEN '1' 
				WHEN 'IN PROGRESS' THEN '0'
				WHEN 'COMPLETE' THEN '-1'
				WHEN 'CANCELLED' THEN '-1'
				ELSE '-2'
			         END
			         FROM JobRecord
			         WHERE exp_id = @expID

		OPEN stat_cursor
		FETCH NEXT FROM stat_cursor INTO @exp_stat

		CLOSE stat_cursor
		DEALLOCATE stat_cursor

		IF (@exp_stat = '1')
		BEGIN
			--case where @expID is valid and in the queue
			DECLARE @endbit bit, @currExpID int, @queuePosition int, @estTimeToRun int, @estExecTime int
			DECLARE chk_cursor CURSOR
			FOR SELECT exp_id, est_exec_time 
				FROM JobRecord
				WHERE job_status = 'QUEUED' 
				ORDER BY priority DESC, submit_time
			OPEN chk_cursor
			FETCH NEXT FROM chk_cursor INTO @currExpID, @estExecTime

			SET @endbit = '0'
			SET @queuePosition = 1
			SET @estTimeToRun = 0

			WHILE @@FETCH_STATUS = 0 AND @endbit = '0'
			BEGIN
				IF (@currExpID = @expID)
				BEGIN
					SET @endbit = '1'
				END
				ELSE
				BEGIN
					SET @queuePosition = @queuePosition + 1
					SET @estTimeToRun = @estTimeToRun + @estExecTime
					FETCH NEXT FROM chk_cursor INTO @currExpID, @estExecTime
				END	
			
			END
			CLOSE chk_cursor
			DEALLOCATE chk_cursor

			INSERT INTO @exp_status (queuePosition, estTimeToRun, estExecTime) VALUES (@queuePosition, @estTimeToRun, @estExecTime)
			RETURN
		END
		ELSE
		BEGIN
			--case where @expID is valid, but not in the queue
			INSERT INTO @exp_status (queuePosition, estTimeToRun, estExecTime) VALUES (@exp_stat, '0', '0')
			RETURN
		END
		
		
	END
	ELSE
	BEGIN
		--case where @expID is not valid 
		INSERT INTO @exp_status (queuePosition, estTimeToRun, estExecTime) VALUES ('-2', '0', '0')
		RETURN
	END
	RETURN

END








GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.qm_ExperimentStatusByRemoteID    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.qm_ExperimentStatusByRemoteID    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION qm_ExperimentStatusByRemoteID (@brokerID int, @remoteExpID int)
RETURNS @exp_status TABLE (
	queuePosition int,
	estTimeToRun int,
	estExecTime int)
 AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 9/26/2003
--
BEGIN 

	IF (SELECT 'true' WHERE EXISTS(SELECT * FROM JobRecord WHERE provider_id = @brokerID AND broker_assigned_id = @remoteExpID)) = 'true'
	BEGIN
		DECLARE @exp_stat int, @localExpID int
		DECLARE stat_cursor CURSOR
		FOR SELECT exp_id, stat_code = CASE job_status
				WHEN 'QUEUED' THEN '1' 
				WHEN 'IN PROGRESS' THEN '0'
				WHEN 'COMPLETE' THEN '-1'
				WHEN 'CANCELLED' THEN '-1'
				ELSE '-2'
			         END
			         FROM JobRecord
			         WHERE provider_id = @brokerID AND broker_assigned_id = @remoteExpID

		OPEN stat_cursor
		FETCH NEXT FROM stat_cursor INTO @localExpID, @exp_stat

		CLOSE stat_cursor
		DEALLOCATE stat_cursor

		IF (@exp_stat = '1')
		BEGIN
			--case where @expID is valid and in the queue
			DECLARE @endbit bit, @currExpID int, @queuePosition int, @estTimeToRun int, @estExecTime int
			DECLARE chk_cursor CURSOR
			FOR SELECT exp_id, est_exec_time 
				FROM JobRecord
				WHERE job_status = 'QUEUED' 
				ORDER BY priority DESC, submit_time
			OPEN chk_cursor
			FETCH NEXT FROM chk_cursor INTO @currExpID, @estExecTime

			SET @endbit = '0'
			SET @queuePosition = 1
			SET @estTimeToRun = 0

			WHILE @@FETCH_STATUS = 0 AND @endbit = '0'
			BEGIN
				IF (@currExpID = @localExpID)
				BEGIN
					SET @endbit = '1'
				END
				ELSE
				BEGIN
					SET @queuePosition = @queuePosition + 1
					SET @estTimeToRun = @estTimeToRun + @estExecTime
					FETCH NEXT FROM chk_cursor INTO @currExpID, @estExecTime
				END	
			
			END
			CLOSE chk_cursor
			DEALLOCATE chk_cursor

			INSERT INTO @exp_status (queuePosition, estTimeToRun, estExecTime) VALUES (@queuePosition, @estTimeToRun, @estExecTime)
			RETURN
		END
		ELSE
		BEGIN
			--case where @expID is valid, but not in the queue
			INSERT INTO @exp_status (queuePosition, estTimeToRun, estExecTime) VALUES (@exp_stat, '0', '0')
			RETURN
		END
		
		
	END
	ELSE
	BEGIN
		--case where @expID is not valid 
		INSERT INTO @exp_status (queuePosition, estTimeToRun, estExecTime) VALUES ('-2', '0', '0')
		RETURN
	END
	RETURN

END









GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.qm_GetExpStatusCodeByLocalID    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.qm_GetExpStatusCodeByLocalID    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION qm_GetExpStatusCodeByLocalID (@expID int)
RETURNS int AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 10/9/2003
--This method returns the experiment status code for the specified experiment ID.  Below is a list of possible output and their meanings.
--	1 - Job/broker combo is valid and still in the queue.
--	2 - Job/broker combo is valid and currently executing.
--	3 - Job/broker combo is valid and terminated normally
--	4 - Job/broker combo is valid and terminated with errors.
--	5 - Job/broker combo is valid and was cancelled by broker.
--	6 - Job/broker combo is invalid.
BEGIN 
	DECLARE @returnedID int, @error_occurred bit, @jobStatus varchar(20), @expStatusCode int
	
	DECLARE expRecord CURSOR FOR
		SELECT exp_id, job_status, error_occurred FROM JobRecord WHERE exp_id = @expID

	OPEN expRecord
	FETCH NEXT FROM expRecord INTO @returnedID, @jobStatus, @error_occurred

	CLOSE expRecord
	DEALLOCATE expRecord

	IF @returnedID = '' OR @returnedID = NULL
	BEGIN
		SET @expStatusCode = '6'
	END
	ELSE IF @jobStatus = 'QUEUED'
	BEGIN
		SET @expStatusCode = '1'
	END
	ELSE IF @jobStatus = 'IN PROGRESS'
	BEGIN
		SET @expStatusCode = '2'
	END
	ELSE IF @jobStatus = 'CANCELLED'
	BEGIN
		SET @expStatusCode = '5'
	END
	ELSE IF @jobStatus = 'COMPLETE' AND @error_occurred = '0'
	BEGIN
		SET @expStatusCode = '3'
	END
	ELSE IF @jobStatus = 'COMPLETE' AND @error_occurred = '1'
	BEGIN
		SET @expStatusCode = '4'
	END
	
	RETURN @expStatusCode

END


	


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.qm_GetExpStatusCodeByRemoteID    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.qm_GetExpStatusCodeByRemoteID    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION qm_GetExpStatusCodeByRemoteID (@brokerID int, @brokerExpID int)
RETURNS int AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 10/9/2003
--This method returns the experiment status code for the specified experiment ID.  Below is a list of possible output and their meanings.
--	1 - Job/broker combo is valid and still in the queue.
--	2 - Job/broker combo is valid and currently executing.
--	3 - Job/broker combo is valid and terminated normally
--	4 - Job/broker combo is valid and terminated with errors.
--	5 - Job/broker combo is valid and was cancelled by broker.
--	6 - Job/broker combo is invalid.
BEGIN 
	DECLARE @returnedID int, @error_occurred bit, @jobStatus varchar(20), @expStatusCode int
	
	DECLARE expRecord CURSOR FOR
		SELECT exp_id, job_status, error_occurred FROM JobRecord WHERE broker_assigned_id = @brokerExpID and provider_id = @brokerID

	OPEN expRecord
	FETCH NEXT FROM expRecord INTO @returnedID, @jobStatus, @error_occurred

	CLOSE expRecord
	DEALLOCATE expRecord

	IF @returnedID = '' OR @returnedID = NULL
	BEGIN
		SET @expStatusCode = '6'
	END
	ELSE IF @jobStatus = 'QUEUED'
	BEGIN
		SET @expStatusCode = '1'
	END
	ELSE IF @jobStatus = 'IN PROGRESS'
	BEGIN
		SET @expStatusCode = '2'
	END
	ELSE IF @jobStatus = 'CANCELLED'
	BEGIN
		SET @expStatusCode = '5'
	END
	ELSE IF @jobStatus = 'COMPLETE' AND @error_occurred = '0'
	BEGIN
		SET @expStatusCode = '3'
	END
	ELSE IF @jobStatus = 'COMPLETE' AND @error_occurred = '1'
	BEGIN
		SET @expStatusCode = '4'
	END
	
	RETURN @expStatusCode

END


	


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.qm_QueueLength    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.qm_QueueLength    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION qm_QueueLength (@priority int)  
RETURNS @queue_stat TABLE (
	queueLength int,
	estTimeToRun int)
AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date 3/11/2003
--
BEGIN 
	DECLARE @queueLen int, @estTimeToRun int
	DECLARE currQstat CURSOR
	FOR SELECT COUNT(*), SUM(est_exec_time) 
		FROM JobRecord 
		WHERE job_status = 'QUEUED' AND priority >= @priority
	OPEN currQstat
	FETCH NEXT FROM currQstat INTO @queueLen, @estTimeToRun

	CLOSE currQstat
	DEALLOCATE currQstat

	IF @estTimeToRun = NULL OR @estTimeToRun = '' 
	BEGIN
		SET @estTimeToRun = 0
	END

	INSERT INTO @queue_stat (queueLength, estTimeToRun) VALUES (@queueLen, @estTimeToRun)
	
	RETURN
END







GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.qm_QueueSnapshot    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.qm_QueueSnapshot    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION qm_QueueSnapshot ()  
RETURNS @queue TABLE (
	exp_id int,
	provider_id int,
	priority int,
	submit_time datetime,
	est_exec_time int,
	queue_at_insert int)

AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 3/11/2003
--
BEGIN 
	DECLARE @expID int, @providerID int, @priority int, @submitTime datetime, @estExecTime int, @queueAtInsert int
	DECLARE queue CURSOR
	FOR SELECT exp_id, provider_id, priority, submit_time, est_exec_time, queue_at_insert
		FROM JobRecord 
		WHERE job_status = 'QUEUED' 
		ORDER BY priority DESC, submit_time
	OPEN queue
	
	FETCH NEXT FROM queue INTO @expID, @providerID, @priority, @submitTime, @estExecTime, @queueAtInsert
	
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO @queue (exp_id, provider_id, priority, submit_time, est_exec_time, queue_at_insert)
			VALUES (@expID, @providerID, @priority, @submitTime, @estExecTime, @queueAtInsert)

		FETCH NEXT FROM queue INTO @expID, @providerID, @priority, @submitTime, @estExecTime, @queueAtInsert
	END
	CLOSE queue
	DEALLOCATE queue


	RETURN 
END


	







GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rm_ExpIdLookup    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.rm_ExpIdLookup    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION rm_ExpIdLookup(@broker_id int, @broker_assigned_id int)

RETURNS int
AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 9/24/2003
--This method returns the Lab Server Internal Experiment ID associated with the supplied broker ID and broker assigned experiment ID.  If the input credential pair does not
--correspond to a experiment record, a value of '-1' is returned.
BEGIN 
	DECLARE @returnVal int

	IF (SELECT 'true' WHERE EXISTS(SELECT exp_id FROM JobRecord WHERE provider_id = @broker_id AND broker_assigned_id = @broker_assigned_id)) = 'true'
	BEGIN
		SET @returnVal = (SELECT exp_id FROM JobRecord WHERE provider_id = @broker_id AND broker_assigned_id = @broker_assigned_id)
	END
	ELSE
	BEGIN
		SET @returnVal = -1	
	END
	
	RETURN @returnVal

END





GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rm_ExpRecordInfoByLocalID    Script Date: 1/11/2007 4:18:47 PM ******/


/****** Object:  User Defined Function dbo.rm_ExpRecordInfoByLocalID    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE  FUNCTION rm_ExpRecordInfoByLocalID (@expID int)  
RETURNS @recordInfo TABLE (
	user_group varchar(100),
	submit_time datetime,
	exec_time datetime,
	end_time datetime,
	exec_elapsed int,
	job_elapsed int,
	setup_name varchar(250))
AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 6/26/2003
--This method supplies the caller with information regarding the specified experiment record.  If the specified job id is not valid, then all fields are returned empty.
BEGIN 
	INSERT INTO @recordInfo
		(user_group, submit_time, exec_time, end_time, exec_elapsed, job_elapsed, setup_name)
		(SELECT j.groups, j.submit_time, j.exec_time, j.end_time, j.exec_elapsed, j.job_elapsed, r.name 
			FROM JobRecord j 
				LEFT JOIN Setups s ON j.setup_used = s.setup_id
				LEFT JOIN Resources r ON s.resource_id = r.resource_id
			WHERE j.exp_id = @expID)
	RETURN 


END




GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rm_ExpRecordInfoByRemoteID    Script Date: 1/11/2007 4:18:47 PM ******/


/****** Object:  User Defined Function dbo.rm_ExpRecordInfoByRemoteID    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE  FUNCTION rm_ExpRecordInfoByRemoteID (@brokerID int, @remoteExpID int)  
RETURNS @recordInfo TABLE (
	user_group varchar(100),
	submit_time datetime,
	exec_time datetime,
	end_time datetime,
	exec_elapsed int,
	job_elapsed int,
	setup_name varchar(250))
AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 9/26/2003
--This method supplies the caller with information regarding the specified experiment record.  If the specified job id is not valid, then all fields are returned empty.
BEGIN 
	INSERT INTO @recordInfo
		(user_group, submit_time, exec_time, end_time, exec_elapsed, job_elapsed, setup_name)
		(SELECT j.groups, j.submit_time, j.exec_time, j.end_time, j.exec_elapsed, j.job_elapsed, r.name 
			FROM JobRecord j 
				LEFT JOIN Setups s ON j.setup_used = s.setup_id
				LEFT JOIN Resources r ON s.resource_id = r.resource_id
			WHERE j.provider_id = @brokerID AND j.broker_assigned_id = @remoteExpID)
	RETURN 


END




GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rm_ExpRuntimeEstimate    Script Date: 1/11/2007 4:18:47 PM ******/


/****** Object:  User Defined Function dbo.rm_ExpRuntimeEstimate    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE  FUNCTION rm_ExpRuntimeEstimate (@points int, @setupID int)  
RETURNS int AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 4/25/2003
--This method makes an estimate on the amount of time a job will take to run based on that new job's number of data points and the specific setup that it is being run on.
--The estimate is made by finding matches with the input data and that of completed past experiments.  The methode first looks for an exact match.  If one or more are found, 
--the execution time for the most recent one is used.  If this fails, the top 10 values with matching setupIDs and that are within 150 datapoints of that input will be will 
--be averaged and returned. If this fails, the execution time of the most recent 20 records with datapoints that are within 150 points of that input will be averaged and returned. 
--If all these attempts fail, the average execution time of the 20 most recent jobs will be returned.
BEGIN 
	DECLARE @jobEstimate int, @expCounter int, @expSum int
	SET @jobEstimate = 0
	IF (SELECT 'true' WHERE EXISTS(SELECT exp_id FROM JobRecord WHERE error_occurred = '0' AND job_status = 'COMPLETE' AND datapoints = @points AND setup_used = @setupID)) = 'true'
	BEGIN
		SET @jobEstimate = (SELECT TOP 1 exec_elapsed 
						FROM JobRecord 
						WHERE error_occurred = '0' AND job_status = 'COMPLETE' AND datapoints = @points AND setup_used = @setupID
						ORDER BY exp_id DESC)
	END
	ELSE IF (SELECT 'true' WHERE EXISTS(SELECT exp_id FROM JobRecord WHERE error_occurred = '0' AND job_status = 'COMPLETE' AND datapoints BETWEEN (@points - 150) AND (@points + 150) AND setup_used = @setupID)) = 'true'
	BEGIN
		DECLARE expCursor CURSOR FOR
			SELECT TOP 10 exec_elapsed 
				FROM JobRecord
				WHERE error_occurred = '0' AND job_status = 'COMPLETE' AND datapoints BETWEEN (@points - 150) AND (@points + 150) AND setup_used = @setupID
				ORDER BY exp_id DESC
		OPEN expCursor
		
		SET @expCounter = 0
		SET @expSum = 0
			
		FETCH NEXT FROM expCursor INTO @jobEstimate
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @expSum = @expSum + @jobEstimate
			SET @expCounter = @expCounter + 1
			FETCH NEXT FROM expCursor INTO @jobEstimate
		END
		CLOSE expCursor
		DEALLOCATE expCursor

		SET @jobEstimate = CAST(ROUND(@expSum / @expCounter, 0) AS int)
	END	
	ELSE IF (SELECT 'true' WHERE EXISTS(SELECT exp_id FROM JobRecord WHERE error_occurred = '0' AND job_status = 'COMPLETE' AND datapoints BETWEEN (@points - 150) AND (@points + 150))) = 'true'
	BEGIN
		DECLARE expCursor CURSOR FOR
			SELECT TOP 20 exec_elapsed
				FROM JobRecord
				WHERE error_occurred = '0' AND job_status = 'COMPLETE' AND datapoints BETWEEN (@points - 150) AND (@points + 150)
				ORDER BY exp_id DESC
		OPEN expCursor

		SET @expCounter = 0
		SET @expSum = 0
			
		FETCH NEXT FROM expCursor INTO @jobEstimate
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @expSum = @expSum + @jobEstimate
			SET @expCounter = @expCounter + 1
			FETCH NEXT FROM expCursor INTO @jobEstimate
		END
		CLOSE expCursor
		DEALLOCATE expCursor

		SET @jobEstimate = CAST(ROUND(@expSum / @expCounter, 0) AS int)
	END
	ELSE 
	BEGIN
		DECLARE expCursor CURSOR FOR
			SELECT TOP 20 exec_elapsed
				FROM JobRecord
				WHERE job_status = 'COMPLETE' 
				ORDER BY exp_id DESC
		OPEN expCursor
		
		SET @expCounter = 0
		SET @expSum = 0
			
		FETCH NEXT FROM expCursor INTO @jobEstimate
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @expSum = @expSum + @jobEstimate
			SET @expCounter = @expCounter + 1
			FETCH NEXT FROM expCursor INTO @jobEstimate
		END
		CLOSE expCursor
		DEALLOCATE expCursor
		IF (@expCounter > 0)
			SET @jobEstimate = CAST(ROUND(@expSum / @expCounter, 0) AS int)
		
		
	END
	RETURN @jobEstimate
END







GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rpm_AuthenticateBrokerCredentials    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.rpm_AuthenticateBrokerCredentials    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION rpm_AuthenticateBrokerCredentials (@Ident varchar(35), @PassKey varchar(20))  
RETURNS int AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 10/22/2003
--This method determines if there is an active broker associated with the supplied broker credientials.  If there is, then the relevant internal broker id is returned to the caller.
--Otherwise, a value of '-1' is returned, indicating that the credentials are invalid.
BEGIN 
	DECLARE @returnValue int

	SET @returnValue = -1

	IF (SELECT 'true' WHERE EXISTS(SELECT broker_id FROM Brokers WHERE broker_server_id = @Ident AND broker_passkey = @PassKey AND is_active = 1)) = 'true'
	BEGIN
		SET @returnValue = (SELECT broker_id FROM Brokers WHERE broker_server_id = @Ident AND broker_passkey = @PassKey AND is_active = 1)
	END

	RETURN @returnValue
END



GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rpm_BrokerIsMemberOf    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.rpm_BrokerIsMemberOf    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION rpm_BrokerIsMemberOf (@brokerID int)  
RETURNS @classMan TABLE (
	ClassID int,
	ClassName varchar(100))
 AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/16/2003
--This method supplies the caller with the class membership information of the specifiec Service Broker.  The caller supplies a valid broker ID and, in return, is given the 
--class_id and the class name of the Usage Class which the Broker belongs to.  If the provided broker id is invalid, the ClassID and ClassName fields will be returned as 
--null values.  
BEGIN 
	DECLARE @ClassID int, @ClassName varchar(100)
	DECLARE classLookup CURSOR FOR
		SELECT b.class_id, c.name 
			FROM Brokers b JOIN UsageClasses c 
					ON b.class_id = c.class_id 
			WHERE b.broker_id = @brokerID
	OPEN classLookup
	FETCH NEXT FROM classLookup INTO @ClassID, @ClassName
	CLOSE classLookup
	DEALLOCATE classLookup

	INSERT INTO @classMan (ClassID, ClassName) VALUES (@ClassID, @ClassName)
	RETURN

END


	








GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rpm_GetActiveSetupList    Script Date: 1/11/2007 4:18:47 PM ******/


/****** Object:  User Defined Function dbo.rpm_GetActiveSetupList    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE  FUNCTION rpm_GetActiveSetupList (@ClassID int)  
RETURNS @setupConfig TABLE (
	setupID int, 
	setupName varchar(250),
	setupDesc varchar(1000),
	setupImageLoc varchar(100)
)
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 6/25/2003
--This method takes a valid class id and returns a list of active setups that the specified class has permission to execute jobs on.  An invalid class id will cause this method 
--to return an empty list.
BEGIN 
	INSERT INTO @setupConfig
		(setupID, setupName, setupDesc, setupImageLoc)
		(SELECT a.setup_id, r.name, r.description, p.icon_path
			FROM ActiveSetups a JOIN Setups p ON a.setup_id = p.setup_id
				JOIN Resources r ON p.resource_id = r.resource_id
				JOIN ClassToResourceMapping m ON p.resource_id = m.resource_id
			WHERE m.class_id = @ClassID AND m.can_view = 1 AND a.is_active = 1 AND a.setup_id <> NULL)
	RETURN
END






GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rpm_GetBrokerResourcePermission    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.rpm_GetBrokerResourcePermission    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION rpm_GetBrokerResourcePermission (@brokerID int, @resourceID int)  
RETURNS @permissionSet TABLE (
	MappingID int, 
	CanView bit,
	CanEdit bit,
	CanGrant bit,
	CanDelete bit,
	Priority int)
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/21/2003
--This method takes as input a valid broker ID, resource ID pair and returns the permission mapping that exists between them.  If no such mapping exists, all return fields 
--will be null.  
BEGIN 
	INSERT INTO @permissionSet 
		(MappingID, CanView, CanEdit, CanGrant, CanDelete, Priority)
		(SELECT m.mapping_id, m.can_view, m.can_edit, m.can_grant, m.can_delete, m.priority
			FROM ClassToResourceMapping m JOIN Brokers b ON b.class_id = m.class_id
			WHERE b.broker_id = @brokerID AND m.resource_id = @resourceID)
	RETURN
END


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rpm_GetClassResourcePermission    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.rpm_GetClassResourcePermission    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION rpm_GetClassResourcePermission (@classID int, @resourceID int)  
RETURNS @permissionSet TABLE (
	MappingID int, 
	CanView bit,
	CanEdit bit,
	CanGrant bit,
	CanDelete bit,
	Priority int)
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/21/2003
--This method takes as input a valid class ID, resource ID pair and returns the permission mapping that exists between them.  If no such mapping exists, all return fields 
--will be null.  
BEGIN 
	INSERT INTO @permissionSet 
		(MappingID, CanView, CanEdit, CanGrant, CanDelete, Priority)
		(SELECT mapping_id, can_view, can_edit, can_grant, can_delete, priority
			FROM ClassToResourceMapping 
			WHERE class_id = @classID AND resource_id = @resourceID)
	RETURN
END



GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rpm_GetGroupID    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.rpm_GetGroupID    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION rpm_GetGroupID (@BrokerID int, @GroupName varchar(250))  
RETURNS int AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 6/24/2003
--This method maps a groupID value to a specified group name and owner brokerID.  Both inputs are required and must correspond to valid records.  Invalid inputs will result
--in a null/empty return value.  If valid inputs are returned, the groupID corresponding to the specified name and owner will be retruned.
BEGIN 
	DECLARE @returnValue int
	
	SET @returnValue = (SELECT group_id FROM Groups WHERE owner_id = @BrokerID AND name = @GroupName)

	IF @returnValue = NULL OR @returnValue = ''
	BEGIN
		SET @returnValue = 0
	END
	

	RETURN @returnValue
END








GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rpm_GetGroupResourcePermission    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.rpm_GetGroupResourcePermission    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION rpm_GetGroupResourcePermission (@groupID int, @resourceID int)  
RETURNS @permissionSet TABLE (
	MappingID int, 
	CanView bit,
	CanEdit bit,
	CanGrant bit,
	CanDelete bit,
	Priority int)
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/21/2003
--This method takes as input a valid group ID, resource ID pair and returns the permission mapping that exists between them.  If no such mapping exists, all return fields 
--will be null.  
BEGIN 
	INSERT INTO @permissionSet 
		(MappingID, CanView, CanEdit, CanGrant, CanDelete, Priority)
		(SELECT m.mapping_id, m.can_view, m.can_edit, m.can_grant, m.can_delete, m.priority
			FROM ClassToResourceMapping m JOIN Groups g ON g.class_id = m.class_id
			WHERE g.group_id = @groupID AND m.resource_id = @resourceID)
	RETURN
END



GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rpm_GetSetupTerminalInfo    Script Date: 1/11/2007 4:18:47 PM ******/




/****** Object:  User Defined Function dbo.rpm_GetSetupTerminalInfo    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE    FUNCTION rpm_GetSetupTerminalInfo (@SetupID int)  
RETURNS @termInfo TABLE (
	termPID int,
	termNumber int, 
	termInstrument varchar(5),
	termName varchar(50),
	termXLoc int,
	termYLoc int,
	termMaxAmp float,
	termMaxOffset float,
	termMaxA float,
	termMaxF float,
	termMaxSamplingRate float,
	termMaxSamplingTime float,
	termMaxPoints float)
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 6/25/2003
--This method takes a valid setup id and returns a list of terminals that correspond to the specified id.  An invalid setup id will cause this method 
--to return an empty list.
BEGIN 
	INSERT @termInfo --INTO @termInfo
		--(termPID, termNumber, termInstrument, termName, termXLoc, termYLoc, termMaxAmplitude, termMaxOffset, termMaxA, termMaxF, termMaxSamplingRate, termMaxSamplingTime, termMaxPoints)
		SELECT pt.setupterm_id, pt.number, pt.instrument, pt.name, pt.x_pixel_loc, pt.y_pixel_loc, pt.max_amplitude, pt.max_offset, pt.max_current, pt.max_frequency, pt.max_sampling_rate, pt.max_sampling_time, pt.max_points
			FROM SetupTerminalConfig pt 
			WHERE pt.setup_id = @SetupID ORDER BY pt.number 
	RETURN
END







GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rpm_GetUserResourcePermission    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.rpm_GetUserResourcePermission    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION rpm_GetUserResourcePermission (@userID int, @resourceID int)  
RETURNS @permissionSet TABLE (
	MappingID int, 
	CanView bit,
	CanEdit bit,
	CanGrant bit,
	CanDelete bit,
	Priority int)
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 7/22/2004
--This method takes as input a valid site user ID, resource ID pair and returns the permission mapping that exists between them.  If no such mapping exists, all return fields 
--will be null.  
BEGIN 
	INSERT INTO @permissionSet 
		(MappingID, CanView, CanEdit, CanGrant, CanDelete, Priority)
		(SELECT m.mapping_id, m.can_view, m.can_edit, m.can_grant, m.can_delete, m.priority
			FROM ClassToResourceMapping m JOIN SiteUsers u ON u.class_id = m.class_id
			WHERE u.user_id = @userID AND m.resource_id = @resourceID)
	RETURN
END



GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rpm_GroupIsMemberOf    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.rpm_GroupIsMemberOf    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION rpm_GroupIsMemberOf (@groupID int)  
RETURNS @classMan TABLE (
	ClassID int,
	ClassName varchar(100))
 AS  
--Author(s): James Hardison (hardison@alum.mit .edu)
--Date: 5/19/2003
--This method supplies the caller with the class membership information of the specifiec group.  The caller supplies a valid group ID and, in return, is given the 
--class_id and the class name of the Usage Class which the group belongs to.  If the provided broker id is invalid, the ClassID and ClassName fields will be returned as 
--null values.  
BEGIN 
	DECLARE @ClassID int, @ClassName varchar(100)
	DECLARE classLookup CURSOR FOR
		SELECT g.class_id, c.name 
			FROM Groups g JOIN UsageClasses c 
					ON g.class_id = c.class_id 
			WHERE g.group_id = @groupID
	OPEN classLookup
	FETCH NEXT FROM classLookup INTO @ClassID, @ClassName
	CLOSE classLookup
	DEALLOCATE classLookup

	INSERT INTO @classMan (ClassID, ClassName) VALUES (@ClassID, @ClassName)
	RETURN


END




GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rpm_ListBrokerPermissions    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.rpm_ListBrokerPermissions    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION rpm_ListBrokerPermissions (@brokerID int)  
RETURNS @brokerPermissions TABLE (
	ResourceID int,
	ResourceName varchar(250),
	ResourceType varchar(10),
	CanView bit,
	CanEdit bit,
	CanGrant bit,
	CanDelete bit,
	Priority int)
AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/21/2003
--This method takes as input a valid broker ID and returns a table of resource permissions that are associated with that group.  The information returned captures the 
--associated resource ID, the name and type of the resource along with the specific permission settings that define the relationship between the specified broker and the 
--listed resources.  If an invalid broker Id is supplied, all fields will return NULL. 
BEGIN 
	INSERT INTO @brokerPermissions 
			(ResourceID, ResourceName, ResourceType, CanView, CanEdit, CanGrant, CanDelete, Priority)
			(SELECT r.resource_id, r.name, r.type, m.can_view, m.can_edit, m.can_grant, m.can_delete, m.priority 
				FROM Brokers b JOIN ClassToResourceMapping m ON b.class_id = m.class_id JOIN Resources r ON m.resource_id = r.resource_id
				WHERE b.broker_id = @brokerID)
	RETURN
		
END



GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rpm_ListClassPermissions    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.rpm_ListClassPermissions    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION rpm_ListClassPermissions (@classID int)  
RETURNS @groupPermissions TABLE (
	ResourceID int,
	ResourceName varchar(250),
	ResourceType varchar(10),
	CanView bit,
	CanEdit bit,
	CanGrant bit,
	CanDelete bit,
	Priority int)
AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/21/2003
--This method takes as input a valid class ID and returns a table of resource permissions that are associated with that class.  The information returned captures the 
--associated resource ID, the name and type of the resource along with the specific permission settings that define the relationship between the specified class and the 
--listed resources.  If an invalid class Id is supplied, all fields will return NULL. 
BEGIN 
	INSERT INTO @groupPermissions 
			(ResourceID, ResourceName, ResourceType, CanView, CanEdit, CanGrant, CanDelete, Priority)
			(SELECT r.resource_id, r.name, r.type, m.can_view, m.can_edit, m.can_grant, m.can_delete, m.priority 
				FROM ClassToResourceMapping m JOIN Resources r ON m.resource_id = r.resource_id
				WHERE m.class_id = @classID)
	RETURN
		
END


GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rpm_ListGroupPermissions    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.rpm_ListGroupPermissions    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION rpm_ListGroupPermissions (@groupID int)  
RETURNS @groupPermissions TABLE (
	ResourceID int,
	ResourceName varchar(250),
	ResourceType varchar(10),
	CanView bit,
	CanEdit bit,
	CanGrant bit,
	CanDelete bit,
	Priority int)
AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/21/2003
--This method takes as input a valid group ID and returns a table of resource permissions that are associated with that group.  The information returned captures the 
--associated resource ID, the name and type of the resource along with the specific permission settings that define the relationship between the specified group and the 
--listed resources.  If an invalid group Id is supplied, all fields will return NULL. 
BEGIN 
	INSERT INTO @groupPermissions 
			(ResourceID, ResourceName, ResourceType, CanView, CanEdit, CanGrant, CanDelete, Priority)
			(SELECT r.resource_id, r.name, r.type, m.can_view, m.can_edit, m.can_grant, m.can_delete, m.priority 
				FROM Groups g JOIN ClassToResourceMapping m ON g.class_id = m.class_id JOIN Resources r ON m.resource_id = r.resource_id
				WHERE g.group_id = @groupID)
	RETURN
		
END






GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  User Defined Function dbo.rpm_ListMembers    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  User Defined Function dbo.rpm_ListMembers    Script Date: 8/31/2004 1:34:35 PM ******/
CREATE FUNCTION rpm_ListMembers (@classID int)  
RETURNS @classMembers TABLE (
	MemberID int,
	MemberName varchar(100),
	MemberType varchar(10))
AS  
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/20/2003
--This method returns information on each of the members of the specified class.  This information includes the ID value associated with the record in it's native table, its
--name and its type (group or broker).  This information is returned as a table.
BEGIN 
	INSERT INTO @classMembers (MemberID, MemberName, MemberType) (SELECT broker_id, name, 'BROKER' FROM Brokers WHERE class_id = @classID)
	INSERT INTO @classMembers (MemberID, MemberName, MemberType) (SELECT group_id, name, 'GROUP' FROM Groups WHERE class_id = @classID)
	RETURN

END





GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Table [dbo].[ActiveSetups]    Script Date: 1/11/2007 4:18:46 PM ******/
CREATE TABLE [dbo].[ActiveSetups] (
	[active_id] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[setup_id] [numeric](18, 0) NULL ,
	[is_active] [bit] NOT NULL 
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Brokers]    Script Date: 1/11/2007 4:18:46 PM ******/
CREATE TABLE [dbo].[Brokers] (
	[broker_id] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[class_id] [numeric](18, 0) NOT NULL ,
	[name] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[broker_server_id] [varchar] (36) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[broker_passkey] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[server_passkey] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[description] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[comments] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[contact_first_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[contact_last_name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[contact_email] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[is_active] [bit] NOT NULL ,
	[notify_location] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[date_created] [datetime] NOT NULL ,
	[date_modified] [datetime] NOT NULL 
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[ClassToResourceMapping]    Script Date: 1/11/2007 4:18:46 PM ******/
CREATE TABLE [dbo].[ClassToResourceMapping] (
	[mapping_id] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[resource_id] [numeric](18, 0) NOT NULL ,
	[class_id] [numeric](18, 0) NOT NULL ,
	[can_view] [bit] NOT NULL ,
	[can_edit] [bit] NOT NULL ,
	[can_grant] [bit] NOT NULL ,
	[can_delete] [bit] NOT NULL ,
	[priority] [int] NOT NULL ,
	[date_created] [datetime] NOT NULL ,
	[date_modified] [datetime] NOT NULL 
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Groups]    Script Date: 1/11/2007 4:18:46 PM ******/
CREATE TABLE [dbo].[Groups] (
	[group_id] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[owner_id] [numeric](18, 0) NOT NULL ,
	[class_id] [numeric](18, 0) NOT NULL ,
	[name] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[description] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[comments] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[is_active] [bit] NOT NULL ,
	[date_created] [datetime] NOT NULL ,
	[date_modified] [datetime] NOT NULL 
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[JobRecord]    Script Date: 1/11/2007 4:18:46 PM ******/
CREATE TABLE [dbo].[JobRecord] (
	[exp_id] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[provider_id] [numeric](18, 0) NOT NULL ,
	[broker_assigned_id] [int] NOT NULL ,
	[groups] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[priority] [int] NOT NULL ,
	[job_status] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[submit_time] [datetime] NOT NULL ,
	[exec_time] [datetime] NULL ,
	[end_time] [datetime] NULL ,
	[exec_elapsed] [int] NULL ,
	[job_elapsed] [int] NULL ,
	[est_exec_time] [int] NOT NULL ,
	[queue_at_insert] [int] NOT NULL ,
	[datapoints] [int] NOT NULL ,
	[setup_used] [int] NOT NULL ,
	[lab_config_at_exec] [ntext] COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[experiment_vector] [ntext] COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[experiment_results] [ntext] COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[error_report] [varchar] (2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[error_occurred] [bit] NOT NULL ,
	[downloaded] [bit] NOT NULL 
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

/****** Object:  Table [dbo].[LSSystemConfig]    Script Date: 1/11/2007 4:18:46 PM ******/
CREATE TABLE [dbo].[LSSystemConfig] (
	[SetupID] [int] IDENTITY (1, 1) NOT NULL ,
	[homepage] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[Admin_ID] [int] NOT NULL ,
	[ws_int_is_active] [bit] NOT NULL ,
	[exp_eng_is_active] [bit] NOT NULL ,
	[lab_server_id] [varchar] (35) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[lab_status_msg] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL 
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[LoginRecord]    Script Date: 1/11/2007 4:18:46 PM ******/
CREATE TABLE [dbo].[LoginRecord] (
	[record_id] [int] IDENTITY (1, 1) NOT NULL ,
	[login_type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[user_id] [int] NOT NULL ,
	[remote_ip] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[user_agent] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[login_time] [datetime] NOT NULL 
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Resources]    Script Date: 1/11/2007 4:18:46 PM ******/
CREATE TABLE [dbo].[Resources] (
	[resource_id] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[name] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[category] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[description] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[date_created] [datetime] NOT NULL ,
	[date_modified] [datetime] NOT NULL 
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[SetupTerminalConfig]    Script Date: 1/11/2007 4:18:46 PM ******/
CREATE TABLE [dbo].[SetupTerminalConfig] (
	[setupterm_id] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[setup_id] [numeric](18, 0) NOT NULL ,
	[number] [int] NOT NULL ,
	[name] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[x_pixel_loc] [int] NOT NULL ,
	[y_pixel_loc] [int] NOT NULL ,
	[max_amplitude] [float] NOT NULL ,
	[max_current] [float] NOT NULL ,
	[max_frequency] [float] NOT NULL ,
	[instrument] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[date_created] [datetime] NOT NULL ,
	[date_modified] [datetime] NOT NULL ,
	[max_sampling_time] [float] NOT NULL ,
	[max_sampling_rate] [float] NOT NULL ,
	[max_offset] [float] NOT NULL ,
	[max_points] [float] NOT NULL 
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Setups]    Script Date: 1/11/2007 4:18:46 PM ******/
CREATE TABLE [dbo].[Setups] (
	[setup_id] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[icon_path] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[terminals_used] [int] NOT NULL ,
	[resource_id] [numeric](18, 0) NOT NULL ,
	[date_created] [datetime] NOT NULL ,
	[date_modified] [datetime] NOT NULL 
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[SiteUsers]    Script Date: 1/11/2007 4:18:46 PM ******/
CREATE TABLE [dbo].[SiteUsers] (
	[user_id] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[first_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[last_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[email] [varchar] (150) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[username] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[password] [varchar] (20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[class_id] [numeric](18, 0) NOT NULL ,
	[is_active] [bit] NOT NULL ,
	[date_created] [datetime] NOT NULL ,
	[date_modified] [datetime] NOT NULL 
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[SystemNotices]    Script Date: 1/11/2007 4:18:46 PM ******/
CREATE TABLE [dbo].[SystemNotices] (
	[notice_id] [int] IDENTITY (1, 1) NOT NULL ,
	[title] [varchar] (45) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[body] [varchar] (1500) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[date_entered] [datetime] NOT NULL ,
	[is_displayed] [bit] NOT NULL ,
	[author_id] [int] NOT NULL 
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[UsageClasses]    Script Date: 1/11/2007 4:18:47 PM ******/
CREATE TABLE [dbo].[UsageClasses] (
	[class_id] [numeric](18, 0) IDENTITY (1, 1) NOT NULL ,
	[name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[description] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[comments] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[amt_member_brokers] [int] NOT NULL ,
	[amt_member_groups] [int] NOT NULL ,
	[amt_member_susers] [int] NOT NULL ,
	[date_created] [datetime] NOT NULL ,
	[date_modified] [datetime] NOT NULL 
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[WebMethodRequestLog]    Script Date: 1/11/2007 4:18:47 PM ******/
CREATE TABLE [dbo].[WebMethodRequestLog] (
	[request_id] [int] IDENTITY (1, 1) NOT NULL ,
	[type] [varchar] (10) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[source_name] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[dest_name] [varchar] (250) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[method_name] [varchar] (100) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[out_dest_URL] [varchar] (500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL ,
	[in_has_permission] [bit] NULL ,
	[completed_successfully] [bit] NOT NULL ,
	[completion_status] [varchar] (1000) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[transaction_time] [datetime] NOT NULL 
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ActiveSetups] WITH NOCHECK ADD 
	CONSTRAINT [PK_ActiveSetups] PRIMARY KEY  CLUSTERED 
	(
		[active_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[Brokers] WITH NOCHECK ADD 
	CONSTRAINT [PK_Brokers] PRIMARY KEY  CLUSTERED 
	(
		[broker_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[ClassToResourceMapping] WITH NOCHECK ADD 
	CONSTRAINT [PK_ClassToResourceMapping] PRIMARY KEY  CLUSTERED 
	(
		[mapping_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[Groups] WITH NOCHECK ADD 
	CONSTRAINT [PK_Groups] PRIMARY KEY  CLUSTERED 
	(
		[group_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[JobRecord] WITH NOCHECK ADD 
	CONSTRAINT [PK_JobRecord] PRIMARY KEY  CLUSTERED 
	(
		[exp_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[LoginRecord] WITH NOCHECK ADD 
	CONSTRAINT [PK_LoginRecord] PRIMARY KEY  CLUSTERED 
	(
		[record_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[Resources] WITH NOCHECK ADD 
	CONSTRAINT [PK_Resources] PRIMARY KEY  CLUSTERED 
	(
		[resource_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SetupTerminalConfig] WITH NOCHECK ADD 
	CONSTRAINT [PK_SetupTerminalConfig] PRIMARY KEY  CLUSTERED 
	(
		[setupterm_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[Setups] WITH NOCHECK ADD 
	CONSTRAINT [PK_Setups] PRIMARY KEY  CLUSTERED 
	(
		[setup_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SiteUsers] WITH NOCHECK ADD 
	CONSTRAINT [PK_SiteUsers] PRIMARY KEY  CLUSTERED 
	(
		[user_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[SystemNotices] WITH NOCHECK ADD 
	CONSTRAINT [PK_SystemNotices] PRIMARY KEY  CLUSTERED 
	(
		[notice_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[UsageClasses] WITH NOCHECK ADD 
	CONSTRAINT [PK_UsageClasses] PRIMARY KEY  CLUSTERED 
	(
		[class_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[WebMethodRequestLog] WITH NOCHECK ADD 
	CONSTRAINT [PK_WebMethodRequestLog] PRIMARY KEY  CLUSTERED 
	(
		[request_id]
	)  ON [PRIMARY] 
GO

ALTER TABLE [dbo].[ActiveSetups] ADD 
	CONSTRAINT [DF_ActiveSetups_is_active] DEFAULT ('1') FOR [is_active]
GO

ALTER TABLE [dbo].[Brokers] ADD 
	CONSTRAINT [DF_Brokers_is_active] DEFAULT ('1') FOR [is_active],
	CONSTRAINT [DF_Brokers_notify_location] DEFAULT ('') FOR [notify_location],
	CONSTRAINT [DF_Brokers_date_modified] DEFAULT (getdate()) FOR [date_modified]
GO

 CREATE  INDEX [IX_Brokers_classID] ON [dbo].[Brokers]([class_id]) ON [PRIMARY]
GO

 CREATE  INDEX [IX_Brokers_name] ON [dbo].[Brokers]([name]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ClassToResourceMapping] ADD 
	CONSTRAINT [DF_ClassToResourceMapping_can_view] DEFAULT (0) FOR [can_view],
	CONSTRAINT [DF_ClassToResourceMapping_can_edit] DEFAULT (0) FOR [can_edit],
	CONSTRAINT [DF_ClassToResourceMapping_can_grant] DEFAULT (0) FOR [can_grant],
	CONSTRAINT [DF_ClassToResourceMapping_can_delete] DEFAULT (0) FOR [can_delete],
	CONSTRAINT [DF_ClassToResourceMapping_priority] DEFAULT (0) FOR [priority],
	CONSTRAINT [DF_ClassToResourceMapping_date_modified] DEFAULT (getdate()) FOR [date_modified],
	CONSTRAINT [CK_priority] CHECK ([priority] >= (-20) and [priority] <= 20)
GO

 CREATE  INDEX [IX_ClassToResourceMapping_resource] ON [dbo].[ClassToResourceMapping]([resource_id]) ON [PRIMARY]
GO

 CREATE  INDEX [IX_ClassToResourceMapping_class] ON [dbo].[ClassToResourceMapping]([class_id]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Groups] ADD 
	CONSTRAINT [DF_Groups_is_active] DEFAULT ('1') FOR [is_active],
	CONSTRAINT [DF_Groups_date_modified] DEFAULT (getdate()) FOR [date_modified]
GO

 CREATE  INDEX [IX_Groups_ownerID] ON [dbo].[Groups]([owner_id]) ON [PRIMARY]
GO

 CREATE  INDEX [IX_Groups_classID] ON [dbo].[Groups]([class_id]) ON [PRIMARY]
GO

 CREATE  INDEX [IX_Groups_name] ON [dbo].[Groups]([name]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[JobRecord] ADD 
	CONSTRAINT [DF_JobRecord_prioirty] DEFAULT (0) FOR [priority],
	CONSTRAINT [DF_JobRecord_datapoints] DEFAULT (0) FOR [datapoints],
	CONSTRAINT [DF_JobRecord_setup_used] DEFAULT (0) FOR [setup_used],
	CONSTRAINT [DF_JobRecord_error_occurres] DEFAULT (0) FOR [error_occurred],
	CONSTRAINT [DF_JobRecord_downloaded] DEFAULT (0) FOR [downloaded],
	CONSTRAINT [IX_JobRecordUniqueExpKey] UNIQUE  NONCLUSTERED 
	(
		[provider_id],
		[broker_assigned_id]
	)  ON [PRIMARY] ,
	CONSTRAINT [CK_JobRecord_job_status] CHECK ([job_status] = 'QUEUED' or [job_status] = 'IN PROGRESS' or [job_status] = 'COMPLETE' or [job_status] = 'CANCELLED'),
	CONSTRAINT [CK_JobRecordPriority] CHECK ([priority] >= (-20) and [priority] <= 20)
GO

 CREATE  INDEX [IX_JobRecord_statuspriority] ON [dbo].[JobRecord]([job_status], [priority]) ON [PRIMARY]
GO

 CREATE  INDEX [IX_JobRecord_statusexpID] ON [dbo].[JobRecord]([job_status], [exp_id]) ON [PRIMARY]
GO

 CREATE  INDEX [IX_JobRecord_providergroup] ON [dbo].[JobRecord]([provider_id], [groups]) ON [PRIMARY]
GO

 CREATE  INDEX [IX_JobRecord_datapoints] ON [dbo].[JobRecord]([datapoints]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[LoginRecord] ADD 
	CONSTRAINT [DF_LoginRecord_login_time] DEFAULT (getdate()) FOR [login_time],
	CONSTRAINT [CK_LoginRecord_login_type] CHECK ([login_type] = 'MANUAL' or [login_type] = 'COOKIE')
GO

ALTER TABLE [dbo].[Resources] ADD 
	CONSTRAINT [DF_Resources_date_modified] DEFAULT (getdate()) FOR [date_modified],
	CONSTRAINT [CK_type] CHECK ([type] = 'SETUP' or ([type] = 'OBJECT' or [type] = 'FUNCTION'))
GO

 CREATE  INDEX [IX_Resources_type] ON [dbo].[Resources]([type]) ON [PRIMARY]
GO

 CREATE  INDEX [IX_Resources_name] ON [dbo].[Resources]([name]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[SetupTerminalConfig] ADD 
	CONSTRAINT [DF_SetupTerminalConfig_max_voltage] DEFAULT (0) FOR [max_amplitude],
	CONSTRAINT [DF_SetupTerminalConfig_max_current] DEFAULT (0) FOR [max_current],
	CONSTRAINT [DF_SetupTerminalConfig_max_frequency] DEFAULT (0) FOR [max_frequency],
	CONSTRAINT [DF_SetupTerminalConfig_date_modified] DEFAULT (getdate()) FOR [date_modified],
	CONSTRAINT [DF_SetupTerminalConfig_max_sampling_time] DEFAULT (0) FOR [max_sampling_time],
	CONSTRAINT [DF_SetupTerminalConfig_max_sampling_rate] DEFAULT (0) FOR [max_sampling_rate],
	CONSTRAINT [DF_SetupTerminalConfig_max_offset] DEFAULT (0) FOR [max_offset],
	CONSTRAINT [DF_SetupTerminalConfig_max_points] DEFAULT (0) FOR [max_points],
	CONSTRAINT [IX_SetupandTerminalNumber] UNIQUE  NONCLUSTERED 
	(
		[setup_id],
		[number]
	)  ON [PRIMARY] ,
	CONSTRAINT [CK_instrument] CHECK ([instrument] = 'FGEN' or [instrument] = 'SCOPE')
GO

 CREATE  INDEX [IX_SetupTerminalConfig_type] ON [dbo].[SetupTerminalConfig]([setup_id]) ON [PRIMARY]
GO

 CREATE  INDEX [IX_SetupTerminalConfig_number] ON [dbo].[SetupTerminalConfig]([number]) ON [PRIMARY]
GO

 CREATE  INDEX [IX_SetupTerminalConfig_instrument] ON [dbo].[SetupTerminalConfig]([instrument]) ON [PRIMARY]
GO

 CREATE  INDEX [IX_SetupTerminalConfig_setupterm] ON [dbo].[SetupTerminalConfig]([setupterm_id]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Setups] ADD 
	CONSTRAINT [DF_Setups_terminals_used] DEFAULT (0) FOR [terminals_used],
	CONSTRAINT [DF_Setups_date_modified] DEFAULT (getdate()) FOR [date_modified]
GO

 CREATE  INDEX [IX_Setups_resource] ON [dbo].[Setups]([resource_id]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[SiteUsers] ADD 
	CONSTRAINT [DF_SiteUsers_is_active] DEFAULT (1) FOR [is_active],
	CONSTRAINT [DF_SiteUsers_date_modified] DEFAULT (getdate()) FOR [date_modified]
GO

ALTER TABLE [dbo].[UsageClasses] ADD 
	CONSTRAINT [DF_UsageClasses_amt_member_brokers] DEFAULT (0) FOR [amt_member_brokers],
	CONSTRAINT [DF_UsageClasses_amt_member_groups] DEFAULT (0) FOR [amt_member_groups],
	CONSTRAINT [DF_UsageClasses_amt_member_susers] DEFAULT (0) FOR [amt_member_susers],
	CONSTRAINT [DF_UsageClasses_date-modified] DEFAULT (getdate()) FOR [date_modified]
GO

 CREATE  INDEX [IX_UsageClasses_name] ON [dbo].[UsageClasses]([name]) ON [PRIMARY]
GO

ALTER TABLE [dbo].[WebMethodRequestLog] ADD 
	CONSTRAINT [DF_WebMethodRequestLog_completed_successfully] DEFAULT ('0') FOR [completed_successfully],
	CONSTRAINT [CK_WebMethodRequestLog] CHECK ([type] = 'INCOMING' or [type] = 'OUTGOING')
GO

ALTER TABLE [dbo].[ActiveSetups] ADD 
	CONSTRAINT [FK_ActiveSetups_Setups] FOREIGN KEY 
	(
		[setup_id]
	) REFERENCES [dbo].[Setups] (
		[setup_id]
	)
GO

ALTER TABLE [dbo].[Brokers] ADD 
	CONSTRAINT [FK_Brokers_UsageClasses] FOREIGN KEY 
	(
		[class_id]
	) REFERENCES [dbo].[UsageClasses] (
		[class_id]
	)
GO

ALTER TABLE [dbo].[ClassToResourceMapping] ADD 
	CONSTRAINT [FK_ClassToResourceMapping_Resources] FOREIGN KEY 
	(
		[resource_id]
	) REFERENCES [dbo].[Resources] (
		[resource_id]
	),
	CONSTRAINT [FK_ClassToResourceMapping_UsageClasses] FOREIGN KEY 
	(
		[class_id]
	) REFERENCES [dbo].[UsageClasses] (
		[class_id]
	)
GO

ALTER TABLE [dbo].[Groups] ADD 
	CONSTRAINT [FK_Groups_Brokers] FOREIGN KEY 
	(
		[owner_id]
	) REFERENCES [dbo].[Brokers] (
		[broker_id]
	),
	CONSTRAINT [FK_Groups_UsageClasses] FOREIGN KEY 
	(
		[class_id]
	) REFERENCES [dbo].[UsageClasses] (
		[class_id]
	)
GO

ALTER TABLE [dbo].[SetupTerminalConfig] ADD 
	CONSTRAINT [FK_SetupTerminalConfig_Setups] FOREIGN KEY 
	(
		[setup_id]
	) REFERENCES [dbo].[Setups] (
		[setup_id]
	)
GO

ALTER TABLE [dbo].[Setups] ADD 
	CONSTRAINT [FK_Setups_Resources] FOREIGN KEY 
	(
		[resource_id]
	) REFERENCES [dbo].[Resources] (
		[resource_id]
	)
GO

ALTER TABLE [dbo].[SiteUsers] ADD 
	CONSTRAINT [FK_SiteUsers_UsageClasses] FOREIGN KEY 
	(
		[class_id]
	) REFERENCES [dbo].[UsageClasses] (
		[class_id]
	)
GO


SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Writes initial state data into UsageClasses Table******/
INSERT INTO UsageClasses (name, description, comments, amt_member_brokers, amt_member_groups, date_created, date_modified) VALUES ('Administrators', 'a default class for Lab Server administrators', NULL, '0', '0', GETDATE(), GETDATE())
GO

INSERT INTO UsageClasses (name, description, comments, amt_member_brokers, amt_member_groups, date_created, date_modified) VALUES ('Guests', 'a default class for Lab Server Guests', NULL, '0', '0', GETDATE(), GETDATE())
GO


SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.qm_CancelByLocalID    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.qm_CancelByLocalID    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE qm_CancelByLocalID
	@expID int
AS
--Author(s): James Hardison (hardison@alum.mit.edu(
--Date: 3/7/2003
--This procedure will remove the experiment request specified by @expID from the Experiment Queue by marking the record 
--as 'CANCELLED' in the Jobrecord table.  An experiment may be cancelled only if the job_status field has a value of 
--'QUEUED'. This procedure is the back-end for the Cancel function of the WebLab Queue Manager as described in 
-- the WebLab Queue Manager Method Description document.
BEGIN	
	IF (SELECT 'true' WHERE EXISTS(SELECT * FROM JobRecord WHERE job_status = 'QUEUED' AND exp_id = @expID)) = 'true'
	BEGIN
		UPDATE JobRecord SET job_status = 'CANCELLED', end_time = getdate(), job_elapsed = DATEDIFF(s, submit_time, getdate())
			WHERE job_status = 'QUEUED' AND exp_id = @expID 

		SELECT 'TRUE' as cancelled	
	END
	ELSE
	BEGIN
		SELECT 'FALSE' as cancelled
	END

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.qm_CancelByRemoteID    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.qm_CancelByRemoteID    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE qm_CancelByRemoteID
	@BrokerID int, 
	@RemoteExpID int
AS
--Author(s): James Hardison (hardison@alum.mit.edu(
--Date: 9/26/2003
--This procedure will remove the experiment request specified by the combination of @BrokerID and @RemoteExpID
--from the Experiment Queue by marking the record as 'CANCELLED' in the Jobrecord table.  An experiment may be 
--cancelled only if the job_status field has a value of 'QUEUED'. This procedure is the back-end for the Cancel function 
--of the WebLab Queue Manager as described in the WebLab Queue Manager Method Description document.
BEGIN	
	IF (SELECT 'true' WHERE EXISTS(SELECT * FROM JobRecord WHERE job_status = 'QUEUED' AND provider_id = @BrokerID AND broker_assigned_id = @RemoteExpID)) = 'true'
	BEGIN
		UPDATE JobRecord SET job_status = 'CANCELLED', end_time = getdate(), job_elapsed = DATEDIFF(s, submit_time, getdate())
			WHERE job_status = 'QUEUED' AND provider_id = @BrokerID AND broker_assigned_id = @RemoteExpID 

		SELECT 'TRUE' as cancelled	
	END
	ELSE
	BEGIN
		SELECT 'FALSE' as cancelled
	END

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.qm_Enqueue    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.qm_Enqueue    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE qm_Enqueue 
	@exp ntext,
	@priority int,
	@groups varchar(100),
	@providerID int,
	@broker_assigned_id int, 
	@est_exec_time int,
	@datapoints int,
	@setup_used int	
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 3/10/2003
--
	DECLARE @queueLen int, @estTimeToRun int, @expID int, @date datetime
	DECLARE currQInfo CURSOR
	FOR SELECT COUNT(*), SUM(est_exec_time) 
		FROM JobRecord 
		WHERE job_status = 'QUEUED' AND priority >= @priority
	OPEN currQInfo
	FETCH NEXT FROM currQInfo INTO @queueLen, @estTimeToRun
	
	IF @estTimeToRun = '' or @estTimeToRun = NULL
	BEGIN
		SET @estTimeToRun = 30
	END


	CLOSE currQInfo
	DEALLOCATE currQInfo

	SET @date = getdate()

	INSERT INTO JobRecord (provider_id, broker_assigned_id, groups, priority, job_status, submit_time, est_exec_time, queue_at_insert, datapoints, setup_used, experiment_vector)
		VALUES (@providerID, @broker_assigned_id, @groups, @priority, 'QUEUED', @date, @est_exec_time, (@queueLen + 1), @datapoints, @setup_used, @exp)

	
	SELECT (@queueLen + 1) AS queuePosition, @estTimeToRun AS estTimeToRun

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.qm_FinishJob    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.qm_FinishJob    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE qm_FinishJob 
	@expID int,
	@result ntext,
	@error_msg varchar(2000),
	@erred bit	
AS
--Author(s) James Hardison (hardison@alum.mit.edu)
--Date: 3/7/2003
--This method marks the record specified by the value of @expID in the JobRecord table as 'COMPLETE', sets the end_time timestamp, calculates
-- the elapsed job and execution times and writes the results from the completed experiment specified by experiment_vector into the experiment_results 
--field.  This method is called by the WebLab Experiment Engine at the completion of an experiment as described in the WebLab Queue Manager Method 
--Description document.

BEGIN
	DECLARE @endTime datetime, @currErrorMsg varchar(2000)
	
	SET @endTime = getdate()	

	DECLARE currError CURSOR FOR
		SELECT error_report 
			FROM JobRecord 
			WHERE job_status = 'IN PROGRESS' AND exp_id = @expID
	OPEN currError
	FETCH NEXT FROM currError INTO @currErrorMsg	
	CLOSE currError
	DEALLOCATE currError

	IF @currErrorMsg = NULL
	BEGIN
		SET @currErrorMsg = ''
	END

	--IF NOT @error_msg = '' 
	--BEGIN
	--	SET @error_msg = @error_msg + ';;'
	--END
	
	SET @currErrorMsg = @currErrorMsg + @error_msg

	

	UPDATE JobRecord 
		SET job_status = 'COMPLETE', end_time = @endTime, exec_elapsed = DATEDIFF(s, exec_time, @endTime), job_elapsed = DATEDIFF(s, submit_time, @endTime), experiment_results = @result, error_report = @currErrorMsg, error_occurred = @erred 
		WHERE job_status = 'IN PROGRESS' AND exp_id = @expID

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.qm_LoadJob    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.qm_LoadJob    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE qm_LoadJob AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 3/6/2003
--
BEGIN 

	DECLARE @expID int
	DECLARE exp_cursor CURSOR
	FOR SELECT TOP 1 exp_id
		FROM JobRecord 
		WHERE job_status = 'QUEUED'  
		ORDER BY priority DESC, submit_time

	OPEN exp_cursor
	FETCH NEXT FROM exp_cursor INTO @expID
	
	 UPDATE JobRecord SET job_status = 'IN PROGRESS', exec_time = GETDATE() WHERE exp_id = @expID
	

	SELECT @expID AS expID, experiment_vector AS exp, provider_id, groups FROM JobRecord WHERE exp_id = @expID 

	CLOSE exp_cursor
	DEALLOCATE exp_cursor
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.qm_LogConfigAtExec    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.qm_LogConfigAtExec    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE qm_LogConfigAtExec
	@expID int, 	--required for record identification
	@labConfig ntext	--required, the payload
 AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 8/1/2003
--This method is designed to be used by the WebLab Lab Server Experiment Execution Engine.  This method take as input a valid experiment id and lab configuration.  The
--effect is that the value of @labConfig is written to the lab_config_at_exec field of the JobRecord record referenced by @expID.  
BEGIN
	IF (SELECT 'true' WHERE NOT EXISTS(SELECT exp_id FROM JobRecord WHERE exp_id = @expID AND job_status = 'IN PROGRESS')) = 'true' OR @expID = '' OR @expID = NULL
	BEGIN
		RETURN
	END
	ELSE
	BEGIN
		UPDATE JobRecord SET lab_config_at_exec = @labConfig WHERE exp_id = @expID
		RETURN
	END
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.qm_RecoverJobs    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.qm_RecoverJobs    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE qm_RecoverJobs AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/8/2003
--Intended caller(s): experiment engine only (once at startup)
--This method ensures that no jobs will be stranded in the queue with a status of "IN PROGRESS".  Specifically, the experiment engine behaves such that, if execution is 
--terminated after a job is dequeued but before it is completed (system failure or manual process shut-down) the job being operated upon at the time is left marked as in
--progress.  Thus, when the experiment engine is restarted, this job will be overlooked by the load job process.  To remedy this, this method will edit all in progress jobs 
--such that their status is set to "QUEUED" and their priority set to "20" (so that, even if the job was low priority initially, it will run before all non-recovered jobs).
BEGIN
	UPDATE JobRecord SET job_status = 'QUEUED', priority = '20', error_report = 'execution terminated due to module failure, retrying;;'  WHERE job_status = 'IN PROGRESS'
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rm_LogIncomingWebRequest    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rm_LogIncomingWebRequest    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rm_LogIncomingWebRequest 
	@source_broker_id int,
	@method_name varchar(100),
	@has_permission bit,
	@completed_successfully bit,
	@completion_status varchar(1000)
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 7/10/2003
--This method logs an incoming web service transaction in the WebMethodRequestLog.  There is no return value.
BEGIN
	DECLARE @sourceName varchar(250)

	IF @source_broker_id = -1 
	BEGIN
		SET @sourceName = 'Unknown Caller'
	END
	ELSE
	BEGIN
		SET @sourceName = (SELECT name FROM Brokers WHERE broker_id = @source_broker_id)	
	END

	INSERT INTO WebMethodRequestLog (type, source_name, dest_name, method_name, out_dest_URL, in_has_permission, completed_successfully, completion_status, transaction_time)
		VALUES ('INCOMING', @sourceName, 'WebLab LS', @method_name, '', @has_permission, @completed_successfully, @completion_status, GETDATE())

RETURN
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rm_LogOutgoingWebRequest    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rm_LogOutgoingWebRequest    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rm_LogOutgoingWebRequest 
	@dest_broker_id int,
	@method_name varchar(100),
	@dest_URL varchar(100),
	@completed_successfully bit, 
	@completion_status varchar(1000)
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 7/10/2003
--This method logs an outgoing web service transaction in the WebMethodRequestLog.  There is no return value.
BEGIN
	DECLARE @destName varchar(250), @destURL varchar(100)

	SET @destName = (SELECT name FROM Brokers WHERE broker_id = @dest_broker_id)	

	INSERT INTO WebMethodRequestLog (type, source_name, dest_name, method_name, out_dest_URL, in_has_permission, completed_successfully, completion_status, transaction_time)
		VALUES ('OUTGOING', 'WebLab LS', @destName, @method_name, @dest_URL, '1', @completed_successfully, @completion_status, GETDATE())

RETURN
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rm_RetrieveResultByLocalID    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rm_RetrieveResultByLocalID    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rm_RetrieveResultByLocalID
	@expID int
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 4/24/2003
--This method returns the results and/or error messages associated with the specified experiment id.  In addition to returning this data, this method marks 
--the appropriate experiment record as having had it's results downloaded.  This method is used by the WebLab Records Manager to return experiment results 
--to an authorized service broker.

BEGIN
	DECLARE @returnedID int, @error_occurred bit, @jobStatus varchar(20), @expStatusCode int
	
	DECLARE expRecord CURSOR FOR
		SELECT exp_id, job_status, error_occurred FROM JobRecord WHERE exp_id = @expID

	OPEN expRecord
	FETCH NEXT FROM expRecord INTO @returnedID, @jobStatus, @error_occurred

	CLOSE expRecord
	DEALLOCATE expRecord

	IF @returnedID = '' OR @returnedID = NULL
	BEGIN
		SET @expStatusCode = '6'
	END
	ELSE IF @jobStatus = 'QUEUED'
	BEGIN
		SET @expStatusCode = '1'
	END
	ELSE IF @jobStatus = 'IN PROGRESS'
	BEGIN
		SET @expStatusCode = '2'
	END
	ELSE IF @jobStatus = 'CANCELLED'
	BEGIN
		SET @expStatusCode = '5'
	END
	ELSE IF @jobStatus = 'COMPLETE' AND @error_occurred = '0'
	BEGIN
		SET @expStatusCode = '3'
	END
	ELSE IF @jobStatus = 'COMPLETE' AND @error_occurred = '1'
	BEGIN
		SET @expStatusCode = '4'
	END

	IF @expStatusCode = '3' 
	BEGIN
		UPDATE JobRecord SET downloaded = '1' WHERE exp_id = @expID

		SELECT @expStatusCode AS experimentStatus, experiment_results AS experimentResults, error_report AS warningMessages, '' AS errorMessages, lab_config_at_exec AS labConfig 
			FROM JobRecord 
			WHERE exp_id = @expID
		RETURN
	END
	ELSE IF @expStatusCode = '4'
	BEGIN
		UPDATE JobRecord SET downloaded = '1' WHERE exp_id = @expID

		SELECT @expStatusCode AS experimentStatus, experiment_results AS experimentResults, '' AS warningMessages, error_report AS errorMessages, lab_config_at_exec AS labConfig  
			FROM JobRecord 
			WHERE exp_id = @expID
		RETURN
	END
	ELSE 
	BEGIN
		SELECT @expStatusCode AS experimentStatus,'' AS experimentResults, '' AS warningMessages, '' AS errorMessages, '' AS labConfig
		RETURN
	END

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rm_RetrieveResultByRemoteID    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rm_RetrieveResultByRemoteID    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rm_RetrieveResultByRemoteID
	@brokerID int,
	@remoteExpID int
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 4/24/2003
--This method returns the results and/or error messages associated with the specified by the brokerID/remote experiment id combo.  In addition to returning this data, this method marks 
--the appropriate experiment record as having had it's results downloaded.  This method is used by the WebLab Records Manager to return experiment results 
--to an authorized service broker.

BEGIN
	DECLARE @returnedID int, @error_occurred bit, @jobStatus varchar(20), @expStatusCode int
	
	DECLARE expRecord CURSOR FOR
		SELECT exp_id, job_status, error_occurred FROM JobRecord WHERE provider_id = @brokerID AND broker_assigned_id = @remoteExpID

	OPEN expRecord
	FETCH NEXT FROM expRecord INTO @returnedID, @jobStatus, @error_occurred

	CLOSE expRecord
	DEALLOCATE expRecord

	IF @returnedID = '' OR @returnedID = NULL
	BEGIN
		SET @expStatusCode = '6'
	END
	ELSE IF @jobStatus = 'QUEUED'
	BEGIN
		SET @expStatusCode = '1'
	END
	ELSE IF @jobStatus = 'IN PROGRESS'
	BEGIN
		SET @expStatusCode = '2'
	END
	ELSE IF @jobStatus = 'CANCELLED'
	BEGIN
		SET @expStatusCode = '5'
	END
	ELSE IF @jobStatus = 'COMPLETE' AND @error_occurred = '0'
	BEGIN
		SET @expStatusCode = '3'
	END
	ELSE IF @jobStatus = 'COMPLETE' AND @error_occurred = '1'
	BEGIN
		SET @expStatusCode = '4'
	END

	IF @expStatusCode = '3' 
	BEGIN
		UPDATE JobRecord SET downloaded = '1' WHERE provider_id = @brokerID AND broker_assigned_id = @remoteExpID

		SELECT @expStatusCode AS experimentStatus, experiment_results AS experimentResults, error_report AS warningMessages, '' AS errorMessages, lab_config_at_exec AS labConfig 
			FROM JobRecord 
			WHERE provider_id = @brokerID AND broker_assigned_id = @remoteExpID
		RETURN
	END
	ELSE IF @expStatusCode = '4'
	BEGIN
		UPDATE JobRecord SET downloaded = '1' WHERE provider_id = @brokerID AND broker_assigned_id = @remoteExpID

		SELECT @expStatusCode AS experimentStatus, experiment_results AS experimentResults, '' AS warningMessages, error_report AS errorMessages, lab_config_at_exec AS labConfig  
			FROM JobRecord 
			WHERE provider_id = @brokerID AND broker_assigned_id = @remoteExpID
		RETURN
	END
	ELSE 
	BEGIN
		SELECT @expStatusCode AS experimentStatus,'' AS experimentResults, '' AS warningMessages, '' AS errorMessages, '' AS labConfig
		RETURN
	END

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rm_ReturnJobLogSubset    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rm_ReturnJobLogSubset    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rm_ReturnJobLogSubset 
	@startIdx int, 
	@interval int
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 12/16/2003
--This method returns a subset of the completed/cancelled job records in the JobRecord table, constrained by a specified start index and interval.  @startIdx should be less than the 
--total number of records in the returned set.  @interval should be non-zero positive when indicating a subset size and 0 when the entire set should be returned. 
BEGIN

DECLARE @expId numeric(18,0), @providerId numeric(18,0), @providerName varchar(250), @groups varchar(100), @jobStatus varchar(50), @submitTime datetime, @execTime datetime, @end_time datetime, @exec_elapsed int, @jobElapsed int, @queueAtInsert int, @setupUsed int, @setupName varchar(250), @errorOccurred bit
DECLARE @index int


	DECLARE @outputTable TABLE (
		exp_id numeric(18,0),
		provider_id numeric(18,0),
		provider_name varchar(250),
		groups varchar(100),
		job_status varchar(50),
		submit_time datetime,
		exec_time datetime,
		end_time datetime,
		exec_elapsed int,
		job_elapsed int,
		queue_at_insert int,
		setup_used int,
		setup_name varchar(250),
		error_occurred bit)		


IF @startIdx > 0 AND @startIdx <= (SELECT COUNT(*) FROM JobRecord WHERE NOT job_status = 'IN PROGRESS' AND NOT job_status = 'QUEUED')
BEGIN
	IF @interval <= 0 
	BEGIN
		INSERT INTO @outputTable (exp_id, provider_id, provider_name, groups, job_status, submit_time, exec_time, end_time, exec_elapsed, job_elapsed, queue_at_insert, setup_used, setup_name, error_occurred)
			SELECT j.exp_id, j.provider_id, b.name, j.groups, j.job_status, j.submit_time, j.exec_time, j.end_time, j.exec_elapsed, j.job_elapsed, j.queue_at_insert, j.setup_used, r.name, j.error_occurred FROM JobRecord j LEFT JOIN Brokers b ON j.provider_id = b.broker_id LEFT JOIN Setups d ON j.setup_used = d.setup_id LEFT JOIN Resources r ON d.resource_id = r. resource_id WHERE NOT job_status = 'IN PROGRESS' AND NOT job_status = 'QUEUED' ORDER BY submit_time DESC
	END
	ELSE
	BEGIN
			
		DECLARE dataLog SCROLL CURSOR FOR
			SELECT j.exp_id, j.provider_id, b.name, j.groups, j.job_status, j.submit_time, j.exec_time, j.end_time, j.exec_elapsed, j.job_elapsed, j.queue_at_insert, j.setup_used, r.name, j.error_occurred FROM JobRecord j LEFT JOIN Brokers b ON j.provider_id = b.broker_id LEFT JOIN Setups d ON j.setup_used = d.setup_id LEFT JOIN Resources r ON d.resource_id = r. resource_id WHERE NOT job_status = 'IN PROGRESS' AND NOT job_status = 'QUEUED' ORDER BY submit_time DESC
		
		OPEN dataLog
		
		FETCH ABSOLUTE @startIdx FROM dataLog INTO @expId, @providerId, @providerName, @groups, @jobStatus, @submitTime, @execTime, @end_time, @exec_elapsed, @jobElapsed, @queueAtInsert, @setupUsed, @setupName, @errorOccurred
	
		SET @index = 1
		
		WHILE @index <= @interval AND @@FETCH_STATUS = 0
		BEGIN
			INSERT INTO @outputTable (exp_id, provider_id, provider_name, groups, job_status, submit_time, exec_time, end_time, exec_elapsed, job_elapsed, queue_at_insert, setup_used, setup_name, error_occurred)
			                               VALUES (@expId, @providerId, @providerName, @groups, @jobStatus, @submitTime, @execTime, @end_time, @exec_elapsed, @jobElapsed, @queueAtInsert, @setupUsed, @setupName, @errorOccurred)
		
			FETCH NEXT FROM dataLog INTO @expId, @providerId, @providerName, @groups, @jobStatus, @submitTime, @execTime, @end_time, @exec_elapsed, @jobElapsed, @queueAtInsert, @setupUsed, @setupName, @errorOccurred
		
			SET @index = @index + 1
	
	
		END
	
		CLOSE dataLog
		DEALLOCATE dataLog
	END
END

SELECT * FROM @outputTable

RETURN

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rm_ReturnLoginLogSubset    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rm_ReturnLoginLogSubset    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rm_ReturnLoginLogSubset 
	@startIdx int, 
	@interval int
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 12/16/2003
--This method returns a subset of the records in the WebMethodRequestLog table, constrained by a specified start index and interval.  @startIdx should be less than the 
--total number of records in the returned set.  @interval should be non-zero positive when indicating a subset size and 0 when the entire set should be returned. 
BEGIN

DECLARE @recordID int, @login_type varchar(10), @user_id int, @user_name varchar(20), @remoteIP varchar(20), @userAgent varchar(500), @loginTime datetime
DECLARE @index int


	DECLARE @outputTable TABLE (
		record_id int,
		login_type varchar(10), 
		user_id int,
		username varchar(20),
		remote_ip varchar(20),
		user_agent varchar(500),
		login_time datetime)

IF @startIdx > 0 AND @startIdx <= (SELECT COUNT(*) FROM LoginRecord)
BEGIN
	IF @interval <= 0 
	BEGIN
		INSERT INTO @outputTable (record_id, login_type, user_id, username, remote_ip, user_agent, login_time)
			SELECT l.record_id, l.login_type, l.user_id, u.username, l.remote_ip, l.user_agent, l.login_time FROM LoginRecord l LEFT JOIN SiteUsers u ON l.user_id = u.user_id ORDER BY l.login_time DESC
	END
	ELSE
	BEGIN
			
		DECLARE dataLog SCROLL CURSOR FOR
			SELECT l.record_id, l.login_type, l.user_id, u.username, l.remote_ip, l.user_agent, l.login_time FROM LoginRecord l LEFT JOIN SiteUsers u ON l.user_id = u.user_id ORDER BY l.login_time DESC
		
		OPEN dataLog
		
		FETCH ABSOLUTE @startIdx FROM dataLog INTO @recordID, @login_type, @user_id, @user_name, @remoteIP, @userAgent, @loginTime

		SET @index = 1
		
		WHILE @index <= @interval AND @@FETCH_STATUS = 0
		BEGIN
			INSERT INTO @outputTable (record_id, login_type, user_id, username, remote_ip, user_agent, login_time)
			VALUES (@recordID, @login_type, @user_id, @user_name, @remoteIP, @userAgent, @loginTime)
		
			FETCH NEXT FROM dataLog INTO @recordID, @login_type, @user_id, @user_name, @remoteIP, @userAgent, @loginTime
		
			SET @index = @index + 1
	
	
		END
	
		CLOSE dataLog
		DEALLOCATE dataLog
	END
END

SELECT * FROM @outputTable

RETURN

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rm_ReturnWSIntLogSubset    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rm_ReturnWSIntLogSubset    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rm_ReturnWSIntLogSubset 
	@startIdx int, 
	@interval int
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 11/7/2003
--This method returns a subset of the records in the WebMethodRequestLog table, constrained by a specified start index and interval.  @startIdx should be less than the 
--total number of records in the returned set.  @interval should be non-zero positive when indicating a subset size and 0 when the entire set should be returned. 
BEGIN

DECLARE @requestID int, @type varchar(10), @sourceName varchar(250), @destName varchar(250), @methodName varchar(100), @outDestURL varchar(500), @inHasPerm bit, @completed bit, @compStat varchar(1000), @transTime dateTime
DECLARE @index int


	DECLARE @outputTable TABLE (
		request_id int,
		type varchar(10),
		source_name varchar(250),
		dest_name varchar(250),
		method_name varchar(100),
		out_dest_URL varchar(500),
		in_has_permission bit,
		completed_successfully bit,
		completion_status varchar(1000),
		transaction_time datetime)

IF @startIdx > 0 AND @startIdx <= (SELECT COUNT(*) FROM WebMethodRequestLog)
BEGIN
	IF @interval <= 0 
	BEGIN
		INSERT INTO @outputTable (request_id, type, source_name, dest_name, method_name, out_dest_URL, in_has_permission, completed_successfully, completion_status, transaction_time)
			SELECT request_id, type, source_name, dest_name, method_name, out_dest_URL, in_has_permission, completed_successfully, completion_status, transaction_time FROM WebMethodRequestLog ORDER BY transaction_time DESC
	END
	ELSE
	BEGIN
			
		DECLARE dataLog SCROLL CURSOR FOR
			SELECT request_id, type, source_name, dest_name, method_name, out_dest_URL, in_has_permission, completed_successfully, completion_status, transaction_time FROM WebMethodRequestLog ORDER BY transaction_time DESC;
		
		OPEN dataLog
		
		FETCH ABSOLUTE @startIdx FROM dataLog INTO @requestID, @type, @sourceName, @destName, @methodName, @outDestURL, @inHasPerm, @completed, @compStat, @transTime
		
		--INSERT INTO @outputTable (request_id, type, source_name, dest_name, method_name, out_dest_URL, in_has_permission, completed_successfully, completion_status, transaction_time)
		--	VALUES (@requestID, @type, @sourceName, @destName, @methodName, @outDestURL, @inHasPerm, @completed, @compStat, @transTime)
		
		SET @index = 1
		
		WHILE @index <= @interval AND @@FETCH_STATUS = 0
		BEGIN
			INSERT INTO @outputTable (request_id, type, source_name, dest_name, method_name, out_dest_URL, in_has_permission, completed_successfully, completion_status, transaction_time)
			VALUES (@requestID, @type, @sourceName, @destName, @methodName, @outDestURL, @inHasPerm, @completed, @compStat, @transTime)
		
			FETCH NEXT FROM dataLog INTO @requestID, @type, @sourceName, @destName, @methodName, @outDestURL, @inHasPerm, @completed, @compStat, @transTime
		
			SET @index = @index + 1
	
	
		END
	
		CLOSE dataLog
		DEALLOCATE dataLog
	END
END

SELECT * FROM @outputTable

RETURN

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_ActivateBroker    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_ActivateBroker    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_ActivateBroker
	@brokerID int,
	@activateGroups bit
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/15/2003
--This method sets the 'is_active' field in the specified broker to 1.  If @activateGroups is set to 1, all of the groups owned by the specified broker are also activated.  
--If successful, the method returns the string 'SUCCESS'.  If the procedure fails (if the specified broker is invalid) then the string 'ERROR' is returned and no change is made.
BEGIN
	IF (SELECT 'true' WHERE NOT EXISTS(SELECT broker_id from Brokers WHERE broker_id = @brokerID)) = 'true'
	BEGIN	
		SELECT 'ERROR' AS Result
		RETURN
	END
	ELSE
	BEGIN
		UPDATE Brokers SET is_active = '1', date_modified = GETDATE() WHERE broker_id = @brokerID

		IF @activateGroups = '1' 
		BEGIN
			UPDATE Groups SET is_active = '1', date_modified = GETDATE() WHERE owner_id = @brokerID
		END
		
		SELECT 'SUCCESS' as Result
		RETURN
	END
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_ActivateGroup    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_ActivateGroup    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_ActivateGroup
	@groupID int
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/16/2003
--This method sets the 'is_active' field in the specified group to 1.  If successful, the method returns the string 'SUCCESS'.  If the procedure fails (if the specified group is 
--invalid) then the string 'ERROR' is returned and no change is made.
BEGIN
	IF (SELECT 'true' WHERE NOT EXISTS(SELECT group_id from Groups WHERE group_id = @groupID)) = 'true'
	BEGIN	
		SELECT 'ERROR' AS Result
		RETURN
	END
	ELSE
	BEGIN
		UPDATE Groups SET is_active = '1', date_modified = GETDATE() WHERE group_id = @groupID
		
		SELECT 'SUCCESS' as Result
		RETURN
	END
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_ActivateSiteUser    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_ActivateSiteUser    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_ActivateSiteUser
	@userID int
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 6/14/2004
--This method sets the 'is_active' field in the specified site user to 1.  
--If successful, the method returns the string 'SUCCESS'.  If the procedure fails (if the specified broker is invalid) then the string 'ERROR' is returned and no change is made.
BEGIN
	IF (SELECT 'true' WHERE NOT EXISTS(SELECT user_id from SiteUsers WHERE user_id = @userID)) = 'true'
	BEGIN	
		SELECT 'ERROR' AS Result
		RETURN
	END
	ELSE
	BEGIN
		UPDATE SiteUsers SET is_active = '1', date_modified = GETDATE() WHERE user_id = @userID
		
		SELECT 'SUCCESS' as Result
		RETURN
	END
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_AddBroker    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_AddBroker    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_AddBroker
	@name varchar(250), --required
	@broker_server_id varchar(35), --required
	@broker_passkey varchar(100), --required
	@server_passkey varchar(100), --required 
	@classID int, --required (0 or valid class id)
	@description varchar(1000), --required
	@contact_first_name varchar(100), --required
	@contact_last_name varchar(100), --required
	@contact_email varchar(100), --required
	@notify_location varchar(200), --may be empty string
	@is_active bit --required (0 or 1)
AS
--Author(s): James Hardison (hardison@alum.mit.edu
--Date: 3/27/2003
--This method adds a Service Provider record into the Providers table.  Specifically, this method checks that the supplied name is not already in use, makes 
--sure that the required fields are not null and, passing these, inserts the record and returns an indication of success to the caller as well as the provider_id.  If any of these checks fail,
--a message is returned to the caller.  The ID of the class the broker will be associated with can be specified here, if @classID is invalid, null or 0, the broker will be added 
--to the default Lab Server Guest Class (ID = 2)
BEGIN
	DECLARE @returnText varchar(100), @returnID int

	IF @name = '' OR @name = NULL
	BEGIN
		SET @returnText = 'Error - A name must be supplied.'
		SET @returnID = 0
		SELECT @returnID AS BrokerID, @returnText AS Comments
		RETURN
	END	
	ELSE
	IF @broker_server_id = '' OR @broker_server_id = NULL 
	BEGIN
		SET @returnText = 'Error - A server id must be supplied.'
		SET @returnID = 0
		SELECT @returnID AS BrokerID, @returnText AS Comments
		RETURN
	END
	ELSE
	IF @broker_passkey = '' OR @broker_passkey = NULL
	BEGIN
		SET @returnText = 'Error - A broker passkey must be supplied.'
		SET @returnID = 0
		SELECT @returnID AS BrokerID, @returnText AS Comments
		RETURN
	END
	ELSE
	IF @server_passkey = '' OR @server_passkey = NULL
	BEGIN
		SET @returnText = 'Error - A lab server passkey must be supplied.'
		SET @returnID = 0
		SELECT @returnID AS BrokerID, @returnText AS Comments
		RETURN
	END
	ELSE
	IF @description = '' OR @description = NULL
	BEGIN
		SET @returnText = 'Error - A description must be supplied.'
		SET @returnID = 0
		SELECT @returnID AS BrokerID, @returnText AS Comments
		RETURN
	END
	ELSE
	IF @contact_first_name = '' OR @contact_first_name = NULL
	BEGIN
		SET @returnText = 'Error - A full contact name  must be supplied.'
		SET @returnID = 0
		SELECT @returnID AS BrokerID, @returnText AS Comments
		RETURN
	END
	ELSE
	IF @contact_last_name = '' OR @contact_last_name = NULL
	BEGIN
		SET @returnText = 'Error - A full contact name must be supplied.'
		SET @returnID = 0
		SELECT @returnID AS BrokerID, @returnText AS Comments
		RETURN
	END
	ELSE
	IF @contact_email = '' OR @contact_email= NULL
	BEGIN
		SET @returnText = 'Error - A contact email address must be supplied.'
		SET @returnID = 0
		SELECT @returnID AS BrokerID, @returnText AS Comments
		RETURN
	END
	ELSE
	IF (SELECT 'true' WHERE EXISTS(SELECT name FROM Brokers WHERE name = @name)) = 'true'
	BEGIN
		SET @returnText = 'Error - The supplied name is in use, please select another name.'
		SET @returnID = 0
		SELECT @returnID AS BrokerID, @returnText AS Comments
		RETURN			
	END
	ELSE
	BEGIN
		IF (SELECT 'true' WHERE NOT EXISTS(SELECT class_id FROM UsageClasses WHERE class_id = @classID)) = 'true' OR @classID = '' OR @classID = NULL
		BEGIN
			SET @classID= 2
		END
		INSERT INTO Brokers (name, broker_server_id, broker_passkey, server_passkey, class_id, description, contact_first_name, contact_last_name, contact_email, is_active, notify_location, date_created)	
			VALUES (@name, @broker_server_id, @broker_passkey, @server_passkey, @classID, @description, @contact_first_name, @contact_last_name, @contact_email, @is_active, @notify_location, getdate())

		UPDATE UsageClasses SET amt_member_brokers = amt_member_brokers + 1, date_modified = GETDATE() WHERE class_id = @classID

		SET @returnText = 'Broker successfully added.'
		SELECT broker_id AS BrokerID, @returnText AS Comments FROM Brokers WHERE name = @name AND broker_passkey = @broker_passkey
		RETURN
	
	END

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_AddClass    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_AddClass    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_AddClass 
	@name varchar(100), --required
	@description varchar(100) --required
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 3/27/2003
--This method adds a Usage Class record to the UsageClasses table.  Specifically, this method checks that the required fields are filled and that the name 
--submitted is not already in use.  If any of these checks fail, an error message is returned.  Otherwise, the record is created and a success message is returned.
BEGIN
	DECLARE @returnText varchar(100)

	IF @name = '' OR @name = NULL
	BEGIN
		SET @returnText = 'Error - A name must be supplied.'
		SELECT @returnText AS Comments
		RETURN
	END
	ELSE
	IF @description = '' OR @description = NULL
	BEGIN
		SET @returnText = 'Error - A description must be supplied.'
		SELECT @returnText AS Comments
		RETURN
	END
	ELSE
	IF (SELECT 'true' WHERE EXISTS(SELECT class_id FROM UsageClasses WHERE name = @name)) = 'true'
	BEGIN
		SET @returnText = 'Error - The name ''' + @name + ''' is already in use, please select another name.'
		SELECT @returnText AS Comments
		RETURN
	END
	ELSE
	BEGIN		
		INSERT INTO UsageCLasses (name, description, date_created)
			VALUES (@name, @description, getdate())

		SET @returnText = 'Usage Class successfully added'
		SELECT @returnText AS Comments
		RETURN
	END	
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_AddGroup    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_AddGroup    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_AddGroup
	@owner_id int, --required
	@class_id int, --optional, if null/invalid default is 2 (guests)
	@name varchar(100), --required
	@description varchar(1000), --required
	@is_active bit --optional, default is 1 (active)
AS
--Author(s): James Hardison (hardison@alum.mit.edu
--Date: 5/16/2003
--This method adds a Lab Registered Group record into the Groups table.  Specifically, this method checks that all required fields are filled, that the owner_id 
--refers to a valid Service Provider record and that there are no pre-existing records with the same name and owner_id.  If any of these checks fail, an error 
--mesage is returned.  Otherwise, the record is inserted , the group is added to the specified class or, if the specified value is invalid, the default guest class
--and the caller is returned an indication of success.
BEGIN
	DECLARE @returnText varchar(100)

	IF (SELECT 'true' WHERE NOT EXISTS(SELECT broker_id FROM Brokers WHERE is_active = '1' AND broker_id = @owner_id)) = 'true'
	BEGIN
		SET @returnText = 'Error - The group owner id must reference an valid, active Service Broker.'
		SELECT @returnText AS Comments 
		RETURN
	END
	ELSE
	IF @name = '' OR @name = NULL
	BEGIN
		SET @returnText = 'Error - A name must be supplied.'
		SELECT @returnText AS Comments
		RETURN
	END	
	ELSE
	IF @description = '' OR @description = NULL
	BEGIN
		SET @returnText = 'Error - A description must be supplied.'
		SELECT @returnText AS Comments
		RETURN
	END
	ELSE
	IF (SELECT 'true' WHERE EXISTS(SELECT group_id FROM Groups WHERE owner_id = @owner_id AND name = @name)) = 'true'
	BEGIN
		SET @returnText = 'Error - The name ''' + @name + ''' is already in used by the specified provider, please select another name.'
		SELECT @returnText AS Comments
		RETURN
	END
	ELSE
	BEGIN
		IF (SELECT 'true' WHERE NOT EXISTS(SELECT class_id FROM UsageClasses WHERE class_id = @class_id)) = 'true' OR @class_id = '' OR @class_id = NULL
		BEGIN
			SET @class_id = 2
		END
		IF @is_active = '' OR @is_active = NULL
		BEGIN
			SET @is_active = 1
		END
		INSERT INTO Groups (owner_id, class_id, name, description, is_active, date_created)
			VALUES(@owner_id, @class_id, @name, @description, @is_active, getdate())

		UPDATE UsageClasses SET amt_member_groups = amt_member_groups + 1, date_modified = GETDATE() WHERE class_id = @class_id

		SET @returnText = 'Group successully added.'
		SELECT @returnText AS Comments
		RETURN
	END

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_AddResource    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_AddResource    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_AddResource
	@name varchar(150), --required, name of the resource
	@type varchar(10), --required, resource type, only 'function' and 'object are acceptable
	@category varchar(150), --required, custom resource category
	@description varchar(1000) --required, resource description
 AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 3/28/2003
--This method adds a System Resource record to the Resources table.  Specifically, the method checks that all required fields are filled and that the supplied type
--value is valid.  Failing this, an error message is returned to the caller.  Otherwise, the record is inserted and the method proceeds.  Once the record is added,  
--a class-resource mapping is created between the new resource and the default Site Administrators (class_id = 1) usage class granting full access to the 
--resource.  Once this mapping has been created, an indication of success is returned to the caller.
--Note: SETUPS MAY NOT BE ADDED VIA THIS METHOD.  The rpm_AddSetup method must be used to create a new system setup..  
--rpm_AddSetup also performs the functions in this method
BEGIN
	DECLARE @new_resource_id int, @admin_map_comment varchar(100), @ins_error int, @caller_out varchar(100)

	IF @name = '' OR @name = NULL
	BEGIN
		SET @caller_out = 'Error - A name must be supplied.'
		SELECT @caller_out AS Comments
		RETURN
	END
	ELSE
	IF (SELECT 'true' WHERE EXISTS(SELECT resource_id FROM Resources WHERE name = @name)) = 'true'
	BEGIN
		SET @caller_out = 'Error - The supplied name is in use, please select another name.'
		SELECT @caller_out AS Comments
		RETURN	
	END
	ELSE
	IF NOT (UPPER(@type) = 'FUNCTION' OR UPPER(@type) = 'OBJECT')
	BEGIN
		SET @caller_out = 'Error - Invalid resource type.'
		SELECT @caller_out AS Comments 
		RETURN
	END
	ELSE
	IF @category = '' OR @category = NULL
	BEGIN
		SET @caller_out = 'Error - A resource category must be supplied.'
		SELECT @caller_out AS Comments
		RETURN
	END
	ELSE
	IF @description = '' OR @description = NULL
	BEGIN
		SET @caller_out = 'Error - A resource description must be supplied.'
		SELECT @caller_out AS Comments
		RETURN
	END
	ELSE
	BEGIN TRAN
		INSERT INTO Resources (name, type, category, description, date_created)
			VALUES (@name, @type, @category, @description, getdate())

		SET @new_resource_id = (SELECT resource_id FROM Resources WHERE name = @name)	
		
		INSERT INTO ClassToResourceMapping (resource_id, class_id, can_view, can_edit, can_grant, can_delete, priority, date_created)
			VALUES (@new_resource_id, '1', '1', '1', '1', '1', '0', getdate())		

		SET @ins_error = @@ERROR

		IF @ins_error <> 0
		BEGIN
			ROLLBACK TRAN
			SET @caller_out = 'Error during insertion.'
		END
		ELSE
		BEGIN
			COMMIT TRAN
			SET @caller_out = 'Resource successfully added.'
		END

		SELECT @caller_out AS Comments 
		RETURN
	
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_AddSetup    Script Date: 1/11/2007 4:18:47 PM ******/




/****** Object:  Stored Procedure dbo.rpm_AddSetup    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE   PROCEDURE rpm_AddSetup
	@name varchar(100), --required, the name of the setup, this will also be the name of the associated resource as well as that displayed to the user.
	@icon_path varchar(250), --may be empty, filesystem location of icon from web root
	@category varchar(100), --required, a user-defined categorization for this setup/resource
	@description varchar(1000) --may be null, a description of the setup.
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/28/2003
--This method will create an experiment setup on the lab server.  the setup will be the software equivalent of an actual, physical experiment setup available for test.
--The setup will also define its terminal assignments.  Specific terminal configurations wll be stored in the 
--SetupTerminalConfig table and linked to the appropriate setup record.  In particular, this method will check that all of the input information is valid. 
--The name should be unique among all resources and a user-defined category must be supplied.  Also compliance values must be set.  
--Individual terminals are created separately after the setup has been created  
--If any of these checks fail, an error message will be returned to the caller.  Otherwise, a resource with the supplied name and a mapping between that resource and 
--the default administrator class will be created.  The setup itself will then be created.  If an error occurs during this process and error will be returned and no changes 
-- wiill be committed.  If no failure occurrs, an indication of success will be passed to the caller.
BEGIN
	DECLARE @return_msg varchar(100)

	IF (SELECT 'true' WHERE EXISTS(SELECT resource_id FROM Resources WHERE name = @name)) = 'true' OR @name = '' OR @name = NULL
	BEGIN
		SET @return_msg = 'Error - A unique name must be specified.'
		SELECT @return_msg AS Comments
		RETURN
	END
	ELSE
	IF @category = '' OR @category = NULL
	BEGIN
		SET @return_msg = 'Error - A resource category must be specified.'
		SELECT @return_msg AS Comments
		RETURN
	END
	ELSE
	BEGIN TRAN
		DECLARE @new_resource_id int, @new_setup_id int, @curr_term_id int, @date datetime
		--create the setup resource and create administrative mapping.
		SET @date = GETDATE()
		
		INSERT INTO Resources (name, type, category, description, date_created)
			VALUES (@name, 'SETUP', @category, @description, @date)

		SET @new_resource_id = (SELECT resource_id FROM Resources WHERE name = @name AND type = 'SETUP' AND date_created = @date)

		INSERT INTO ClassToResourceMapping (resource_id, class_id, can_view, can_edit, can_grant, can_delete, priority, date_created)
			VALUES (@new_resource_id, '1', '1', '1', '1', '1', '0', GETDATE())
	
		IF @@ERROR <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			SET @return_msg = 'Error - Failure on resource creation.'
			SELECT @return_msg AS Comments
			RETURN
		END 

		--create the setup record.
		INSERT INTO Setups (resource_id, icon_path, date_created)
			VALUES (@new_resource_id, @icon_path, GETDATE())

		IF @@ERROR <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			SET @return_msg = 'Error - Failure on setup creation.'
			SELECT @return_msg AS Comments
			RETURN
		END 
		ELSE
		BEGIN

			COMMIT TRANSACTION
			SET @return_msg = 'Setup Successfully Created.'
			SELECT @return_msg AS Comments
			RETURN		
		END

END



GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

/****** Object:  Stored Procedure dbo.rpm_AddSetupTerminal    Script Date: 1/11/2007 4:18:47 PM ******/


/****** Object:  Stored Procedure dbo.rpm_AddSetupTerminal    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE   PROCEDURE rpm_AddSetupTerminal
	@setup_id int, --required, references the setup that this terminal belongs to
	@name varchar(100), --required, the name of the terminal
	@xPixelLoc int, --required, the x pixel location of this terminal on the setup image.
	@yPixelLoc int, --required, the y pixel location of this terminal on the setup image.
	@max_amplitude float,  --required, the magnitude of maximum voltage amplitude allowed on each terminal
	@max_offset float,  --required, the magnitude of the maximum offset amplitude allowed on each terminal
	@max_current float,  --required, the maximum current allowed on each terminal
	@max_frequency float,  --required, the maximum frequency allowed on each terminal
	@max_sampling_rate float,  --required, the maximum sampling rate allowed on each terminal (default is 0 for input terminals)
	@max_sampling_time float,  --required, the maximum sampling time allowed on each terminal (default is 0 for input terminals)
	@max_points float, --required, the Maximum number of points that can be read from this terminal (default is 0 for input terminals)
	@instrument varchar(5) -- required, the instrument type of this terminal (FGEN, SCOPE, etc.)
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/22/2003
--This method creates a setup terminal configuration for a specified setup.  This terminal captures the general setup configuration information such as the instrument that
--the terminal is connected to, the name of the instrument as well as its order with respect to other instruments for a given setup.  This method checks that the input data is valid and 
--not a duplicate of an existing terminal.  If the information is valid, the record is entered and the terminals-used counter in the appropriate setup is incremented.   
--Otherwise, an error is returned.
BEGIN
	DECLARE @returnMsg varchar(100)

	IF (SELECT 'true' WHERE NOT EXISTS(SELECT setup_id FROM Setups WHERE setup_id = @setup_id)) = 'true' OR @setup_id = '' OR @setup_id = NULL
	BEGIN
		SET @returnMsg = 'Error - The specified setup id is invalid.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	IF (SELECT 'true' WHERE EXISTS(SELECT setupterm_id FROM SetupTerminalConfig WHERE setup_id = @setup_id AND (name = @name OR (x_pixel_loc = @xPixelLoc AND y_pixel_loc = @yPixelLoc) OR instrument = @instrument))) = 'true'
	BEGIN
		SET @returnMsg = 'Error - One or more inputs values duplicate existing terminal.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	IF @instrument <> 'FGEN' AND @instrument <> 'SCOPE' AND @instrument <> 'GND'
	BEGIN
		SET @returnMsg = 'Error - Invalid instrument designation.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	IF @max_amplitude = NULL OR @max_offset = NULL OR @max_current = NULL OR @max_frequency = NULL OR @max_sampling_rate = NULL OR @max_sampling_time = NULL OR @max_points = NULL
	BEGIN
		SET @returnMsg = 'Error - Compliance values must be specified.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	IF @name = '' OR @name = NULL
	BEGIN
		SET @returnMsg = 'Error - A name for this terminal must be supplied.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	IF @xPixelLoc = '' OR @xPixelLoc = NULL OR @yPixelLoc = '' OR @yPixelLoc = NULL
	BEGIN
		SET @returnMsg = 'Error - A pixel coordinate pair must be supplied.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	BEGIN TRAN
		DECLARE @termCount int
		
		SET @termCount = (SELECT COUNT(*) FROM SetupTerminalConfig WHERE setup_id = @setup_id)
	
		INSERT INTO SetupTerminalConfig (setup_id, number, name, x_pixel_loc, y_pixel_loc, max_amplitude, max_offset, max_current, max_frequency, max_sampling_rate, max_sampling_time, max_points, instrument, date_created)
			VALUES (@setup_id, @termCount + 1, @name, @xPixelLoc, @yPixelLoc, @max_amplitude, @max_offset, @max_current, @max_frequency, @max_sampling_rate, @max_sampling_time, @max_points, @instrument, GETDATE())

		UPDATE Setups SET terminals_used = @termCount + 1, date_modified = GETDATE() WHERE setup_id = @setup_id

		IF @@ERROR <>0
		BEGIN
			ROLLBACK TRANSACTION
			SET @returnMsg = 'Error - Insert Failed.'
			SELECT @returnMsg AS Comments
			RETURN
		END
		ELSE
		BEGIN
			COMMIT TRANSACTION
			SET @returnMsg = 'Terminal Successfully Added.'
			SELECT @returnMsg AS Comments
			RETURN
		END


END



GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_AddSiteUser    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_AddSiteUser    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_AddSiteUser
	@first_name varchar(100), --required
	@last_name varchar(100), --required
	@email varchar(150), --required 
	@username varchar(20), --required
	@password varchar(20), --required
	@classID int, --required (0 or valid class id)
	@is_active bit --required (0 or 1)
AS
--Author(s): James Hardison (hardison@alum.mit.edu
--Date: 6/14/2004
--This method adds a Site User record into the SiteUsers table.  Specifically, this method checks that the supplied username is not already in use, makes 
--sure that the required fields are not null and, passing these, inserts the record and returns the new user_id as an indication of success.  If any of these checks fail,
--a message is returned to the caller.  The ID of the class the user will be associated with can be specified here, if @classID is invalid, null or 0, the user will be added 
--to the default Lab Server Guest Class (ID = 2)
BEGIN
	DECLARE @returnVal varchar(100), @ins_error int

	IF @first_name = '' OR @first_name = NULL
	BEGIN
		SET @returnVal = 'Error - A first name must be supplied.'
		SELECT @returnVal AS Result
		RETURN
	END
	ELSE
	IF @last_name = '' OR @last_name = NULL
	BEGIN
		SET @returnVal = 'Error - A last name must be supplied.'
		SELECT @returnVal AS Result
		RETURN
	END
	ELSE
	IF @email = '' OR @email = NULL
	BEGIN
		SET @returnVal = 'Error - An email address must be supplied.'
		SELECT @returnVal AS Result
		RETURN
	END
	ELSE
	IF @username = '' OR @username = NULL
	BEGIN
		SET @returnVal = 'Error - A username must be supplied.'
		SELECT @returnVal AS Result
		RETURN
	END
	ELSE
	IF @password = '' OR @password = NULL
	BEGIN
		SET @returnVal = 'Error - A password must be supplied.'
		SELECT @returnVal AS Result
		RETURN
	END
	ELSE
	IF @is_active = NULL 
	BEGIN
		SET @returnVal = 'Error - An activity status value msut be supplied.'
		SELECT @returnVal AS Result
		RETURN
	END
	ELSE
		


	IF (SELECT 'true' WHERE EXISTS(SELECT username FROM SiteUsers WHERE username = @username)) = 'true'
	BEGIN
		SET @returnVal = 'Error - The supplied username is in use, please select another one.'
		SELECT @returnVal AS Result
		RETURN			
	END
	ELSE
	BEGIN TRAN
		IF (SELECT 'true' WHERE NOT EXISTS(SELECT class_id FROM UsageClasses WHERE class_id = @classID)) = 'true' OR @classID = '' OR @classID = NULL
		BEGIN
			SET @classID= 2
		END

		INSERT INTO SiteUsers (first_name, last_name, email, username, password, class_id, is_active, date_created)
			VALUES (@first_name, @last_name, @email, @username, @password, @classID, @is_active, GETDATE())

		UPDATE UsageClasses SET amt_member_susers = amt_member_susers + 1, date_modified = GETDATE() WHERE class_id = @classID
			
		SET @ins_error = @@ERROR

		IF @ins_error <> 0 
		BEGIN
			ROLLBACK TRAN
			SET @returnVal = 'Error Creating Site User.  Aborting.'
			SELECT @returnVal As Result
			RETURN	
		END
		ELSE
		BEGIN
			COMMIT TRAN
			SELECT user_id AS Result FROM SiteUsers WHERE username = @username
			RETURN
		END
	


END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_CopySetup    Script Date: 1/11/2007 4:18:47 PM ******/



/****** Object:  Stored Procedure dbo.rpm_CopySetup    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE   PROCEDURE rpm_CopySetup 
	@setup_id int, --required, references the setup to be copied. 
	@name varchar(250) --required, a unique name for the new setup/resource
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/28/2003
--This method creates a new instance of the specified setup under the specified name.  The setup id must reference a valid ID and the name must be non-null and unique
--across all setups/resources.  The new setup will have the same terminal configurations as the original.  Permissions will only be given to the default administrators group
--upon creation.  If the procedure fails, an error message is generated.  Otherwise, an  indication of success is passed to the caller.
BEGIN
	DECLARE @returnMsg varchar(100)
	IF (SELECT 'true' WHERE EXISTS(SELECT resource_id FROM Resources WHERE name = @name)) = 'true' OR @name = '' OR @name = NULL
	BEGIN
		SET @returnMsg = 'Error - A unique resource name must be specified.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	IF (SELECT 'true' WHERE NOT EXISTS(SELECT setup_id FROM Setups WHERE setup_id = @setup_id)) = 'true' OR @setup_id = '' OR @setup_id = NULL
	BEGIN
		SET @returnMsg = 'Error - A valid setup id must be specified.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	BEGIN TRAN
		DECLARE @oldResourceID int, @newResourceID int, @newSetupID int, @currTerminalID int

		--creates new resource record and mapping to default admin class
		SET @oldResourceID = (SELECT resource_id FROM Setups WHERE setup_id = @setup_id)
		
		INSERT INTO Resources (name, type, category, description, date_created)
			SELECT @name AS name, type, category, description, GETDATE() AS date_created 
				FROM Resources
				WHERE resource_id = @oldResourceID

		SET @newResourceID = (SELECT resource_id FROM Resources WHERE type = 'SETUP' AND name = @name)

		INSERT INTO ClassToResourceMapping (resource_id, class_id, can_view, can_edit, can_grant, can_delete, priority, date_created)
			VALUES (@newResourceID, '1', '1', '1', '1', '1', '0', GETDATE())

		IF @@ERROR <> 0
		BEGIN
			ROLLBACK TRANSACTION 
			SET @returnMsg = 'Error - Failure on resource creation.'
			SELECT @returnMsg AS Comments
			RETURN
		END
	
		--create new setup record
		INSERT INTO Setups (resource_id, icon_path, terminals_used, date_created)
			SELECT @newResourceID AS resource_id, icon_path, terminals_used, GETDATE() AS date_created 
				FROM Setups 	
				WHERE setup_id = @setup_id

		SET @newSetupID = (SELECT setup_id FROM Setups WHERE resource_id = @newResourceID)

		IF @@ERROR <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			SET @returnMsg = 'Error - Failure on setup creation.'
			SELECT @returnMsg AS Comments
			RETURN
		END
		
		--creates terminal configurations for the new setup
		DECLARE terminals CURSOR FOR
			SELECT setupterm_id FROM SetupTerminalConfig WHERE setup_id = @setup_id

		OPEN terminals
		FETCH NEXT FROM terminals INTO @currTerminalID

		WHILE @@FETCH_STATUS = 0
		BEGIN
			INSERT INTO SetupTerminalConfig (setup_id, number, name, x_pixel_loc, y_pixel_loc, instrument, max_amplitude, max_offset, max_current, max_frequency, max_sampling_rate, max_sampling_time, max_points, date_created)
				SELECT @newSetupID AS setup_id, number, name, x_pixel_loc, y_pixel_loc, instrument, max_amplitude, max_offset, max_current, max_frequency, max_sampling_rate, max_sampling_time, max_points, GETDATE()
					FROM SetupTerminalConfig
					WHERE setupterm_id = @currTerminalID
	
			FETCH NEXT FROM terminals INTO @currTerminalID
		END
		CLOSE terminals
		DEALLOCATE terminals

		IF @@ERROR <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			SET @returnMsg = 'Error - Failure on terminal configuration.'
			SELECT @returnMsg AS Comments
			RETURN
		END
		ELSE 
		BEGIN
			COMMIT TRANSACTION
			SET @returnMsg = 'Setup Successfully Copied.'
			SELECT @returnMsg AS Comments
			RETURN
		END

END



GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_DeactivateBroker    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_DeactivateBroker    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_DeactivateBroker 
	@brokerID int
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/15/2003
--This method sets the 'is_active' field in the specified broker and that in each of the groups owned by that broker to 0.  If successful, the method returns the string 
--'SUCCESS'.  If the procedure fails (if the specified broker is invalid) then the string 'ERROR' is returned and no change is made.
BEGIN
	IF (SELECT 'true' WHERE NOT EXISTS(SELECT broker_id from Brokers WHERE broker_id = @brokerID)) = 'true'
	BEGIN	
		SELECT 'ERROR' AS Result
		RETURN
	END
	ELSE
	BEGIN
		UPDATE Brokers SET is_active = '0', date_modified = GETDATE() WHERE broker_id = @brokerID

		UPDATE Groups SET is_active = '0', date_modified = GETDATE() WHERE owner_id = @brokerID
		
		SELECT 'SUCCESS' as Result
		RETURN
	END
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_DeactivateGroup    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_DeactivateGroup    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_DeactivateGroup
	@groupID int
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/16/2003
--This method sets the 'is_active' field in the specified group to 0.  If successful, the method returns the string 'SUCCESS'.  If the procedure fails (if the specified group is 
--invalid) then the string 'ERROR' is returned and no change is made.
BEGIN
	IF (SELECT 'true' WHERE NOT EXISTS(SELECT group_id from Groups WHERE group_id = @groupID)) = 'true'
	BEGIN	
		SELECT 'ERROR' AS Result
		RETURN
	END
	ELSE
	BEGIN
		UPDATE Groups SET is_active = '0', date_modified = GETDATE() WHERE group_id = @groupID
		
		SELECT 'SUCCESS' as Result
		RETURN
	END
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_DeactivateSiteUser    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_DeactivateSiteUser    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_DeactivateSiteUser
	@userID int
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 6/14/2004
--This method sets the 'is_active' field in the specified site user to 0.  If successful, the method returns the string 
--'SUCCESS'.  If the procedure fails (if the specified user is invalid) then the string 'ERROR' is returned and no change is made.
BEGIN
	IF (SELECT 'true' WHERE NOT EXISTS(SELECT user_id from SiteUsers WHERE user_id = @userID)) = 'true'
	BEGIN	
		SELECT 'ERROR' AS Result
		RETURN
	END
	ELSE
	BEGIN
		UPDATE SiteUSers SET is_active = '0', date_modified = GETDATE() WHERE user_id = @userID
		
		SELECT 'SUCCESS' as Result
		RETURN
	END
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_EditResourceMapping    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_EditResourceMapping    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_EditResourceMapping
	@mappingID int, --required, a reference to an existing mapping
	@can_view bit, 	--required, 0 = false, 1 = true, pre-requisite access: none
	@can_edit bit, --required, 0 = false, 1= true, pre-requisite access: can_view = 1
	@can_grant bit, --required, 0 = fales, 1 = true, pre-requisite access: can_view = 1
	@can_delete bit, --required, 0 = false, 1 = true, pre-requisite access: can_edit = 1, can_view = 1
	@priority int --optional, integer value between +20/-20 only used for setups.
 AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/20/2003
--This method updates a preexisting record in the ClassToResourceMapping table.  Specifically, this method checks that the input data is valid and  that the referenced 
--mapping exists .  If any of these tests fails, an error message is returned to teh caller.  Otherwise, the record is updated with the specified parameters.
BEGIN
	DECLARE @returnMsg varchar(100), @ins_error int, @resource_id int

	IF (SELECT 'true' WHERE NOT EXISTS(SELECT mapping_id FROM ClassToResourceMapping WHERE mapping_id = @mappingID)) = 'true' OR @mappingID = '' OR @mappingID = NULL
	BEGIN
		SET @returnMsg = 'Error - The specified mapping is invalid.'
		SELECT @returnMsg AS Comments 
		RETURN
	END
	ELSE
	IF (SELECT class_id FROM ClassToResourceMapping WHERE mapping_id = @mappingID) = '1' AND (@can_view = '0' OR @can_edit = '0' OR @can_grant = '0' OR @can_delete = '0')
	BEGIN
		SET @returnMsg = 'Error - Permissions may not be removed from the Administrator Class.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	IF @can_delete = '1' AND ( @can_view = '0' OR @can_edit = '0')
	BEGIN	
		SET @returnMsg = 'Error - permission violation, delete requires view and edit.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	IF @can_edit = '1' AND @can_view = '0'
	BEGIN
		SET @returnMsg = 'Error - permission violation, edit requires view.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	IF @can_grant = '1' AND @can_view = '0'
	BEGIN
		SET @returnMsg = 'Error - permission violation, grant requires view.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	BEGIN TRAN

		IF @priority = NULL OR @priority = '' OR @priority < -20 OR @priority > 20 
		BEGIN
			SET @priority = 0
		END
		
		UPDATE ClassToResourceMapping 
			SET can_view = @can_view, can_edit = @can_edit, can_grant = @can_grant, can_delete = @can_delete, priority = @priority, date_modified = GETDATE()
			WHERE mapping_id = @mappingID

		SET @resource_id = (SELECT resource_id FROM ClassToResourceMapping WHERE mapping_id = @mappingID)

		UPDATE Resources SET date_modified = GETDATE() WHERE resource_id = @resource_id

		SET @ins_error = @@ERROR

		IF @ins_error <> 0
		BEGIN
			ROLLBACK TRAN
			SET @returnMsg = 'Error during update.'
		END
		ELSE
		BEGIN
			COMMIT TRAN
			SET @returnMsg = 'Mapping successfully updated.'
		END
		
		SELECT @returnMsg AS Comments 
		RETURN

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_MapBrokerToClass    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_MapBrokerToClass    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_MapBrokerToClass 
	@brokerID int, --required, refers to an existing service broker record
	@classID int --required, refers to an existing usage class record
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/20/2003
--This mapping associates a service broker with a usage class on the lab server.  This is done by first reading the current class membership from the specified broker record
--and decrementing the appropriate class membership counter.  The broker is then 'added' to the specified class by writing the new class pointer into the broker record and
--incrementing the new class' membership counter.  Invalid inputs will generate an error message.
BEGIN
	DECLARE @returnMsg varchar(100), @upd_error int, @oldClassID int

	IF (SELECT 'true' WHERE NOT EXISTS(SELECT broker_id FROM Brokers WHERE broker_id = @brokerID)) = 'true' OR @brokerID = '' OR @brokerID = NULL
	BEGIN
		SET @returnMsg = 'Error - A valid broker id must be provided.'
		SELECT @returnMsg As Comments
		RETURN
	END
	ELSE
	IF (SELECT 'true' WHERE NOT EXISTS(SELECT class_id FROM UsageClasses WHERE class_id = @classID)) = 'true' OR @classID = '' OR @classID = NULL
	BEGIN
		SET @returnMsg = 'Error - A valid usage class id must be provided;'
		SELECT @returnMsg As Comments
		RETURN
	END
	ELSE
	BEGIN TRAN
		SET @oldClassID = (SELECT class_id FROM Brokers WHERE broker_id = @brokerID)

		UPDATE UsageClasses SET amt_member_brokers = amt_member_brokers - 1, date_modified = GETDATE() WHERE class_id = @oldClassID

		UPDATE Brokers SET class_id = @classID, date_modified = GETDATE() WHERE broker_id = @brokerID

		UPDATE UsageClasses SET amt_member_brokers = amt_member_brokers + 1, date_modified = GETDATE() WHERE class_id = @classID

		SET @upd_error = @@ERROR

		IF @upd_error <> 0 
		BEGIN
			ROLLBACK TRAN
			SET @returnMsg = 'Error during update.'
		END
		ELSE
		BEGIN
			COMMIT TRAN
			SET @returnMsg = 'Mapping successfully updated.'
		END

		SELECT @returnMsg AS Comments	
		RETURN

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_MapClasstoResource    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_MapClasstoResource    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_MapClasstoResource
	@resource_id int, --required, reference to pre-existing record in Resources
	@class_id int, --required, reference to pre-existing record in UsageClasses
	@can_view bit, --required, 0 = false, 1 = true, pre-requisite access: none
	@can_edit bit, --required, 0 = false, 1= true, pre-requisite access: can_view = 1
	@can_grant bit, --required, 0 = fales, 1 = true, pre-requisite access: can_view = 1
	@can_delete bit, --required, 0 = false, 1 = true, pre-requisite access: can_edit = 1, can_view = 1
	@priority int --optional, integer value between +20/-20 only used for setups.
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 3/28/2003
--This method adds a record to the ClassToResourceMapping table, thus creating a permission mapping between a specified class, resource pair.  Specifically, 
--this method first checks that the input data are valid (see above parameter descriptions), that the referenced resource and usage class exist and that there
--isn't already a mapping between the specified class and resource..  Failing these tests, an error message is returned to the caller.  Otherwise, the record is 
--added and the caller is informed of completion.
BEGIN
	DECLARE @caller_out varchar(100), @ins_error int

	IF (SELECT 'true' WHERE NOT EXISTS(SELECT resource_id FROM Resources WHERE resource_id = @resource_id)) = 'true'
	BEGIN
		SET @caller_out = 'Error - the specified resource is invalid.'
		SELECT @caller_out AS Comments 
		RETURN
	END
	ELSE
	IF (SELECT 'true' WHERE NOT EXISTS(SELECT class_id FROM UsageClasses WHERE class_id = @class_id)) = 'true'
	BEGIN
		SET @caller_out = 'Error - the specified class is invalid.'
		SELECT @caller_out AS Comments
		RETURN
	END	
	ELSE
	IF (SELECT 'true' WHERE EXISTS(SELECT mapping_id FROM ClassToResourceMapping WHERE resource_id = @resource_id AND class_id = @class_id)) = 'true'
	BEGIN
		SET @caller_out = 'Error - Mapping already exists, please edit current mapping or map different objects.'
		SELECT @caller_out AS Comments
		RETURN
	END
	ELSE
	IF @can_delete = '1' AND ( @can_view = '0' OR @can_edit = '0')
	BEGIN	
		SET @caller_out = 'Error - permission violation, delete requires view and edit.'
		SELECT @caller_out AS Comments
		RETURN
	END
	ELSE
	IF @can_edit = '1' AND @can_view = '0'
	BEGIN
		SET @caller_out = 'Error - permission violation, edit requires view.'
		SELECT @caller_out AS Comments
		RETURN
	END
	ELSE
	IF @can_grant = '1' AND @can_view = '0'
	BEGIN
		SET @caller_out = 'Error - permission violation, grant requires view.'
		SELECT @caller_out AS Comments
		RETURN
	END
	ELSE
	BEGIN TRAN
		INSERT INTO ClassToResourceMapping (resource_id, class_id, can_view, can_edit, can_grant, can_delete, priority, date_created)
			VALUES (@resource_id, @class_id, @can_view, @can_edit, @can_grant, @can_delete, @priority, getdate())

		UPDATE Resources SET date_modified = GETDATE() WHERE resource_id = @resource_id

		SET @ins_error = @@ERROR

		IF @ins_error <> 0
		BEGIN
			ROLLBACK TRAN
			SET @caller_out = 'Error during assignment.'
		END
		ELSE
		BEGIN
			COMMIT TRAN
			SET @caller_out = 'Mapping successfully added.'
		END
		
		SELECT @caller_out AS Comments 
		RETURN
	--END

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_MapGrouptoClass    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_MapGrouptoClass    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_MapGrouptoClass
	@groupID int, --required, refers to an existing Lab Registered Group record
	@classID int --required, refers to an existing Usage Class record.
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/20/2003
--This mapping associates a group with a usage class on the lab server.  This is done by first reading the current class membership from the specified group record
--and decrementing the appropriate class membership counter.  The group is then 'added' to the specified class by writing the new class pointer into the group record and
--incrementing the new class' membership counter.  Invalid inputs will generate an error message.
BEGIN
	DECLARE @returnMsg varchar(100), @upd_error int, @oldClassID int

	IF (SELECT 'true' WHERE NOT EXISTS(SELECT group_id FROM Groups WHERE group_id = @groupID)) = 'true' OR @groupID = '' OR @groupID = NULL
	BEGIN
		SET @returnMsg = 'Error - A valid group id must be provided.'
		SELECT @returnMsg As Comments
		RETURN
	END
	ELSE
	IF (SELECT 'true' WHERE NOT EXISTS(SELECT class_id FROM UsageClasses WHERE class_id = @classID)) = 'true' OR @classID = '' OR @classID = NULL
	BEGIN
		SET @returnMsg = 'Error - A valid usage class id must be provided;'
		SELECT @returnMsg As Comments
		RETURN
	END
	ELSE
	BEGIN TRAN
		SET @oldClassID = (SELECT class_id FROM Groups WHERE group_id = @groupID)

		UPDATE UsageClasses SET amt_member_groups = amt_member_groups - 1, date_modified = GETDATE() WHERE class_id = @oldClassID

		UPDATE Groups SET class_id = @classID, date_modified = GETDATE() WHERE group_id = @groupID

		UPDATE UsageClasses SET amt_member_groups = amt_member_groups + 1, date_modified = GETDATE() WHERE class_id = @classID

		SET @upd_error = @@ERROR

		IF @upd_error <> 0 
		BEGIN
			ROLLBACK TRAN
			SET @returnMsg = 'Error during update.'
		END
		ELSE
		BEGIN
			COMMIT TRAN
			SET @returnMsg = 'Mapping successfully updated.'
		END

		SELECT @returnMsg AS Comments	
		RETURN

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_MapSiteUserToClass    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_MapSiteUserToClass    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_MapSiteUserToClass 
	@userID int, --required, refers to an existing site user record
	@classID int --required, refers to an existing usage class record
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 6/14/2004
--This mapping associates a site user with a usage class on the lab server.  This is done by first reading the current class membership from the specified user record
--and decrementing the appropriate class membership counter.  The user is then 'added' to the specified class by writing the new class pointer into the user record and
--incrementing the new class' membership counter.  Invalid inputs will generate an error message.
BEGIN
	DECLARE @returnMsg varchar(100), @upd_error int, @oldClassID int

	IF (SELECT 'true' WHERE NOT EXISTS(SELECT user_id FROM SiteUsers WHERE user_id = @userID)) = 'true' OR @userID = '' OR @userID = NULL
	BEGIN
		SET @returnMsg = 'Error - A valid user id must be provided.'
		SELECT @returnMsg As Comments
		RETURN
	END
	ELSE
	IF (SELECT 'true' WHERE NOT EXISTS(SELECT class_id FROM UsageClasses WHERE class_id = @classID)) = 'true' OR @classID = '' OR @classID = NULL
	BEGIN
		SET @returnMsg = 'Error - A valid usage class id must be provided;'
		SELECT @returnMsg As Comments
		RETURN
	END
	ELSE
	BEGIN TRAN
		SET @oldClassID = (SELECT class_id FROM SiteUsers WHERE user_id = @userID)

		UPDATE UsageClasses SET amt_member_susers = amt_member_susers - 1, date_modified = GETDATE() WHERE class_id = @oldClassID

		UPDATE SiteUsers SET class_id = @classID, date_modified = GETDATE() WHERE user_id = @userID

		UPDATE UsageClasses SET amt_member_susers = amt_member_susers + 1, date_modified = GETDATE() WHERE class_id = @classID

		SET @upd_error = @@ERROR

		IF @upd_error <> 0 
		BEGIN
			ROLLBACK TRAN
			SET @returnMsg = 'Error during update.'
		END
		ELSE
		BEGIN
			COMMIT TRAN
			SET @returnMsg = 'Mapping successfully updated.'
		END

		SELECT @returnMsg AS Comments	
		RETURN

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_RemoveBroker    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_RemoveBroker    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_RemoveBroker
	@brokerID int
 AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/15/2003
--This method removes a service broker from the Lab Server database.  Specifically, the caller specifies the ID of the broker to be removed.  The corresponding record in
--Brokers is removed, as well as any groups that are orphaned by the procedure.  The approproate class membership counters are decremented.  If any part of the above 
--process fails, an error message is generated.  Otherwise, an indication of success is passed to the caller.  
BEGIN
	DECLARE @returnMsg varchar(100)

	IF (SELECT 'true' WHERE NOT EXISTS(SELECT broker_id FROM Brokers WHERE broker_id = @brokerID)) = 'true' OR @brokerID = '' OR @brokerID = NULL
	BEGIN
		SET @returnMsg = 'Error - The specified broker id is invalid.'
		SELECT @returnMsg AS Comment
		RETURN
	END
	ELSE
	BEGIN TRAN
		DECLARE @currGroupID int, @currClassID int, @group_error int, @broker_error int, @brokerClassID int

		SET @brokerClassID = (SELECT class_id FROM Brokers WHERE broker_id = @brokerID)

		DECLARE orphanGroups CURSOR FOR
			SELECT group_id, class_id FROM Groups WHERE owner_id = @brokerID
		
		OPEN  orphanGroups
		FETCH NEXT FROM orphanGroups INTO @currGroupID, @currClassID
			
		SET @group_error = 0
		WHILE @@FETCH_STATUS = 0
		BEGIN
			DELETE FROM Groups WHERE group_id = @currGroupID

			UPDATE UsageClasses SET amt_member_groups = amt_member_groups - 1, date_modified = GETDATE() WHERE class_id = @currClassID
			SET @group_error = @@ERROR

			FETCH NEXT FROM orphanGroups INTO @currGroupID, @currClassID			
			
		END
	
		CLOSE orphanGroups
		DEALLOCATE orphanGroups

		DELETE FROM Brokers WHERE broker_id = @brokerID

		UPDATE UsageClasses SET amt_member_brokers = amt_member_brokers - 1 WHERE class_id = @brokerClassID

		SET @broker_error = @@ERROR

		IF @group_error <> 0 --OR @broker_error <> 0
		BEGIN
			ROLLBACK TRAN
			SET @returnMsg = 'Error during group delete.'
		END
		ELSE
		IF @broker_error <> 0
		BEGIN
			ROLLBACK TRAN
			SET @returnMsg = 'Error during broker delete.'
		END
		ELSE
		BEGIN
			COMMIT TRAN
			SET @returnMsg = 'Broker successfully deleted.'
		END

		SELECT @returnMsg AS Comments	
		RETURN
		

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_RemoveClass    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_RemoveClass    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_RemoveClass
	@classID int, --required, class to be deleted
	@newClassID int --optional, class to assign orphaned groups/brokers to, if input is invalid, '2' is used
 AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date Created: 5/20/2003
--Last Updated: 6/14/2004
--This method removes a Usage Class from the Lab Server Database.  Specifically, the caller specifies the ID of the class to be removed.  If the id is valid and may be removed
--(classIDs 1 and 2 are the default admin and guest groups and may not be deleted) it will be removed, along with any orphaned resource to class mappings.  Orphaned 
--groups and brokers will be added either to a specified new class or, if none is specified,  the default guest class and the appropriate membership counters will be adjusted.  If any part of the above process failes, an error 
--message is generated.  Otherwise, an indication of success is passed to the caller.
BEGIN
	DECLARE @returnMsg varchar(100)

	IF (SELECT 'true' WHERE NOT EXISTS(SELECT class_id FROM UsageClasses WHERE class_id = @classID)) = 'true' OR @classID = '' OR @classID = NULL
	BEGIN
		SET @returnMsg = 'Error - The specified class id is invalid.'
		SELECT @returnMsg As Comment
		RETURN
	END
	ELSE 
	IF @classID = '1' OR @classID = '2'
	BEGIN
		SET @returnMsg = 'Error - The specified class may not be deleted.'
		SELECT @returnMsg As Comment
		RETURN
	END
	ELSE
	BEGIN TRAN
		DECLARE @groupCnt int, @brokerCnt int, @suserCnt int, @upd_error int, @del_error int

		IF (SELECT 'true' WHERE NOT EXISTS(SELECT class_id FROM UsageClasses WHERE class_id = @newClassID)) = 'true' OR @newClassID = '' OR @newClassID = NULL
		BEGIN
			SET @newClassID = '2'  --default Guest class
		END

		--reassign orphaned groups and brokers to new class
		SET @groupCnt = (SELECT COUNT(*) FROM Groups WHERE class_id = @classID)
		SET @brokerCnt = (SELECT COUNT(*) FROM Brokers WHERE class_id = @classID)
		SET @suserCnt = (SELECT COUNT(*) FROM SiteUsers WHERE class_id = @classID)
		
		UPDATE Groups SET class_id = @newClassID, date_modified = GETDATE() WHERE class_id = @classID
		SET @upd_error = @@ERROR
	
		UPDATE Brokers SET class_id = @newClassID, date_modified = GETDATE() WHERE class_id = @classID
		SET @upd_error = @@ERROR

		UPDATE SiteUsers SET class_id = @newClassID, date_modified = GETDATE() WHERE  class_id = @classID
	
		UPDATE UsageClasses 
			SET amt_member_groups = amt_member_groups + @groupCnt, amt_member_brokers = amt_member_brokers + @brokerCnt, amt_member_susers = amt_member_susers + @suserCnt,  date_modified = GETDATE()
			 WHERE class_id = @newClassID
		SET @upd_error = @@ERROR
	
		--removes orphaned class/resource mappings
		DELETE FROM ClassToResourceMapping WHERE class_id = @classID
		SET @del_error = @@ERROR
	
		--removes the class
		DELETE FROM UsageClasses WHERE class_id = @classID
		SET @del_error = @@ERROR

		IF @del_error <> 0 OR @upd_error <> 0 
		BEGIN
			ROLLBACK TRAN
			SET @returnMsg = 'Error during class delete.'
			SELECT @returnMsg AS Comment
			RETURN
		END
		ELSE
		BEGIN
			COMMIT TRAN
			SET @returnMsg = 'Class successfully deleted.'
			SELECT @returnMsg AS Comment
			RETURN	
		END
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_RemoveGroup    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_RemoveGroup    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_RemoveGroup
	@groupID int
 AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/19/2003
--This method removes a group from the Lab Server Database.  Specifically, the caller specifies the ID of the group to be removed.  The corresponding record in Groups is 
--removed.  The appropriate membership counter in UsageClasses is decrements.  If any part of the above process fails, an error message is generated.  Otherwise, an 
--indication of success is passed to the caller.
BEGIN
	DECLARE @returnMsg varchar(100)

	IF (SELECT 'true' WHERE NOT EXISTS(SELECT group_id FROM Groups WHERE group_id = @groupID)) = 'true' OR @groupID = '' OR @groupID = NULL
	BEGIN
		SET @returnMsg = 'Error - The specified group id is invalid.'
		SELECT @returnMsg As Comment
		RETURN
	END
	ELSE
	BEGIN TRAN
		DECLARE @groupClassID int, @del_error int
		
		SET @groupClassID = (SELECT class_id FROM Groups WHERE group_id = @groupID)
		
		DELETE FROM Groups WHERE group_id = @groupID

		UPDATE UsageClasses SET amt_member_groups = amt_member_groups - 1, date_modified = GETDATE() WHERE class_id = @groupClassID

		SET @del_error = @@ERROR

		IF @del_error <> 0
		BEGIN
			ROLLBACK TRAN
			SET @returnMsg = 'Error during group delete.'
		END
		ELSE
		BEGIN
			COMMIT TRAN
			SET @returnMsg = 'Group successfully deleted.'
		END

		SELECT @returnMsg AS Comments	
		RETURN
		


END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_RemoveResource    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_RemoveResource    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_RemoveResource
	@resourceID int --required, references the resource record to be removed
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/29/2003
--This method removes a resource from the WebLab system.  Specifically, it removes the referenced resource record along with any associated permission mappings.  
--Additionally, if the resource is of type SETUP, the associated setup record and terminal configuration records are also removed.  If the input des not reference a 
--valid resource, an error is returned.
BEGIN
	DECLARE @returnMsg varchar(100)

	IF (SELECT 'true' WHERE NOT EXISTS(SELECT resource_id FROM Resources WHERE resource_id = @resourceID)) = 'true' OR @resourceID = '' OR @resourceID = NULL
	BEGIN
		SET @returnMsg = 'Error - The specified resource id is invalid.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	BEGIN TRAN
		
		--tests if the specified resource is a setup, if so, removes the setup
		IF (SELECT type FROM Resources WHERE resource_id = @resourceID) = 'SETUP'
		BEGIN
			DECLARE @setupID int

			SET @setupID = (SELECT setup_id FROM Setups WHERE resource_id = @resourceID)

			--removes references to setup in ActiveSetups
			UPDATE ActiveSetups SET setup_id = NULL WHERE setup_id = @setupID
			
			--removes setup terminal configurations
			DELETE FROM SetupTerminalConfig WHERE setup_id = @setupID

			--removes setup record
			DELETE FROM Setups WHERE setup_id = @setupID

			IF @@ERROR <> 0 
			BEGIN
				ROLLBACK TRANSACTION
				SET @returnMsg = 'Error - Failure on setup removal.'
				SELECT @returnMsg AS Comments
				RETURN
			END
		END
		
		--removes resource/class mappings
		DELETE FROM ClassToResourceMapping WHERE resource_id = @resourceID

		IF @@ERROR <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			SET @returnMsg = 'Error - Failure on permission removal.'
			SELECT @returnMsg AS Comments
			RETURN
		END

		--removes the resource record
		DELETE FROM Resources WHERE resource_id = @resourceID

		IF @@ERROR <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			SET @returnMsg = 'Error - Failure on resource removal.'
		END
		ELSE
		BEGIN
			COMMIT TRANSACTION
			SET @returnMsg = 'Resource Successfully Removed.'
		END

		SELECT @returnMsg AS Comments
		RETURN
		
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_RemoveResourceMapping    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_RemoveResourceMapping    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_RemoveResourceMapping
	@mappingID int
 AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/20/2003
--This method removes the specified mapping record from the ClassToResourceMapping table.  If the specified mapping ID is invalid or points to the default administrator 
--class, an error will be returned.  Otherwise, the specified mapping will be removed from the system.
BEGIN
	DECLARE @returnMsg varchar(100), @ins_error int, @resource_id int
	
	IF (SELECT 'true' WHERE NOT EXISTS(SELECT mapping_id FROM ClassToResourceMapping WHERE mapping_id = @mappingID)) = 'true' OR @mappingID = '' OR @mappingID = NULL
	BEGIN
		SET @returnMsg = 'Error - The specified mapping id is invalid.'
		SELECT @returnMsg AS Comment
		RETURN	
	END
	ELSE
	IF (SELECT class_id FROM ClassToResourceMapping WHERE mapping_id = @mappingID) = '1'
	BEGIN
		SET @returnMsg = 'Error - Mappings to the Administrator class may not be deleted.'
		SELECT @returnMsg AS Comment
		RETURN
	END
	ELSE
	BEGIN TRAN
		DELETE FROM ClassToResourceMapping WHERE mapping_id = @mappingID

		SET @resource_id = (SELECT resource_id FROM ClassToResourceMapping WHERE mapping_id = @mappingID)

		UPDATE Resources SET date_modified = GETDATE() WHERE resource_id = @resource_id

		SET @ins_error = @@ERROR

		IF @ins_error <> 0
		BEGIN
			ROLLBACK TRAN
			SET @returnMsg = 'Error during delete.'
		END
		ELSE
		BEGIN
			COMMIT TRAN
			SET @returnMsg = 'Mapping successfully deleted.'
		END
		
		SELECT @returnMsg AS Comments 
		RETURN


END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_RemoveSetup    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_RemoveSetup    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_RemoveSetup
	@setupID int --required, the setup to be deleted
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/29/2003
--This method removes a setup from the WebLab system.  Specifically, this method removes the setup record, associated setup terminal configurations, associated 
--resources and permission mappings.  Any references to this setup in ActiveSetups are also set to NULL (no setup).This requires that the input value is a reference to a 
--valid setup.  Invalid input will result in an error being returned.
BEGIN
	DECLARE @returnMsg varchar(100)

	IF (SELECT 'true' WHERE NOT EXISTS(SELECT setup_id FROM Setups WHERE setup_id = @setupID)) = 'true' OR @setupID = '' OR @setupID = NULL
	BEGIN
		SET @returnMsg = 'Error - The specified setup id is invalid.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	BEGIN TRAN
		DECLARE @resourceID int

		--remove any references to the specified setup in ActiveSetups
		UPDATE ActiveSetups SET setup_id = NULL, is_active = 0 WHERE setup_id = @setupID

		IF @@ERROR <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			SET @returnMsg = 'Error - Failure on setup deactivation.'
			SELECT @returnMsg AS Comments
			RETURN
		END	

		--remove terminal configurations associated with the specified setup
		DELETE FROM SetupTerminalConfig 
			WHERE setup_id = @setupID

		IF @@ERROR <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			SET @returnMsg = 'Error - Failure on terminal removal.'
			SELECT @returnMsg AS Comments
			RETURN
		END	

		--finds the associated resource ID, removes class - resource mappings
		SET @resourceID = (SELECT resource_id FROM Setups WHERE setup_id = @setupID)
		
		DELETE FROM ClassToResourceMapping 
			WHERE resource_id = @resourceID

		IF @@ERROR <> 0
		BEGIN
			ROLLBACK TRANSACTION
			SET @returnMsg = 'Error - Failure on permission removal.'
			SELECT @returnMsg AS Comments
			RETURN
		END

		--removes the specififed setup record
		DELETE FROM Setups 
			WHERE setup_id = @setupID

		IF @@ERROR <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			SET @returnMsg = 'Error - Failure on setup removal.'
			SELECT @returnMsg AS Comments
			RETURN
		END

		--removes the associated resource record
		DELETE FROM Resources
			WHERE resource_id = @resourceID

		IF @@ERROR <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			SET @returnMsg = 'Error - Failure on resource removal.'
		END
		ELSE
		BEGIN
			COMMIT TRANSACTION
			SET @returnMsg = 'Setup Successfully Removed.'
		END

		SELECT @returnMsg AS Comments			
		RETURN

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_RemoveSetupTerminal    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_RemoveSetupTerminal    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_RemoveSetupTerminal
	@setupTermID int
 AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/27/2003
--This method removes the specified setup terminal from the database.  If the terminal exists, it is removed, the appropriate terminal counter in Setups is descremented.
--  This method also renumbers the remaining terminals for the affected setup such that they remain sequentially numbered.  If the specified id is invalid, an error message is returned.
BEGIN
	DECLARE @returnMsg varchar(100)

	IF (SELECT 'true' WHERE NOT EXISTS(SELECT setupterm_id FROM SetupTerminalConfig WHERE setupterm_id = @setupTermID)) = 'true' OR @setupTermID = '' OR @setupTermID = NULL
	BEGIN
		SET @returnMsg = 'Error - The specififed terminal id is invalid.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	BEGIN TRAN
		DECLARE @currSetupID int, @termPointer int, @termNumber int

		SET @currSetupID = (SELECT setup_id FROM SetupTerminalConfig WHERE setupterm_id = @setupTermID)
		
		DELETE FROM SetupTerminalConfig WHERE setupterm_id = @setupTermID

		UPDATE Setups SET terminals_used = terminals_used - 1, date_modified = GETDATE() WHERE setup_id = @currSetupID

		DECLARE terminals CURSOR FOR
			SELECT setupterm_id FROM SetupTerminalConfig
				WHERE setup_id = @currSetupID
				ORDER BY number
		OPEN terminals
		SET @termNumber = 1
		FETCH NEXT FROM terminals INTO @termPointer
	
		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE SetupTerminalConfig SET number = @termNumber, date_modified = GETDATE() WHERE setupterm_id = @termPointer
			SET @termNumber = @termNumber + 1
			FETCH NEXT FROM terminals INTO @termPointer		
		END
		CLOSE terminals 
		DEALLOCATE terminals

		IF @@ERROR <> 0 
		BEGIN
			ROLLBACK TRANSACTION
			SET @returnMsg = 'Error - Delete Failed'
		END
		ELSE
		BEGIN
			COMMIT TRANSACTION
			SET @returnMsg = 'Terminal Successfully Deleted.'
		END

		SELECT @returnMsg AS Comments
		RETURN

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_RemoveSiteUser    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_RemoveSiteUser    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_RemoveSiteUser
	@userID int
 AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 6/14/2004
--This method removes a site user from the Lab Server database.  Specifically, the caller specifies the ID of the user to be removed.  The corresponding record in
--SiteUsers is removed.  The approproate class membership counters are decremented.  If any part of the above 
--process fails, an error message is generated.  Otherwise, an indication of success is passed to the caller.  
BEGIN
	DECLARE @returnMsg varchar(100)

	IF (SELECT 'true' WHERE NOT EXISTS(SELECT user_id FROM SiteUsers WHERE user_id = @userID)) = 'true' OR @userID = '' OR @userID = NULL
	BEGIN
		SET @returnMsg = 'Error - The specified user id is invalid.'
		SELECT @returnMsg AS Comment
		RETURN
	END
	ELSE
	BEGIN TRAN
		DECLARE @userClassID int, @tran_error int

		SET @userClassID = (SELECT class_id FROM SiteUsers WHERE user_id = @userID)

		DELETE FROM SiteUsers WHERE user_id = @userID

		UPDATE UsageClasses SET amt_member_susers = amt_member_susers - 1 WHERE class_id = @userClassID

		SET @tran_error = @@ERROR

		IF @tran_error <> 0
		BEGIN
			ROLLBACK TRAN
			SET @returnMsg = 'Error during user delete.  Aborting.'
		END
		ELSE
		BEGIN
			COMMIT TRAN
			SET @returnMsg = 'Site User successfully deleted.'
		END

		SELECT @returnMsg AS Comments	
		RETURN
		

END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

/****** Object:  Stored Procedure dbo.rpm_SetActiveSetup    Script Date: 1/11/2007 4:18:47 PM ******/

/****** Object:  Stored Procedure dbo.rpm_SetActiveSetup    Script Date: 8/31/2004 1:34:34 PM ******/
CREATE PROCEDURE rpm_SetActiveSetup
	@is_active bit, --required, 1 for active, 0 for inactive
	@setupID int --optional, the id of the setup being assigned.  No setup is designated as NULL
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/29/2003
--This method assigns a valid, specified setup to specified active status.  If the setup id is invalid, an error will be generated.
BEGIN
	DECLARE @returnMsg varchar(100)
	
	IF @is_active = NULL
	BEGIN
		SET @returnMsg = 'Error - A valid status value must be specified.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	IF @setupID = '' OR @setupID = NULL
	BEGIN
		SET @returnMsg = 'Error - A valid setup id value must be specified.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	BEGIN
		IF (SELECT 'true' WHERE NOT EXISTS(SELECT setup_id FROM Setups WHERE setup_id = @setupID)) = 'true' 
		BEGIN
			SET @returnMsg = 'Error - The supplied setup id is not valid.'
			SELECT @returnMsg AS Comments
			RETURN
		END
		ELSE

		UPDATE ActiveSetups SET is_active = @is_active WHERE setup_id = @setupID
	END

	SET @returnMsg = 'Setup status successfully set.'
	SELECT @returnMsg AS Comments
	RETURN
	
END

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

CREATE PROCEDURE rpm_SetActiveDevice
	@activeID int, --the id of the position record to set
	@is_active bit, --required, 1 for active, 0 for inactive
	@setupID int --optional, the id of the device profile being assigned.  No device is designated as NULL
AS
--Author(s): James Hardison (hardison@alum.mit.edu)
--Date: 5/29/2003
--This method assigns a valid, specified device profile to the valid, specified device position.  If either input is invalid, an error will be generated.
BEGIN
	DECLARE @returnMsg varchar(100)
	
	IF (SELECT 'true' WHERE NOT EXISTS(SELECT active_id FROM ActiveSetups WHERE active_id = @activeID)) = 'true' OR @activeID = '' OR @activeID = NULL
	BEGIN
		SET @returnMsg = 'Error - A valid device position id must be specified.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE 

	IF @is_active = NULL
	BEGIN
		SET @returnMsg = 'Error - A valid status value must be specified.'
		SELECT @returnMsg AS Comments
		RETURN
	END
	ELSE
	

	IF @setupID = '' OR @setupID = NULL
	BEGIN
		UPDATE ActiveSetups SET setup_id = NULL, is_active = @is_active WHERE active_id = @activeID
	END
	ELSE
	BEGIN
		IF (SELECT 'true' WHERE NOT EXISTS(SELECT setup_id FROM Setups WHERE setup_id = @setupID)) = 'true' 
		BEGIN
			SET @returnMsg = 'Error - The supplied device profile is not valid.'
			SELECT @returnMsg AS Comments
			RETURN
		END
		ELSE

		UPDATE ActiveSetups SET setup_id = @setupID, is_active = @is_active WHERE active_id = @activeID
	END

	SET @returnMsg = 'Device position successfully set.'
	SELECT @returnMsg AS Comments
	RETURN
	
END
GO


SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Create default initial admin user ******/
EXEC rpm_AddSiteUser 'Site', 'Administrator', 'default@admin.org', 'admin', 'mrroot', 1, 1

/****** Create system resources ******/
EXEC rpm_AddResource 'WSInterface', 'FUNCTION', 'Software Component', 'Resource respresenting the Lab Server Web Service Interface Methods.  View access is all that is necessary for a broker to access the interface.' 
EXEC rpm_AddResource 'AcctManagement', 'FUNCTION', 'Software Component', 'Represent administrative code that deals with the management of Service Broker and Site User accounts.'
EXEC rpm_AddResource 'AccessControl', 'FUNCTION', 'Software Component', 'Resource representing software components used to administer access control on the server.  This includes Usage Class and Resource creation as well as permission assignment.'
EXEC rpm_AddResource 'SetupManagement', 'FUNCTION', 'Software Component', 'Resource representing software components used to create/manage system setup models as well as set the setups active on the system.  Experiment setups (being resources) can be edited with permission to this resource.  AccessControl permissions are required to create/delete/grant permissions on setups.'
EXEC rpm_AddResource 'SysRecords', 'FUNCTION', 'Software Component', 'Resource representing software components used to view Lab Server System Usage Records.'
EXEC rpm_AddResource 'SysConfig', 'FUNCTION', 'Software Component', 'Resource representing software components used to edit system configuration settings and to create/edit/delete system notices.'

EXEC rpm_AddSetup 'No Circuit', '', 'SETUP', ''

/****** Create Active Setup Location (set to inactive) ******/
INSERT INTO ActiveSetups (setup_id, is_active) SELECT s.setup_id, '0' FROM Resources r JOIN Setups s ON r.resource_id = s.resource_id WHERE r.name = 'No Circuit' 

/****** Write initial System Configuration state ******/
INSERT INTO LSSystemConfig (Admin_ID, ws_int_is_active, exp_eng_is_active) VALUES(1, 0, 0) 


SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

