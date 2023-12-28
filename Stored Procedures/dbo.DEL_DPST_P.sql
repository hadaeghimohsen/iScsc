SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_DPST_P]
	-- Add the parameters for the stored procedure here
	@X XML
AS
BEGIN
	BEGIN TRY
   BEGIN TRAN DEL_DPST_T
   
	   DECLARE @Rqid BIGINT;
   	
	   SELECT @Rqid = @X.query('//Deposit').value('(Deposit/@rqid)[1]', 'BIGINT');
   	
   	-- 1400/01/01 * لاگ برداری از عملیات کاربر
   	DECLARE @XTemp XML = (
   	   SELECT rr.FIGH_FILE_NO AS '@fileno',
   	          '013' AS '@type',
   	          N'صورتحساب بیعانه به مبلغ ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.AMNT), 1), '.00', '') + N' بابت ' + rt.RQTP_DESC + 
   	          --CASE WHEN p.SUM_PYMT_DSCN_DNRM != 0 THEN N' با تخفیف ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_PYMT_DSCN_DNRM), 1), '.00', '') ELSE N'' END +
   	          --CASE WHEN p.SUM_RCPT_EXPN_PRIC != 0 THEN N' با مبلغ پرداختی ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_RCPT_EXPN_PRIC), 1), '.00', '') ELSE N'' END +
   	          N' که توسط کاربر ' + p.CRET_BY + N' ایجاد شده بود توسط کاربر ' + UPPER(SUSER_NAME()) + N' به صورت کامل از سیستم حذف شد' AS '@text'
   	     FROM dbo.Gain_Loss_Rial p, dbo.Request r, dbo.Request_Row rr, dbo.Request_Type rt
   	    WHERE p.RQRO_RQST_RQID = r.RQID
   	      AND r.RQID = rr.RQST_RQID
   	      AND r.RQTP_CODE = rt.CODE
   	      AND r.RQID = @Rqid
   	      FOR XML PATH('Log')
   	);
   	EXEC dbo.INS_LGOP_P @X = @XTemp; -- xml
   	
	   -- حذف مبلغ بیعانه
	   DELETE dbo.Gain_Loss_Rial
	    WHERE RQRO_RQST_RQID = @Rqid;
	
	COMMIT TRAN DEL_DPST_T
	END TRY
	BEGIN CATCH
	   DECLARE @ErrorMessage NVARCHAR(MAX);
	   SET @ErrorMessage = ERROR_MESSAGE();
      RAISERROR ( @ErrorMessage, -- Message text.
               16, -- Severity.
               1 -- State.
               );
      ROLLBACK TRAN DEL_DPST_T;
	END CATCH
END
GO
