SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_PYDT_P]
	@Rqid BIGINT,
	@CashCode BIGINT,
	@RqroRwno SMALLINT,
	@ExpnCode BIGINT,
	@DocmNumb BIGINT,
	@IssuDate DATE,
	@RcptMtod VARCHAR(3)
AS
BEGIN
   -- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>69</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 69 سطوح امینتی : شما مجوز ذخیره کردن اطلاعات هزینه های پرداخت شده برای ثبت نام را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   
	UPDATE Payment_Detail
	   SET DOCM_NUMB = @DocmNumb
	      ,ISSU_DATE = @IssuDate
	      ,RCPT_MTOD = @RcptMtod
	 WHERE PYMT_RQST_RQID = @Rqid
	   AND PYMT_CASH_CODE = @CashCode
	   AND RQRO_RWNO = @RqroRwno
	   AND EXPN_CODE = @ExpnCode;
END
GO
