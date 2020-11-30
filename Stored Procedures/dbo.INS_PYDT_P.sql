SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[INS_PYDT_P]
   @PYMT_CASH_CODE BIGINT
  ,@PYMT_RQST_RQID BIGINT
  ,@RQRO_RWNO SMALLINT
  ,@EXPN_CODE BIGINT
  ,@PAY_STAT VARCHAR(3)
  ,@EXPN_PRIC BIGINT
  ,@EXPN_EXTR_PRCT BIGINT
  ,@REMN_PRIC BIGINT
  ,@QNTY REAL 
  ,@DOCM_NUMB BIGINT
  ,@ISSU_DATE DATETIME
  ,@RCPT_MTOD VARCHAR(3)
  ,@RECV_LETT_NO VARCHAR(15)
  ,@RECV_LETT_DATE DATETIME
  ,@PYDT_DESC NVARCHAR(250)
  ,@ADD_QUTS VARCHAR(3)
  ,@FIGH_FILE_NO BIGINT
  ,@PRE_EXPN_STAT VARCHAR(3)
  ,@CBMT_CODE_DNRM BIGINT
  ,@EXPR_DATE DATE
  ,@CODE BIGINT out
AS
BEGIN

INSERT INTO [dbo].[Payment_Detail]
           ([PYMT_CASH_CODE]
           ,[PYMT_RQST_RQID]
           ,[RQRO_RWNO]
           ,[EXPN_CODE]
           ,[CODE]
           ,[PAY_STAT]
           ,[EXPN_PRIC]
           ,[EXPN_EXTR_PRCT]
           ,[REMN_PRIC]
           ,[QNTY]
           ,[DOCM_NUMB]
           ,[ISSU_DATE]
           ,[RCPT_MTOD]
           ,[RECV_LETT_NO]
           ,[RECV_LETT_DATE]
           ,[PYDT_DESC]
           ,[ADD_QUTS]
           ,[FIGH_FILE_NO]
           ,[PRE_EXPN_STAT]
           ,[CBMT_CODE_DNRM]
           ,[EXPR_DATE])
     VALUES
           (@PYMT_CASH_CODE
           ,@PYMT_RQST_RQID
           ,@RQRO_RWNO
           ,@EXPN_CODE
           ,0
           ,@PAY_STAT
           ,@EXPN_PRIC
           ,@EXPN_EXTR_PRCT
           ,@REMN_PRIC
           ,@QNTY
           ,@DOCM_NUMB
           ,@ISSU_DATE
           ,@RCPT_MTOD
           ,@RECV_LETT_NO
           ,@RECV_LETT_DATE
           ,@PYDT_DESC
           ,@ADD_QUTS
           ,@Figh_File_No
           ,@PRE_EXPN_STAT
           ,@CBMT_CODE_DNRM
           ,@EXPR_DATE);
   
   SELECT @CODE = CODE
     FROM dbo.Payment_Detail
    WHERE PYMT_RQST_RQID = @PYMT_RQST_RQID
      AND PYMT_CASH_CODE = @PYMT_CASH_CODE
      AND RQRO_RWNO = @RQRO_RWNO
      AND EXPN_CODE = @EXPN_CODE; 
END;



GO
