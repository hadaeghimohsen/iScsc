SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_ACTN_P] 
   @REGN_PRVN_CNTY_CODE VARCHAR(3)
  ,@REGN_PRVN_CODE VARCHAR(3)
  ,@REGN_CODE VARCHAR(3)
  ,@CLUB_CODE BIGINT
  ,@SUM_AMNT BIGINT
  ,@AMNT_TYPE VARCHAR(3)
  ,@AMNT_DATE DATETIME
  ,@RWNO BIGINT OUT
AS
BEGIN
   IF NOT EXISTS(
      SELECT * FROM Account
       WHERE [REGN_PRVN_CNTY_CODE] = @REGN_PRVN_CNTY_CODE
         AND [REGN_PRVN_CODE] = @REGN_PRVN_CODE
         AND [REGN_CODE] = @REGN_CODE
         AND [CLUB_CODE] = @CLUB_CODE
         AND [AMNT_TYPE] = @AMNT_TYPE
         AND CAST([AMNT_DATE] AS DATE) = CAST(@AMNT_DATE AS DATE)
   )
   BEGIN
      INSERT INTO [Account]
                 ([REGN_PRVN_CNTY_CODE]
                 ,[REGN_PRVN_CODE]
                 ,[REGN_CODE]
                 ,[CLUB_CODE]
                 ,[RWNO]
                 ,[SUM_AMNT]
                 ,[AMNT_TYPE]
                 ,[AMNT_DATE])
           VALUES
                 (@REGN_PRVN_CNTY_CODE
                 ,@REGN_PRVN_CODE
                 ,@REGN_CODE
                 ,@CLUB_CODE
                 ,dbo.GNRT_NVID_U()
                 ,@SUM_AMNT
                 ,@AMNT_TYPE
                 ,@AMNT_DATE);
      SELECT @RWNO = MAX(RWNO)
        FROM Account
       WHERE [REGN_PRVN_CNTY_CODE] = @REGN_PRVN_CNTY_CODE
         AND [REGN_PRVN_CODE] = @REGN_PRVN_CODE
         AND [REGN_CODE] = @REGN_CODE
         AND [CLUB_CODE] = @CLUB_CODE
         AND [SUM_AMNT] = @SUM_AMNT
         AND [AMNT_TYPE] = @AMNT_TYPE
         AND [AMNT_DATE] = @AMNT_DATE
         AND [CRET_BY] = UPPER(SUSER_NAME());
   END
   ELSE              
      SELECT @RWNO = MAX(RWNO)
        FROM Account
       WHERE [REGN_PRVN_CNTY_CODE] = @REGN_PRVN_CNTY_CODE
         AND [REGN_PRVN_CODE] = @REGN_PRVN_CODE
         AND [REGN_CODE] = @REGN_CODE
         AND [CLUB_CODE] = @CLUB_CODE
         AND [AMNT_TYPE] = @AMNT_TYPE
         AND CAST([AMNT_DATE] AS DATE) = CAST(@AMNT_DATE AS DATE);
END;
GO
