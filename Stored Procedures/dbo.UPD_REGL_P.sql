SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_REGL_P]
	@Year SMALLINT
  ,@Code INT
  ,@Type VARCHAR(3)
  ,@ReglStat VARCHAR(3)
  ,@LettNo VARCHAR(15)
  ,@LettDate DATETIME
  ,@LettOwnr NVARCHAR(250)
  ,@StrtDate DATETIME
  ,@EndDate  DATETIME
  ,@TaxPrct  REAL
  ,@DutyPrct REAL
  ,@AmntType Varchar(3)
  ,@InsrPric BIGINT
AS
BEGIN
   -- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>4</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 4 سطوح امینتی : شما مجوز ویرایش کردن آیین نامه را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      GOTO L$End;
   END
   -- پایان دسترسی
   
	UPDATE Regulation
	   SET TYPE = @Type
	      ,REGL_STAT = @ReglStat
	      ,LETT_NO = @LettNo
	      ,LETT_DATE = @LettDate
	      ,LETT_OWNR = @LettOwnr
	      ,STRT_DATE = @StrtDate
	      ,END_DATE = @EndDate
	      ,TAX_PRCT = @TaxPrct
	      ,DUTY_PRCT = @DutyPrct
	      ,AMNT_TYPE = @AmntType
	      ,INSR_PRIC = @InsrPric
	 WHERE YEAR = @Year
	   AND CODE = @Code;
	
	L$End:
	RETURN;
END
GO
