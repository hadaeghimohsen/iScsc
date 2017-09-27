SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$Clubs]
(	
	@X XML
)
RETURNS TABLE 
AS
RETURN 
(
   /*
    <Region code="" prvncode=""/>
    */
   WITH QXML AS
   (
      SELECT @X.query('Club').value('(Club/@code)[1]', 'BIGINT') AS CODE
   )
	SELECT C.*
	  FROM Club C, V#URFGA UR, V#UCFGA UC, QXML QX
	 WHERE UPPER(SUSER_NAME()) = UR.SYS_USER
	   AND UR.SYS_USER         = UC.SYS_USER
	   AND C.REGN_PRVN_CODE    = UR.REGN_PRVN_CODE
	   AND C.REGN_CODE         = UR.REGN_CODE
	   AND C.CODE              = UC.CLUB_CODE
	   AND (QX.CODE IS NULL OR QX.CODE = 0 OR C.CODE = QX.CODE)
)
GO
