SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[PLC_RQST_U]
(
	@X XML
)
RETURNS VARCHAR(3)
AS
BEGIN
	DECLARE @Rqid BIGINT;
	SELECT @Rqid = @X.query('Request').value('(Request/@rqid)[1]', 'BIGINT');
	
	DECLARE @Rslt VARCHAR(3); -- DOMAIN YSNO
	
	SELECT @Rslt = CASE COUNT(*) WHEN 0 THEN '001' WHEN 1 THEN '002' END
	  FROM Request R, V#URFGA P
	 WHERE R.REGN_PRVN_CODE = P.REGN_PRVN_CODE
	   AND R.REGN_CODE = P.REGN_CODE
	   AND R.RQID = @Rqid
	   AND P.SYS_USER = UPPER(SUSER_NAME());
	
	RETURN @Rslt;
END
GO
