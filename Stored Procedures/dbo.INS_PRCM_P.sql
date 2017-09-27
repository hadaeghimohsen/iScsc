SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_PRCM_P](
   @Prsn_Prid BIGINT
  ,@Cmnt NVARCHAR(250)
  ,@Pcid BIGINT OUT
)
AS
BEGIN
   WAITFOR DELAY '00:00:00:50';
   INSERT INTO [dbo].[Present_Comment]
           ([PRSN_PRID]
           ,[CMNT]
           ,[PCID])
     VALUES
           (@Prsn_Prid
           ,@Cmnt
           ,dbo.GNRT_NWID_U());
           
   SELECT @Pcid = MAX(PCID)
     FROM Present_Comment
    WHERE PRSN_PRID = @Prsn_Prid;
END;
GO
