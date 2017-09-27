SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Mohsen, Hadaeghi
-- Create date: 1394/09/17
-- Description: تابع دسترسی به سطوح ردیف جداول
-- =============================================
CREATE FUNCTION [dbo].[FGA_UCLB_U] ()
RETURNS VARCHAR(MAX)
AS
BEGIN
	DECLARE @FGA_USER_CLUBS VARCHAR(MAX);
	SELECT @FGA_USER_CLUBS = (
	   SELECT CAST(A.CLUB_CODE AS VARCHAR(MAX)) + ','
	     FROM dbo.User_Club_Fgac A, dbo.V#URFGA B, Club C
	    WHERE UPPER(A.SYS_USER) = UPPER(SUSER_NAME())
	      AND UPPER(B.SYS_USER) = UPPER(SUSER_NAME())
	      AND A.CLUB_CODE = C.CODE
	      AND C.REGN_PRVN_CODE = B.REGN_PRVN_CODE
	      AND C.REGN_CODE = B.REGN_CODE
	      AND A.REC_STAT = '002' -- رکورد فعال باشد
	      AND A.VALD_TYPE = '002' -- رکورد معتبر و قابل نمایش باشد
	      FOR XML PATH('')
	);
	RETURN ISNULL(LEFT(@FGA_USER_CLUBS, LEN(@FGA_USER_CLUBS) - 1), '0');
END
GO
