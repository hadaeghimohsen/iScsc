SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_PYMT_P]
	@X XML
AS
BEGIN
   BEGIN TRY
   BEGIN TRAN DEL_PYMT_T
   
	   DECLARE @Rqid BIGINT
	          ,@CashCode BIGINT;
   	
	   SELECT @Rqid = @X.query('//Payment').value('(Payment/@rqid)[1]', 'BIGINT')
	         ,@CashCode = @X.query('//Payment').value('(Payment/@cashcode)[1]', 'BIGINT');
   	
   	-- 1400/01/01 * لاگ برداری از عملیات کاربر
   	DECLARE @XTemp XML = (
   	   SELECT rr.FIGH_FILE_NO AS '@fileno',
   	          '003' AS '@type',
   	          N'صورتحساب به مبلغ ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_EXPN_PRIC), 1), '.00', '') + N' بابت ' + rt.RQTP_DESC + 
   	          CASE WHEN p.SUM_PYMT_DSCN_DNRM != 0 THEN N' با تخفیف ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_PYMT_DSCN_DNRM), 1), '.00', '') ELSE N'' END +
   	          CASE WHEN p.SUM_RCPT_EXPN_PRIC != 0 THEN N' با مبلغ پرداختی ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_RCPT_EXPN_PRIC), 1), '.00', '') ELSE N'' END +
   	          N' که توسط کاربر ' + p.CRET_BY + N' ایجاد شده بود توسط کاربر ' + UPPER(SUSER_NAME()) + N' به صورت کامل از سیستم حذف شد' AS '@text'
   	     FROM dbo.Payment p, dbo.Request r, dbo.Request_Row rr, dbo.Request_Type rt
   	    WHERE p.RQST_RQID = r.RQID
   	      AND r.RQID = rr.RQST_RQID
   	      AND r.RQTP_CODE = rt.CODE
   	      AND r.RQID = @Rqid
   	      FOR XML PATH('Log')
   	);
   	EXEC dbo.INS_LGOP_P @X = @XTemp; -- xml
   	
	   -- ابتدا حذف تخفیفات هزینه
	   DELETE dbo.Payment_Discount
	    WHERE PYMT_CASH_CODE = @CashCode
	      AND PYMT_RQST_RQID = @Rqid;
   	
	   --  حذف چک های هزینه   
	   DELETE dbo.Payment_Check
	    WHERE PYMT_CASH_CODE = @CashCode
	      AND PYMT_RQST_RQID = @Rqid;
   	
	   -- حذف پرداختی های هزینه
	   DELETE dbo.Payment_Method
	    WHERE PYMT_CASH_CODE = @CashCode
	      AND PYMT_RQST_RQID = @Rqid;
   	
	   -- حذف آیتم های هزینه
	   DELETE dbo.Payment_Detail
       WHERE PYMT_CASH_CODE = @CashCode
	      AND PYMT_RQST_RQID = @Rqid;
   	
	   -- حذف هزینه
	   DELETE dbo.Payment
	    WHERE CASH_CODE = @CashCode
	      AND RQST_RQID = @Rqid;
	
	COMMIT TRAN DEL_PYMT_T
	END TRY
	BEGIN CATCH
	   DECLARE @ErrorMessage NVARCHAR(MAX);
	   SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN DEL_PYMT_T;
	END CATCH
END
GO
