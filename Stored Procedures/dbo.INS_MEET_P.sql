SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_MEET_P](
   @Comm_Cmid BIGINT
  ,@Actn_Date DATETIME
  ,@Meet_Stat VARCHAR(3)
  ,@Strt_Time TIME
  ,@End_Time  TIME
  ,@Meet_Plac NVARCHAR(100)
  ,@Meet_Subj NVARCHAR(250)
  ,@Mtid      BIGINT OUT
)
AS
BEGIN
   WAITFOR DELAY '00:00:00:50';
   INSERT INTO [dbo].[Meeting]
           ([COMM_CMID]
           ,[ACTN_DATE]
           ,[MEET_STAT]
           ,[STRT_TIME]
           ,[END_TIME]
           ,[MEET_PLAC]
           ,[MEET_SUBJ]
           ,[MTID])
     VALUES
           (@Comm_Cmid
           ,@Actn_Date
           ,@Meet_Stat
           ,@Strt_Time
           ,@End_Time
           ,@Meet_Plac
           ,@Meet_Subj
           ,dbo.GNRT_NWID_U());
   SELECT @Mtid = MAX(@Mtid)
     FROM Meeting
    WHERE COMM_CMID = @Comm_Cmid;
END;
GO
