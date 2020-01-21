--Create Long Running Jobs table
USE [cs_helper]
GO

IF OBJECT_ID('dbo.LongRunningJobs') IS NOT NULL
	DROP TABLE dbo.LongRunningJobs

CREATE TABLE [dbo].[LongRunningJobs](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[JobName] [sysname] NOT NULL,
	[JobID] [uniqueidentifier] NOT NULL,
	[StartExecutionDate] [datetime] NULL,
	[AvgDurationMin] [int] NULL,
	[DurationLimit] [int] NULL,
	[CurrentDuration] [int] NULL,
	[RowInsertDate] [datetime] NOT NULL
) ON [PRIMARY]

GO

ALTER TABLE [dbo].[LongRunningJobs] ADD  CONSTRAINT [DF_LongRunningJobs_Date]  DEFAULT (getdate()) FOR [RowInsertDate]
GO


USE [cs_helper]
GO

/****** Object:  StoredProcedure [dbo].[usp_LongRunningJobs]    Script Date: 07/24/2012 14:25:51 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_LongRunningJobs]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_LongRunningJobs]
GO

USE [cs_helper]
GO

/****** Object:  StoredProcedure [dbo].[usp_LongRunningJobs]    Script Date: 07/24/2012 14:25:51 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:        Devin Knight and Jorge Segarra
-- Create date: 7/6/2012
-- Description:    Monitors currently running SQL Agent jobs and 
-- alerts admins if runtime passes set threshold
--			
-- =============================================

/*
Change log:
 =============================================
7/11/2012 (v 1.01)	
		Changed Method for capturing currently running jobs to use master.dbo.xp_sqlagent_enum_jobs 1, ''

7/12/2012 (v 1.03)
		Updated code to deal with “phantom” jobs that weren’t really running. 
		Improved logic to handle this. Beware, uses undocumented stored procedure xp_sqlagent_enum_jobs


7/24/2012 (v. 1.16)
	    Removed need to specify mail profile
		Fix for error sending notify email
		Added commented line for testing purposes (avg+1 minute for short tests)
 =============================================

*/
CREATE PROCEDURE [dbo].[usp_LongRunningJobs]
AS 

--Set limit in minutes (applies to all jobs)
--NOTE: Percentage limit is applied to all jobs where average runtime greater than 5 minutes
--else the time limit is simply average + 10 minutes
    DECLARE @JobLimitPercentage FLOAT

    SET @JobLimitPercentage = 150 --Use whole percentages greater than 100
    
	-- Create intermediate work tables for currently running jobs
    DECLARE @currently_running_jobs TABLE
        (
          job_id UNIQUEIDENTIFIER NOT NULL ,
          last_run_date INT NOT NULL ,
          last_run_time INT NOT NULL ,
          next_run_date INT NOT NULL ,
          next_run_time INT NOT NULL ,
          next_run_schedule_id INT NOT NULL ,
          requested_to_run INT NOT NULL ,-- BOOL
          request_source INT NOT NULL ,
          request_source_id SYSNAME COLLATE database_default
                                    NULL ,
          running INT NOT NULL ,-- BOOL
          current_step INT NOT NULL ,
          current_retry_attempt INT NOT NULL ,
          job_state INT NOT NULL
        ) -- 0 = Not idle or suspended, 1 = Executing, 2 = Waiting For Thread, 3 = Between Retries, 4 = Idle, 5 = Suspended, [6 = WaitingForStepToFinish], 7 = PerformingCompletionActions

--Capture Jobs currently working
    INSERT  INTO @currently_running_jobs
            EXECUTE master.dbo.xp_sqlagent_enum_jobs 1, ''

--Temp table exists check


    CREATE TABLE ##LRJobsStage
        (
          [JobID] [UNIQUEIDENTIFIER] NOT NULL ,
          [JobName] [sysname] NOT NULL ,
          [StartExecutionDate] [DATETIME] NOT NULL ,
          [AvgDurationMin] [INT] NULL ,
          [DurationLimit] [INT] NULL ,
          [CurrentDuration] [INT] NULL
        )

    INSERT  INTO ##LRJobsStage
            ( JobID ,
              JobName ,
              StartExecutionDate ,
              AvgDurationMin ,
              DurationLimit ,
              CurrentDuration
	        )
            SELECT  jobs.Job_ID AS JobID ,
                    jobs.NAME AS JobName ,
                    act.start_execution_date AS StartExecutionDate ,
                    AVG(FLOOR(run_duration / 100)) AS AvgDurationMin ,
                    CASE 
		--If job average less than 5 minutes then limit is avg+10 minutes
                         WHEN AVG(FLOOR(run_duration / 100)) <= 5
                         THEN ( AVG(FLOOR(run_duration / 100)) ) + 10
		--If job average greater than 5 minutes then limit is avg*limit percentage
                         ELSE ( AVG(FLOOR(run_duration / 100))
                                * ( @JobLimitPercentage / 100 ) )
                    END AS DurationLimit ,
                    DATEDIFF(MI, act.start_execution_date, GETDATE()) AS [CurrentDuration]
            FROM    @currently_running_jobs crj
                    INNER JOIN msdb..sysjobs AS jobs ON crj.job_id = jobs.job_id
                    INNER JOIN msdb..sysjobactivity AS act ON act.job_id = crj.job_id
                                                              AND act.stop_execution_date IS NULL
                                                              AND act.start_execution_date IS NOT NULL
                    INNER JOIN msdb..sysjobhistory AS hist ON hist.job_id = crj.job_id
                                                              AND hist.step_id = 0
            WHERE   crj.job_state = 1
            GROUP BY jobs.job_ID ,
                    jobs.NAME ,
                    act.start_execution_date ,
                    DATEDIFF(MI, act.start_execution_date, GETDATE())
            HAVING  CASE WHEN AVG(FLOOR(run_duration / 100)) <= 5
							--  THEN (AVG(FLOOR(run_duration / 100))) + 10
                            THEN ( AVG(FLOOR(run_duration / 100)) ) + 1  --Uncomment/Use for testing purposes only
                         ELSE ( AVG(FLOOR(run_duration / 100))
                                * ( @JobLimitPercentage / 100 ) )
                    END < DATEDIFF(MI, act.start_execution_date, GETDATE())


--Checks to see if a long running job has already been identified so you are not alerted multiple times
    IF EXISTS ( SELECT  RJ.*
                FROM    ##LRJobsStage RJ
                WHERE   CHECKSUM(RJ.JobID, RJ.StartExecutionDate) NOT IN (
                        SELECT  CHECKSUM(JobID, StartExecutionDate)
                        FROM    dbo.LongRunningJobs ) )
     BEGIN
--Send email with results of long-running jobs

	--Set Email Recipients
    DECLARE @MailRecipients VARCHAR(50)

	SET @MailRecipients = 'eisdbalux@clearstream.com'
    -- SET @MailRecipients = 'olivier.theizen@clearstream.com' --Uncomment/Use for testing purposes only

    EXEC msdb.dbo.sp_send_dbmail --@profile_name = @MailProfile
        @recipients = @MailRecipients,
		@reply_to = 'eisdbalux@clearstream.com',
        @query = 'USE cs_helper; Select RJ.*
				From ##LRJobsStage RJ
				WHERE CHECKSUM(RJ.JobID,RJ.StartExecutionDate) 
				NOT IN (Select CHECKSUM(JobID,StartExecutionDate) From dbo.LongRunningJobs) ',
        @body = 'Long running jobs:',
        @subject = 'Long Running SQL Agent Job Alert',
        @attach_query_result_as_file = 0;

--Populate LongRunningJobs table with jobs exceeding established limits
    INSERT  INTO [cs_helper].[dbo].[LongRunningJobs]
            ( [JobID] ,
              [JobName] ,
              [StartExecutionDate] ,
              [AvgDurationMin] ,
              [DurationLimit] ,
              [CurrentDuration]
	        )
            ( SELECT    RJ.*
              FROM      ##LRJobsStage RJ
              WHERE     CHECKSUM(RJ.JobID, RJ.StartExecutionDate) NOT IN (
                        SELECT  CHECKSUM(JobID, StartExecutionDate)
                        FROM    dbo.LongRunningJobs )
            )
	END




GO





