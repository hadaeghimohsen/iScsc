SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[UPD_PYDT_T]
   @CODE BIGINT
  ,@PYMT_CASH_CODE BIGINT
  ,@PYMT_RQST_RQID BIGINT
  ,@RQRO_RWNO SMALLINT
  ,@EXPN_CODE BIGINT
  ,@PAY_STAT VARCHAR(3)
  ,@EXPN_PRIC bigint
  ,@EXPN_EXTR_PRCT bigint
  ,@REMN_PRIC bigint
  ,@QNTY REAL 
  ,@DOCM_NUMB BIGINT
  ,@ISSU_DATE DATETIME
  ,@RCPT_MTOD VARCHAR(3)
  ,@RECV_LETT_NO VARCHAR(15)
  ,@RECV_LETT_DATE DATETIME
  ,@PYDT_DESC NVARCHAR(250)
  ,@ADD_QUTS VARCHAR(3)
  ,@Figh_File_No BIGINT
  ,@Pre_Expn_Stat VARCHAR(3)
  ,@Cbmt_Code_Dnrm BIGINT
  ,@EXPR_DATE DATETIME
  ,@From_Numb BIGINT
  ,@To_Numb BIGINT
  ,@Exts_Code BIGINT
  ,@Exts_Rsrv_Date DATETIME
AS
BEGIN

UPDATE [dbo].[Payment_Detail]
   SET   [EXPN_CODE] = @EXPN_CODE     
        ,[PAY_STAT] = @PAY_STAT
        ,[QNTY] = @QNTY
        ,[DOCM_NUMB] = @DOCM_NUMB
        ,[ISSU_DATE] = @ISSU_DATE
        ,[RCPT_MTOD] = @RCPT_MTOD
        ,[RECV_LETT_NO] = @RECV_LETT_NO
        ,[RECV_LETT_DATE] = @RECV_LETT_DATE
        ,[PYDT_DESC] = @PYDT_DESC
        ,[ADD_QUTS] = @ADD_QUTS
        ,[FIGH_FILE_NO] = @Figh_File_No
        ,PRE_EXPN_STAT = @Pre_Expn_Stat
        ,CBMT_CODE_DNRM = @Cbmt_Code_Dnrm
        ,EXPR_DATE = @EXPR_DATE
        ,FROM_NUMB = @From_Numb
        ,TO_NUMB = @To_Numb
        ,EXTS_CODE = @Exts_Code
        ,EXTS_RSRV_DATE = @Exts_Rsrv_Date
 WHERE PYMT_RQST_RQID = @PYMT_RQST_RQID
   AND PYMT_CASH_CODE = @PYMT_CASH_CODE
   AND RQRO_RWNO = @RQRO_RWNO
   AND EXPN_CODE = @EXPN_CODE
   AND CODE = @CODE; 
END;



GO
