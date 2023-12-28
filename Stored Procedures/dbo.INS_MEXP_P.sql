SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[INS_MEXP_P]
	-- Add the parameters for the stored procedure here
	@Club_Code BIGINT,
	@Epit_Code BIGINT,
	@Coch_File_No BIGINT,
	@Vald_Type VARCHAR(3),
	@Calc_Expn_Type VARCHAR(3),
	@Decr_Prct FLOAT,
	@Delv_Stat VARCHAR(3),
	@Delv_Date DATE,
	@Delv_By NVARCHAR(250),
	@Expn_Amnt DECIMAL(18, 2),
	@Expn_Desc NVARCHAR(500),
	@Qnty FLOAT
AS
BEGIN
	-- بررسی دسترسی کاربر
	DECLARE @AP BIT
	       ,@AccessString VARCHAR(250);
	SET @AccessString = N'<AP><UserName>' + SUSER_NAME() + '</UserName><Privilege>212</Privilege><Sub_Sys>5</Sub_Sys></AP>';	
   EXEC iProject.dbo.SP_EXECUTESQL N'SELECT @ap = DataGuard.AccessPrivilege(@P1)',N'@P1 ntext, @ap BIT OUTPUT',@AccessString , @ap = @ap output
   IF @AP = 0 
   BEGIN
      RAISERROR ( N'خطا - عدم دسترسی به ردیف 212 سطوح امینتی', -- Message text.
               16, -- Severity.
               1 -- State.
               );
      RETURN;
   END
   -- پایان دسترسی
   
   INSERT INTO dbo.Misc_Expense
           ( CLUB_CODE ,
             EPIT_CODE ,
             COCH_FILE_NO ,
             CODE ,
             VALD_TYPE ,
             EXPN_AMNT ,
             EXPN_DESC ,
             CALC_EXPN_TYPE ,
             DECR_PRCT ,
             DELV_STAT ,
             DELV_DATE ,
             DELV_BY ,
             QNTY
           )
   VALUES  ( @Club_Code , -- CLUB_CODE - bigint
             @Epit_Code , -- EPIT_CODE - bigint
             @Coch_File_No , -- COCH_FILE_NO - bigint
             0 , -- CODE - bigint
             @Vald_Type , -- VALD_TYPE - varchar(3)
             @Expn_Amnt , -- EXPN_AMNT - bigint
             @Expn_Desc , -- EXPN_DESC - nvarchar(500)
             @Calc_Expn_Type , -- CALC_EXPN_TYPE - varchar(3)
             @Decr_Prct , -- DECR_PRCT - float
             @Delv_Stat , -- DELV_STAT - varchar(3)
             @Delv_Date , -- DELV_DATE - date
             @Delv_By , -- DELV_BY - nvarchar(250)
             @Qnty
           );
END
GO
