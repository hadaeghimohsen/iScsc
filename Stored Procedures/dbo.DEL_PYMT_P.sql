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
 	   DECLARE @AP BIT
             ,@AccessString VARCHAR(250);

   	
	   SELECT @Rqid = @X.query('//Payment').value('(Payment/@rqid)[1]', 'BIGINT')
	         ,@CashCode = @X.query('//Payment').value('(Payment/@cashcode)[1]', 'BIGINT');
   	
   	IF ISNULL(@Rqid, 0) != 0
   	BEGIN
         SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>222</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
         EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
         IF @AP = 0 
         BEGIN
            RAISERROR ( N'خطا - عدم دسترسی به ردیف 222 سطوح امینتی', -- Message text.
                     16, -- Severity.
                     1 -- State.
                     );
            RETURN;
         END
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
   	      --UNION ALL   	   
   	   );
   	   EXEC dbo.INS_LGOP_P @X = @XTemp; -- xml
      	
	      -- ابتدا حذف تخفیفات هزینه
	      DELETE dbo.Payment_Discount
	       WHERE PYMT_CASH_CODE = @CashCode
	         AND PYMT_RQST_RQID = @Rqid;
      	
   	   -- Remove Payment_Expense
   	   DELETE dbo.Payment_Expense
          WHERE RQRO_RQST_RQID = @Rqid;
      	
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
	   END
	   
	   SELECT @Rqid = @X.query('//Deposit').value('(Deposit/@rqid)[1]', 'BIGINT');
	   IF(ISNULL(@Rqid, 0) != 0)
	   BEGIN 
	      SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>274</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
         EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
         IF @AP = 0 
         BEGIN
            RAISERROR ( N'خطا - عدم دسترسی به ردیف 274 سطوح امینتی', -- Message text.
                     16, -- Severity.
                     1 -- State.
                     );
            RETURN;
         END
	      -- حذف مبلغ سپرده
	      /*DELETE dbo.Gain_Loss_Rial
	       WHERE RQRO_RQST_RQID = @Rqid
	         AND EXISTS (SELECT * FROM dbo.Request r WHERE r.RQID = @Rqid AND r.RQTP_CODE = '020')*/
	      DELETE dbo.Request 
	       WHERE RQID = @Rqid AND RQTP_CODE = '020';
	      
	      SET @XTemp = (
   	      SELECT rr.FIGH_FILE_NO AS '@fileno',
   	             '003' AS '@type',
   	             N'صورتحساب به مبلغ ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.AMNT), 1), '.00', '') + N' بابت ' + rt.RQTP_DESC + 
   	             --CASE WHEN p.AMNT != 0 THEN N' با تخفیف ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_PYMT_DSCN_DNRM), 1), '.00', '') ELSE N'' END +
   	             --CASE WHEN p.AMNT != 0 THEN N' با مبلغ پرداختی ' + REPLACE(CONVERT(NVARCHAR, CONVERT(MONEY, p.SUM_RCPT_EXPN_PRIC), 1), '.00', '') ELSE N'' END +
   	             N' که توسط کاربر ' + p.CRET_BY + N' ایجاد شده بود توسط کاربر ' + UPPER(SUSER_NAME()) + N' به صورت کامل از سیستم حذف شد' AS '@text'
   	        FROM dbo.Gain_Loss_Rial p, dbo.Request r, dbo.Request_Row rr, dbo.Request_Type rt
   	       WHERE p.RQRO_RQST_RQID = r.RQID
   	         AND r.RQID = rr.RQST_RQID
   	         AND r.RQTP_CODE = rt.CODE
   	         AND r.RQID = @Rqid
   	         FOR XML PATH('Log')
   	   )
   	   EXEC dbo.INS_LGOP_P @X = @XTemp; -- xml
	   END 
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
