SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[SAVE_FRDY_P]	
AS
BEGIN
	DECLARE @CrntDate DATE = GETDATE()
	       ,@CrntYear INT = SUBSTRING(dbo.GET_MTOS_U(GETDATE()), 1, 4)
	       ,@GetYear INT 
	       ,@CrntDay INT = DATEPART(WEEKDAY, GETDATE());
	
	SET @CrntDate = CASE WHEN @CrntDay != 6 THEN DATEADD(DAY, 6 - @CrntDay, GETDATE()) ELSE @CrntDate END;
	SET @GetYear = SUBSTRING(dbo.GET_MTOS_U(@CrntDate), 1, 4);
	
	WHILE @CrntYear = @GetYear
	BEGIN	   
	   IF NOT EXISTS(
	      SELECT *
	        FROM dbo.Holidays
	       WHERE HLDY_DATE = @CrntDate
	   )
	   BEGIN
	      INSERT INTO dbo.Holidays
	              ( CODE ,
	                YEAR ,
	                CYCL ,
	                HLDY_DATE 
	              )
	      VALUES  ( 0 , -- CODE - bigint
	                NULL , -- YEAR - int
	                NULL , -- CYCL - varchar(3)
	                @CrntDate  -- HLDY_DATE - date
	              );
	   END;
	   SET @CrntDate = DATEADD(DAY, 7, @CrntDate);
	   SET @GetYear = SUBSTRING(dbo.GET_MTOS_U(@CrntDate), 1, 4);
	END
END
GO
