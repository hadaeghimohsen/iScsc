SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_RCAN_P](
   @Amnt BIGINT,
   @From_User VARCHAR(250),
   @To_User VARCHAR(250),
   @Rcan_Stat VARCHAR(3),
   @Auto_Doc VARCHAR(3),
   @Actn_Date DATETIME,
   @RcanRaid BIGINT,
   @Raid BIGINT OUT
)
As
BEGIN

   INSERT INTO [dbo].[Receipt_Announcement]
           ([RAID]
           ,[AMNT]
           ,[FROM_USER]           
           ,[TO_USER]
           ,[RCAN_STAT]
           ,[AUTO_DOC]
           ,[ACTN_DATE]
           ,[RCAN_RAID])
     VALUES
           (0
           ,@AMNT
           ,CASE @Auto_Doc WHEN '002' THEN @From_User ELSE UPPER(SUSER_NAME()) END
           ,CASE @Auto_Doc WHEN '002' THEN UPPER(SUSER_NAME()) ELSE @To_User END
           ,@RCAN_STAT
           ,@AUTO_DOC
           ,@ACTN_DATE
           ,@RcanRaid);
   
   SELECT @Raid = MAX(RAID)
     FROM Receipt_Announcement
    WHERE TO_USER = CASE @Auto_Doc WHEN '002' THEN UPPER(SUSER_NAME()) ELSE @To_User END
      AND AMNT = @Amnt
      AND RCAN_STAT = @Rcan_Stat
      AND ACTN_DATE = @Actn_Date
      AND AUTO_DOC = @Auto_Doc
      AND FROM_USER = CASE @Auto_Doc WHEN '002' THEN @From_User ELSE UPPER(SUSER_NAME()) END
      AND RCAN_RAID = @Raid;
END;
GO
