SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DUP_CEXC_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
	   BEGIN TRANSACTION T$DUP_CEXC_P
	   
	   -- Local Parameters
	   DECLARE @CexcCode BIGINT;      
      SELECT @CexcCode = @X.query('//OpIran').value('(OpIran/@cexccode)[1]', 'BIGINT');
      
      -- Local Variables      
              
      INSERT INTO dbo.Calculate_Expense_Coach
      ( CODE , EXPN_CODE , COCH_FILE_NO ,
       EPIT_CODE , RQTP_CODE , RQTT_CODE ,
       COCH_DEG , EXTP_CODE , 
       MTOD_CODE , CTGY_CODE ,
       CALC_EXPN_TYPE , CALC_TYPE , PRCT_VALU ,
       STAT , PYMT_STAT ,
       MIN_NUMB_ATTN , MIN_ATTN_STAT ,
       RDUC_AMNT , CBMT_CODE , 
       EFCT_DATE_TYPE , EXPR_PAY_DAY ,
       TAX_PRCT_VALU , FORE_GIVN_ATTN_NUMB 
      )      
      SELECT dbo.GNRT_NVID_U(), e.CODE, cm.COCH_FILE_NO,
             et.EPIT_CODE, rr.RQTP_CODE, rr.RQTT_CODE,             
             ex.COCH_DEG, e.EXTP_CODE, 
             e.MTOD_CODE, e.CTGY_CODE,
             ex.CALC_EXPN_TYPE, ex.CALC_TYPE, ex.PRCT_VALU,
             ex.STAT, ex.PYMT_STAT,
             ex.MIN_NUMB_ATTN, ex.MIN_ATTN_STAT,
             ex.RDUC_AMNT, ex.CBMT_CODE,
             ex.EFCT_DATE_TYPE, ex.EXPR_PAY_DAY,
             ex.TAX_PRCT_VALU, ex.FORE_GIVN_ATTN_NUMB
        FROM dbo.Expense e, dbo.Expense_Type et, dbo.Request_Requester rr, 
             dbo.Club_Method cm, dbo.Calculate_Expense_Coach ex
       WHERE e.EXPN_STAT = '002'
         AND e.PRIC > 0
         AND e.MTOD_CODE = cm.MTOD_CODE
         AND cm.MTOD_STAT = '002'
         AND ex.CODE = @CexcCode
         AND e.EXTP_CODE = et.CODE
         AND et.RQRQ_CODE = rr.CODE
         AND (
             (ex.RQTP_CODE = '016' AND rr.RQTP_CODE = '016') OR 
             (ex.RQTP_CODE IN ('001', '009') AND rr.RQTP_CODE IN ('001', '009'))
         )
         AND NOT EXISTS (
             SELECT *
               FROM dbo.Calculate_Expense_Coach ext
              WHERE ext.EXPN_CODE = e.CODE
                AND ext.COCH_FILE_NO = cm.COCH_FILE_NO
                AND ext.MTOD_CODE = cm.MTOD_CODE
         )
         AND cm.CODE = (
             SELECT MAX(cmt.CODE)
               FROM dbo.Club_Method cmt
              WHERE cmt.COCH_FILE_NO = cm.COCH_FILE_NO
                AND cmt.MTOD_CODE = cm.MTOD_CODE
                AND cmt.MTOD_STAT = '002'
         );
      -- در این قسمت باید برای تمام گزینه های پرسنلی که در قسمت مدیریت بخش خدمات ارائه میدهند اطلاعات را وارد کنیم
      
	   
	   COMMIT TRANSACTION [T$DUP_CEXC_P]	
	END TRY
	BEGIN CATCH
	   DECLARE @ErorMesg NVARCHAR(MAX) = ERROR_MESSAGE();
	   RAISERROR(@ErorMesg, 16, 1);
	   ROLLBACK TRANSACTION [T$DUP_CEXC_P]
	END CATCH
END
GO
