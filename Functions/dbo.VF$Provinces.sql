SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$Provinces]
(	
	@X XML
)
RETURNS TABLE 
AS
RETURN 
(
   /*
    <Province code=""/>
    */
   WITH QXML AS
   (
      SELECT @X.query('Province').value('(Province/@code)[1]', 'VARCHAR(3)') AS CODE
   )
	SELECT P.*
	  FROM Province P, V#URFGA UR, QXML QX
	 WHERE UPPER(SUSER_NAME()) = UR.SYS_USER
	   AND P.CODE              = ur.REGN_PRVN_CODE
	   AND (QX.Code IS NULL OR LEN(QX.CODE) <> 3 OR P.CODE = QX.CODE)
)
GO
