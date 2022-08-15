SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[DEL_PYDS_P]
	-- Add the parameters for the stored procedure here
	@Pymt_Cash_Code BIGINT,
	@Pymt_Rqst_Rqid BIGINT,
	@Rqro_Rwno SMALLINT,
	@Rwno SMALLINT
AS
BEGIN
	 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>180</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 180 سطوح امینتی : شما مجوز حذف کردن تخفیف مبلغ هزینه را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   --IF @Amnt = 0 RAISERROR (N'مبلغ تخفیف باید مبلغی مثبت و غیر صفر باشد', 16, 1);
   
   -- 1401/05/21 * رکورد هایی که برای کد تخفیف لحاظ شده اند اگر در جدول تخفیف صورتحساب حذف شود باید دوباره آزاد گردند
   -- آزاد سازی تخفیف کمپین تبلیغاتی
   UPDATE dbo.Advertising_Campaign
      SET RQST_RQID = NULL
    WHERE RQST_RQID = @Pymt_Rqst_Rqid;
   
   -- آزاد سازی تخفیف مشتریان ارزنده
   UPDATE dbo.Fighter_Discount_Card
      SET RQST_RQID = NULL
    WHERE RQST_RQID = @Pymt_Rqst_Rqid;
   
   DELETE dbo.Payment_Discount
    WHERE PYMT_CASH_CODE = @Pymt_Cash_Code
      AND PYMT_RQST_RQID = @Pymt_Rqst_Rqid
      AND RQRO_RWNO = @Rqro_Rwno
      AND RWNO = @Rwno;           
END
GO
