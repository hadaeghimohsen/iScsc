SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[PLC_REGN_U]
(
	@X XML
)
RETURNS VARCHAR(3)
AS
BEGIN
	DECLARE @PrvnCode VARCHAR(3)
	       ,@RegnCode VARCHAR(3);
	SELECT @PrvnCode = @X.query('Region').value('(Region/@prvncode)[1]', 'VARCHAR(3)')
	      ,@RegnCode = @X.query('Region').value('(Region/@regncode)[1]', 'VARCHAR(3)');
	
	DECLARE @Rslt VARCHAR(3); -- DOMAIN YSNO
	
	SELECT @Rslt = CASE COUNT(*) WHEN 0 THEN '001' WHEN 1 THEN '002' END
	  FROM Region R, V#URFGA P
	 WHERE R.PRVN_CODE = P.REGN_PRVN_CODE
	   AND R.CODE = P.REGN_CODE
	   AND R.PRVN_CODE = @PrvnCode
	   AND R.CODE = @RegnCode
	   AND P.SYS_USER = UPPER(SUSER_NAME());
	
	RETURN @Rslt;
END
GO
