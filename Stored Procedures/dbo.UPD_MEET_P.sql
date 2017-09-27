SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[UPD_MEET_P](
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
   UPDATE Meeting
      SET ACTN_DATE = @Actn_Date
         ,MEET_STAT = @Meet_Stat
         ,STRT_TIME = @Strt_Time
         ,END_TIME  = @End_Time
         ,MEET_PLAC = @Meet_Plac
         ,MEET_SUBJ = @Meet_Subj
    WHERE COMM_CMID = @Comm_Cmid
      AND MTID      = @Mtid;
END;
GO
