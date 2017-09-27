SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mohsen, Hadaeghi
-- Create date: 1394/09/17
-- Description: تابع دسترسی به سطوح ردیف جداول
-- =============================================
CREATE FUNCTION [dbo].[FGA_UPRV_U] ()
RETURNS VARCHAR(MAX)
AS
BEGIN
	DECLARE @FGA_USER_PROVINCES VARCHAR(MAX);
	SELECT @FGA_USER_PROVINCES = (
	   SELECT REGN_PRVN_CODE + ','
	     FROM dbo.User_Region_Fgac
	    WHERE UPPER(SYS_USER) = UPPER(SUSER_NAME())
	      AND REC_STAT = '002' -- رکورد فعال باشد
	      AND VALD_TYPE = '002' -- رکورد معتبر و قابل نمایش باشد
	      FOR XML PATH('')
	);
	RETURN LEFT(@FGA_USER_PROVINCES, LEN(@FGA_USER_PROVINCES) - 1);
END
GO
