SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_CLUB_P]
	-- Add the parameters for the stored procedure here
	@Regn_Prvn_Cnty_Code VARCHAR(3),
	@Regn_Prvn_Code VARCHAR(3),
	@Regn_Code VARCHAR(3),
	@Name     NVARCHAR(250),
	@Post_Adrs NVARCHAR(1000),
	@Emal_Adrs VARCHAR(250),
	@Web_Site  VARCHAR(500),
	@Cord_X    FLOAT,
	@Cord_Y    FLOAT,
	@Tell_Phon VARCHAR(15),
	@Cell_Phon VARCHAR(11)
AS
BEGIN
 	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>42</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 42 سطوح امینتی : شما مجوز اضافه کردن باشگاه جدید را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   INSERT INTO Club (REGN_PRVN_CNTY_CODE, REGN_PRVN_CODE, REGN_CODE, NAME, POST_ADRS, EMAL_ADRS, WEB_SITE,CORD_X, CORD_Y, TELL_PHON, CELL_PHON)
   VALUES (@Regn_Prvn_Cnty_Code, @Regn_Prvn_Code, @Regn_Code, @Name, @Post_Adrs, @Emal_Adrs, @Web_Site, @Cord_X, @Cord_Y, @Tell_Phon, @Cell_Phon);
END
GO
