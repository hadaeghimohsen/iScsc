SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$Fighters]
(	
	@X XML
)
RETURNS TABLE 
AS
RETURN 
(
   /*
    <Fighter fileno=""/>
    */
   WITH QXML AS
   (
      SELECT @X.query('Fighter').value('(Fighter/@fileno)[1]', 'BIGINT') AS File_No
   )
	SELECT F.*
	  FROM Fighter F, V#URFGA UR, V#UCFGA UC, QXML QX
	 WHERE UPPER(SUSER_NAME()) = UR.SYS_USER
	   AND UR.SYS_USER         = UC.SYS_USER
	   AND UR.REGN_PRVN_CODE   = F.REGN_PRVN_CODE
	   AND UR.REGN_CODE        = F.REGN_CODE
	   AND UC.CLUB_CODE        = F.CLUB_CODE_DNRM
	   AND ISNULL(F.ACTV_TAG_DNRM, '101') >= '101'
	   AND (QX.File_No IS NULL OR QX.File_No = 0 OR F.FILE_NO = QX.File_No)
)
GO
