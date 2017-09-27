SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_PYDS_P]
	-- Add the parameters for the stored procedure here
	@PymtCashCode BIGINT,
	@PymtRqstRqid BIGINT,
	@RqroRwno SMALLINT,
	@ExpnCode BIGINT,
	@Amnt INT,
	@AmntType VARCHAR(3),
	@Stat VARCHAR(3),
	@PydsDesc NVARCHAR(250)
AS
BEGIN
	 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>179</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 179 سطوح امینتی : شما مجوز اضافه کردن تخفیف مبلغ هزینه را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   IF @Amnt = 0 RAISERROR (N'مبلغ تخفیف باید مبلغی مثبت و غیر صفر باشد', 16, 1);
   IF @RqroRwno = 0 OR @RqroRwno IS NULL
      SET @RqroRwno = 1;
   IF @AmntType IS NULL
      SET @AmntType = '002';
   IF @Stat IS NULL 
      SET @Stat = '002';
      
   INSERT INTO dbo.Payment_Discount
           ( PYMT_CASH_CODE ,
             PYMT_RQST_RQID ,
             RQRO_RWNO ,
             --RWNO ,
             EXPN_CODE ,
             AMNT ,
             AMNT_TYPE ,
             STAT ,
             PYDS_DESC 
           )
   VALUES  ( @PymtCashCode , -- PYMT_CASH_CODE - bigint
             @PymtRqstRqid , -- PYMT_RQST_RQID - bigint
             @RqroRwno , -- RQRO_RWNO - smallint
             --0 , -- RWNO - smallint
             @ExpnCode , -- EXPN_CODE - bigint
             @Amnt , -- AMNT - int
             @AmntType , -- AMNT_TYPE - varchar(3)
             @Stat , -- STAT - varchar(3)
             @PydsDesc  -- PYDS_DESC - nvarchar(250)             
           )   
END
GO
