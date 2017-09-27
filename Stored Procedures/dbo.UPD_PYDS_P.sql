SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_PYDS_P]
	-- Add the parameters for the stored procedure here
	@PymtCashCode BIGINT,
	@PymtRqstRqid BIGINT,
	@RqroRwno SMALLINT,
	@Rwno SMALLINT,
	@ExpnCode BIGINT,
	@Amnt INT,
	@AmntType VARCHAR(3) = '002',
	@Stat VARCHAR(3),
	@PydsDesc NVARCHAR(250)
AS
BEGIN
	 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>181</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 181 سطوح امینتی : شما مجوز ویرایش کردن تخفیف مبلغ هزینه را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   --IF @Amnt = 0 RAISERROR (N'مبلغ تخفیف باید مبلغی مثبت و غیر صفر باشد', 16, 1);
   
   UPDATE dbo.Payment_Discount
      SET Expn_Code = @ExpnCode
         ,Amnt = @Amnt
         ,Amnt_Type = @AmntType
         ,Stat = @Stat
         ,PYDS_DESC = @PydsDesc
    WHERE PYMT_CASH_CODE = @PymtCashCode
      AND PYMT_RQST_RQID = @PymtRqstRqid
      AND RQRO_RWNO = @RqroRwno
      AND RWNO = @Rwno;           
END
GO
