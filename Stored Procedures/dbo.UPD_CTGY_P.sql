SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_CTGY_P]
	-- Add the parameters for the stored procedure here
	@Code     BIGINT,
	@Ctgy_Code BIGINT,
	@Name     NVARCHAR(250),
	@Ctgy_Desc NVARCHAR(250),
	@Ordr    SMALLINT,
	@Epit_Type VARCHAR(3),
	@Numb_Of_Attn_Mont INT,
	@Numb_Cycl_Day INT,
	@Numb_Mont_Ofer INT,
	@Prvt_Coch_Expn VARCHAR(3),
	@Pric BIGINT,
	@Dflt_Stat VARCHAR(3),
	@Ctgy_Stat VARCHAR(3),
	@Gust_Numb INT,
	@Natl_Code VARCHAR(2),
	@Rwrd_Attn_Pric BIGINT,
	@Show_Stat VARCHAR(3),
	@Fee_Amnt BIGINT
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>22</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 22 سطوح امینتی : شما مجوز ویرایش کردن رده کمربند را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   UPDATE Category_Belt
      SET NAME = @Name
         ,CTGY_DESC = @Ctgy_Desc
         ,ORDR = @Ordr
         ,EPIT_TYPE = @Epit_Type
         ,NUMB_OF_ATTN_MONT = @Numb_Of_Attn_Mont
         ,NUMB_CYCL_DAY = @NUmb_Cycl_Day
         ,NUMB_MONT_OFER = @Numb_Mont_Ofer
         ,PRVT_COCH_EXPN = @Prvt_Coch_Expn
         ,PRIC = @Pric
         ,DFLT_STAT = ISNULL(@Dflt_Stat, '001')
         ,CTGY_STAT = @Ctgy_Stat
         ,GUST_NUMB = @Gust_Numb
         ,NATL_CODE = @Natl_Code
         ,RWRD_ATTN_PRIC = @Rwrd_Attn_Pric
         ,SHOW_STAT = @Show_Stat
         ,CTGY_CODE = @Ctgy_Code
         ,FEE_AMNT = @Fee_Amnt
    WHERE CODE = @Code;
END
GO
