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
