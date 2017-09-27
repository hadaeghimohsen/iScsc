SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_MTCM_P](
   @Meet_Mtid BIGINT
  ,@Cmnt      NVARCHAR(250)
  ,@Rspn_Impl NVARCHAR(100)
  ,@Exp_Date  DATETIME
  ,@Mcid      BIGINT OUT
)
AS
BEGIN
   WAITFOR DELAY '00:00:00:50';
   INSERT INTO [dbo].[Meeting_Comment]
           ([MEET_MTID]
           ,[CMNT]
           ,[RSPN_IMPL]
           ,[EXP_DATE]
           ,[MCID])
     VALUES
           (@Meet_Mtid
           ,@Cmnt
           ,@Rspn_Impl
           ,@Exp_Date
           ,dbo.GNRT_NWID_U());
           
   SELECT @Mcid = MAX(MCID)
     FROM Meeting_Comment
    WHERE MEET_MTID = @Meet_Mtid;           
END;
GO
