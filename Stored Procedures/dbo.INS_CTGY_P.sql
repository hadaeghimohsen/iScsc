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
	@Name     NVARCHAR(250),
	@Ctgy_Desc NVARCHAR(250),
	@Ordr    SMALLINT,
	@Epit_Type VARCHAR(3),
	@Numb_Of_Attn_Mont INT,
	@NUmb_Cycl_Day INT,
	@Numb_Mont_Ofer INT,
	@Prvt_Coch_Expn VARCHAR(3),
	@Pric INT,
	@Dflt_Stat VARCHAR(3),
	@Ctgy_Stat VARCHAR(3)
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
   
   INSERT INTO Category_Belt (MTOD_CODE, NAME, CTGY_DESC, ORDR, EPIT_TYPE, NUMB_OF_ATTN_MONT, NUMB_CYCL_DAY, NUMB_MONT_OFER, PRVT_COCH_EXPN, PRIC, DFLT_STAT, CTGY_STAT)
   VALUES (@Mtod_Code, @Name, @Ctgy_Desc, @Ordr, @Epit_Type, @Numb_Of_Attn_Mont, @NUmb_Cycl_Day, @Numb_Mont_Ofer, @Prvt_Coch_Expn, @Pric, ISNULL(@Dflt_Stat, '001'), @Ctgy_Stat);
END
GO
