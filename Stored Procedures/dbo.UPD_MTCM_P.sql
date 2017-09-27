SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[UPD_MTCM_P](
   @Meet_Mtid BIGINT
  ,@Cmnt      NVARCHAR(250)
  ,@Rspn_Impl NVARCHAR(100)
  ,@Exp_Date  DATETIME
  ,@Mcid      BIGINT OUT
)
AS
BEGIN
   UPDATE Meeting_Comment
      SET CMNT = @Cmnt
         ,RSPN_IMPL = @Rspn_Impl
         ,EXP_DATE = @Exp_Date
    WHERE MCID = @Mcid;
END;
GO
