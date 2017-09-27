SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[UPD_CLUB_P]
	-- Add the parameters for the stored procedure here
   @Code     BIGINT,
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
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>43</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 43 سطوح امینتی : شما مجوز ویرایش کردن باشگاه را ندارید', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   UPDATE Club
      SET NAME = @Name
         ,POST_ADRS = @Post_Adrs
         ,EMAL_ADRS = @Emal_Adrs
         ,WEB_SITE = @Web_Site
         ,CORD_X = @Cord_X
         ,CORD_Y = @Cord_Y
         ,TELL_PHON = @Tell_Phon
         ,CELL_PHON = @Cell_Phon
    WHERE CODE = @Code;
END
GO
