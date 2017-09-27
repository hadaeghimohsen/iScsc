SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_ACDT_P] 
   @ACTN_REGN_PRVN_CNTY_CODE VARCHAR(3)
  ,@ACTN_REGN_PRVN_CODE VARCHAR(3)
  ,@ACTN_REGN_CODE VARCHAR(3)
  ,@ACTN_CLUB_CODE BIGINT
  ,@ACTN_RWNO BIGINT
  ,@AMNT BIGINT
  ,@AMNT_TYPE VARCHAR(3)
  ,@AMNT_DATE DATETIME
  ,@PYMT_CASH_CODE BIGINT
  ,@PYMT_RQST_RQID BIGINT
  ,@MSEX_CODE BIGINT
  ,@RWNO INT OUT
AS
BEGIN
   INSERT INTO [Account_Detail]
           ([ACTN_REGN_PRVN_CNTY_CODE]
           ,[ACTN_REGN_PRVN_CODE]
           ,[ACTN_REGN_CODE]
           ,[ACTN_CLUB_CODE]
           ,[ACTN_RWNO]
           ,[RWNO]
           ,[AMNT]
           ,[AMNT_TYPE]
           ,[AMNT_DATE]
           ,[PYMT_CASH_CODE]
           ,[PYMT_RQST_RQID]
           ,[MSEX_CODE])
     VALUES
           (@ACTN_REGN_PRVN_CNTY_CODE
           ,@ACTN_REGN_PRVN_CODE
           ,@ACTN_REGN_CODE
           ,@ACTN_CLUB_CODE
           ,@ACTN_RWNO
           ,0
           ,@AMNT
           ,@AMNT_TYPE
           ,@AMNT_DATE
           ,@PYMT_CASH_CODE
           ,@PYMT_RQST_RQID
           ,@MSEX_CODE);
   
   SELECT @RWNO = MAX(RWNO)
     FROM Account_Detail
    WHERE [ACTN_REGN_PRVN_CNTY_CODE]  = @ACTN_REGN_PRVN_CNTY_CODE
      AND [ACTN_REGN_PRVN_CODE]       = @ACTN_REGN_PRVN_CODE
      AND [ACTN_REGN_CODE]            = @ACTN_REGN_CODE
      AND [ACTN_CLUB_CODE]            = @ACTN_CLUB_CODE
      AND [ACTN_RWNO]                 = @ACTN_RWNO
      AND [AMNT]                      = @AMNT
      AND [AMNT_TYPE]                 = @AMNT_TYPE
      AND [AMNT_DATE]                 = @AMNT_DATE
      AND ISNULL([PYMT_CASH_CODE], 0) = ISNULL(@PYMT_CASH_CODE, 0)
      AND ISNULL([PYMT_RQST_RQID], 0) = ISNULL(@PYMT_RQST_RQID, 0)
      AND ISNULL([MSEX_CODE], 0)      = ISNULL(@MSEX_CODE, 0);
END;
GO
