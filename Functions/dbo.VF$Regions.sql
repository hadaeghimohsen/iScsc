SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$Regions]
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
      SELECT @X.query('Region').value('(Region/@code)[1]', 'VARCHAR(3)') AS CODE
            ,@X.query('Region').value('(Region/@prvncode)[1]', 'VARCHAR(3)') AS PRVN_CODE
   )
	SELECT R.*
	  FROM Province P, Region R, V#URFGA UR, QXML QX
	 WHERE UPPER(SUSER_NAME()) = UR.SYS_USER
	   AND P.CODE              = UR.REGN_PRVN_CODE
	   AND R.PRVN_CODE         = P.CODE
	   AND R.CODE              = UR.REGN_CODE
	   AND (QX.CODE IS NULL OR LEN(QX.CODE) <> 3 OR R.CODE = QX.CODE)
	   AND (QX.PRVN_CODE IS NULL OR LEN(QX.PRVN_CODE) <> 3 OR P.CODE = Qx.PRVN_CODE)
)
GO
