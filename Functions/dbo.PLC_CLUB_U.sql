SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[PLC_CLUB_U]
(
	@X XML
)
RETURNS VARCHAR(3)
AS
BEGIN
	DECLARE @Code BIGINT;
	SELECT @Code = @X.query('Club').value('(Club/@code)[1]', 'BIGINT');
	
	DECLARE @Rslt VARCHAR(3); -- DOMAIN YSNO
	
	SELECT @Rslt = CASE COUNT(*) WHEN 0 THEN '001' WHEN 1 THEN '002' END
	  FROM Club C, V#UCFGA P, V#URFGA R
	 WHERE C.REGN_PRVN_CODE = R.REGN_PRVN_CODE
	   AND C.REGN_CODE = R.REGN_CODE
	   AND C.CODE = P.CLUB_CODE
	   AND C.CODE = @Code
	   AND P.SYS_USER = UPPER(SUSER_NAME())
	   AND R.SYS_USER = UPPER(SUSER_NAME());
	
	RETURN @Rslt;
END
GO
