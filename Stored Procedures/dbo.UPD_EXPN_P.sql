SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_EXPN_P]
   @CODE BIGINT
  ,@PRIC BIGINT
  ,@EXPN_STAT VARCHAR(3)
  ,@ADD_QUTS VARCHAR(3)
  ,@COVR_DSCT VARCHAR(3)
  ,@EXPN_TYPE VARCHAR(3)
  ,@BUY_PRIC BIGINT
  ,@BUY_EXTR_PRCT BIGINT
  ,@NUMB_OF_STOK INT
  ,@NUMB_OF_SALE INT
  ,@COVR_TAX VARCHAR(3)
  ,@NUMB_OF_ATTN_MONT INT
  ,@NUMB_OF_ATTN_WEEK INT
  ,@MODL_NUMB_BAR_CODE VARCHAR(50)
  ,@PRVT_COCH_EXPN VARCHAR(3)
  ,@NUMB_CYCL_DAY INT
  ,@NUMB_MONT_OFER INT
  ,@MIN_NUMB INT
  ,@GROP_CODE BIGINT
  ,@EXPN_DESC NVARCHAR(250)
  ,@MIN_TIME DATETIME
  ,@RELY_CMND VARCHAR(50)
  ,@ORDR_ITEM VARCHAR(100)
  ,@BRND_CODE BIGINT
  ,@Min_Pric BIGINT
  ,@Max_Pric BIGINT
  ,@Unit_Apbs_Code BIGINT
  ,@CAN_CALC_PROF VARCHAR(3)
  ,@Must_Fill_Ownr VARCHAR(3)
AS
BEGIN
	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>7</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 7 سطوح امینتی : شما مجوز ویرایش کردن آیین نامه هزینه را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      GOTO L$End;
   END
   -- پایان دسترسی
   
   UPDATE Expense
      SET EXPN_STAT = @EXPN_STAT
         ,PRIC = @PRIC
         ,EXPN_DESC = @Expn_Desc
         ,ADD_QUTS = @Add_Quts
         ,COVR_DSCT = @Covr_DSCT
         ,EXPN_TYPE = @EXPN_TYPE
         ,BUY_PRIC = @BUY_PRIC
         ,BUY_EXTR_PRCT = @BUY_EXTR_PRCT
         ,NUMB_OF_STOK = @NUMB_OF_STOK
         ,NUMB_OF_SALE = @NUMB_OF_SALE
         ,COVR_TAX = @COVR_TAX
         ,NUMB_OF_ATTN_MONT = @NUMB_OF_ATTN_MONT
         ,NUMB_OF_ATTN_WEEK = @NUMB_OF_ATTN_WEEK
         ,MODL_NUMB_BAR_CODE = @MODL_NUMB_BAR_CODE
         ,PRVT_COCH_EXPN = @PRVT_COCH_EXPN
         ,NUMB_CYCL_DAY = @NUMB_CYCL_DAY
         ,NUMB_MONT_OFER = @NUMB_MONT_OFER
         ,MIN_NUMB = @MIN_NUMB
         ,GROP_CODE = @GROP_CODE
         ,MIN_TIME = @MIN_TIME
         ,RELY_CMND = @RELY_CMND
         ,ORDR_ITEM = @ORDR_ITEM
         ,BRND_CODE = @BRND_CODE
         ,MIN_PRIC = @Min_Pric
         ,MAX_PRIC = @Max_Pric
         ,UNIT_APBS_CODE = @Unit_Apbs_Code
         ,CAN_CALC_PROF = @CAN_CALC_PROF
         ,MUST_FILL_OWNR = @Must_Fill_Ownr
    WHERE CODE = @CODE;
   
   L$End:
   RETURN;
END
GO
