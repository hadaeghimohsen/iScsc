SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[UPD_PRCM_P](
   @Prsn_Prid BIGINT
  ,@Cmnt NVARCHAR(250)
  ,@Pcid BIGINT OUT
)
AS
BEGIN
   UPDATE Present_Comment
      SET CMNT = @Cmnt
    WHERE PCID = @Pcid;
END;
GO
