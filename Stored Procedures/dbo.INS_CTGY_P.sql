SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_CTGY_P]
	-- Add the parameters for the stored procedure here
	@Mtod_Code BIGINT,
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
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>21</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 21 سطوح امینتی : شما مجوز اضافه کردن رده کمربند را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   -- شماره کد تعرفه
   IF CONVERT(INT, ISNULL(@Natl_Code, '0')) = 0
   BEGIN
      SELECT @Natl_Code = dbo.GET_PSTR_U(MAX(CONVERT(INT, ISNULL(c.NATL_CODE, '0'))) + 1, 2)
        FROM dbo.Category_Belt c
       WHERE c.MTOD_CODE = @Mtod_Code;
   END 
   
   IF ISNULL(@Gust_Numb, 0) = 0 AND ISNULL(@Numb_Of_Attn_Mont, 0) > 0
      SET @Gust_Numb = @Numb_Of_Attn_Mont;
   
   SET @Rwrd_Attn_Pric = ISNULL(@Rwrd_Attn_Pric, 0);
   
   INSERT INTO Category_Belt (MTOD_CODE, CTGY_CODE, NAME, CTGY_DESC, ORDR, EPIT_TYPE, NUMB_OF_ATTN_MONT, NUMB_CYCL_DAY, NUMB_MONT_OFER, PRVT_COCH_EXPN, PRIC, DFLT_STAT, CTGY_STAT, GUST_NUMB, NATL_CODE, RWRD_ATTN_PRIC, SHOW_STAT, FEE_AMNT)
   VALUES (@Mtod_Code, @Ctgy_Code, @Name, @Ctgy_Desc, @Ordr, @Epit_Type, @Numb_Of_Attn_Mont, @NUmb_Cycl_Day, @Numb_Mont_Ofer, @Prvt_Coch_Expn, @Pric, ISNULL(@Dflt_Stat, '001'), @Ctgy_Stat, @Gust_Numb, @Natl_Code, @Rwrd_Attn_Pric, @Show_Stat, @Fee_Amnt);
END
GO
