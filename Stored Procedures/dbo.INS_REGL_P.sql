SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_REGL_P]
	@Year SMALLINT
  ,@Type VARCHAR(3)
  ,@LettNo VARCHAR(15)
  ,@LettDate DATETIME
  ,@LettOwnr NVARCHAR(250)
  ,@StrtDate DATETIME
  ,@EndDate  DATETIME
  ,@TaxPrct  REAL
  ,@DutyPrct REAL
  ,@AmntType Varchar(3)
AS
BEGIN
   -- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>3</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 3 سطوح امینتی : شما مجوز درح آیین نامه را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      GOTO L$End;
   END;
   -- پایان دسترسی
   
  
	INSERT INTO Regulation ( YEAR, TYPE, SUB_SYS,  REGL_STAT, LETT_NO, LETT_DATE, LETT_OWNR, STRT_DATE, END_DATE, TAX_PRCT, DUTY_PRCT, AMNT_TYPE)
	VALUES                 (@Year, @Type, 1      , '001'    , @LettNo, @LettDate, @LettOwnr, @StrtDate, @EndDate, @TaxPrct, @DutyPrct, @AmntType)
	
	L$End:
	RETURN;
END
GO
