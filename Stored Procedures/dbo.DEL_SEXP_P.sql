SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DEL_SEXP_P]   
   @X XML
AS 
   /*
      <Request rqid="">
         <Payment cashcode="">
            <Payment_Detail code=""/>
         </Payment>
      </Request>
   */
BEGIN
   BEGIN TRY
   BEGIN TRAN DEL_SEXP_P_T
      DECLARE @Rqid BIGINT
             ,@PymtCashCode BIGINT
             ,@PymtPydtCode BIGINT;
             
      SELECT @Rqid = @X.query('Request').value('(Request/@rqid)[1]', 'BIGINT')
            ,@PymtCashCode = @X.query('Request/Payment').value('(Payment/@cashcode)[1]', 'BIGINT')
            ,@PymtPydtCode = @X.query('Request/Payment/Payment_Detail').value('(Payment_Detail/@code)[1]', 'BIGINT');
      
      -- 1400/01/01 * لاگ برداری از عملیات کاربر
      IF EXISTS (SELECT * FROM dbo.Request r WHERE r.RQID = @Rqid AND r.RQST_STAT = '002')
      BEGIN 
   	   DECLARE @XTemp XML = (
   	      SELECT rr.FIGH_FILE_NO AS '@fileno',
   	             '004' AS '@type',
   	             N'از صورتحساب به مبلغ ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_EXPN_PRIC), 1), '.00', '') + N' بابت ' + rt.RQTP_DESC + 
   	             CASE WHEN p.SUM_PYMT_DSCN_DNRM != 0 THEN N' با تخفیف ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_PYMT_DSCN_DNRM), 1), '.00', '') ELSE N'' END +
   	             CASE WHEN p.SUM_RCPT_EXPN_PRIC != 0 THEN N' با مبلغ پرداختی ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_RCPT_EXPN_PRIC), 1), '.00', '') ELSE N'' END +
   	             N' که توسط کاربر ' + p.CRET_BY + N' ایجاد شده بود توسط کاربر ' + UPPER(SUSER_NAME()) + N' یک قلم از اقلام صورتحساب که ' + e.EXPN_DESC + N' به تعداد ' + CAST(pd.QNTY AS VARCHAR(10)) + 
   	             N' به ارزش ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, pd.QNTY * pd.EXPN_PRIC), 1), '.00', '') + N' از صورتحساب مشتری حذف شد' AS '@text'
   	        FROM dbo.Payment p, dbo.Request r, dbo.Request_Row rr, dbo.Request_Type rt, dbo.Payment_Detail pd, dbo.Expense e
   	       WHERE p.RQST_RQID = r.RQID
   	         AND r.RQID = rr.RQST_RQID
   	         AND r.RQTP_CODE = rt.CODE
   	         AND pd.PYMT_RQST_RQID = p.RQST_RQID
   	         AND pd.EXPN_CODE = e.CODE
   	         AND r.RQID = @Rqid
   	         AND pd.CODE = @PymtPydtCode
   	         FOR XML PATH('Log')
   	   );
   	   EXEC dbo.INS_LGOP_P @X = @XTemp; -- xml
      END 
      
      DELETE Payment_Detail
       WHERE PYMT_RQST_RQID = @Rqid
         AND PYMT_CASH_CODE = @PymtCashCode
         AND CODE = @PymtPydtCode;
         
      COMMIT TRAN DEL_SEXP_P_T;
   END TRY
   BEGIN CATCH
      DECLARE @ErrorMessage NVARCHAR(MAX);
      SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN DEL_SEXP_P_T;
   END CATCH
END
GO
