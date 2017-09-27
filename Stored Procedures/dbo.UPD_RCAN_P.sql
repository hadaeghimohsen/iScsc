SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[UPD_RCAN_P](
   @Raid BIGINT,
   --@Amnt BIGINT,
   --@To_User VARCHAR(250),
   @Rcan_Stat VARCHAR(3),
   --@Auto_Doc VARCHAR(3),
   @Actn_Date DATETIME
   --@RcanRaid BIGINT
)
As
BEGIN
   UPDATE dbo.Receipt_Announcement
      SET --AMNT = @Amnt
         --,TO_USER = @To_User
         RCAN_STAT = @Rcan_Stat
         --,AUTO_DOC = @Auto_Doc
         ,ACTN_DATE = @Actn_Date
         --,RCAN_RAID = @RcanRaid
    WHERE RAID = @Raid;
END;
GO
