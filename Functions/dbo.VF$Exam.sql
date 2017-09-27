SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$Exam]
(	
	@FileNo BIGINT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT e.RWNO
	      ,x.DOMN_DESC AS TYPE
	      ,e.TIME
	      ,e.CACH_NUMB
	      ,e.STEP_HEGH
	      ,e.WEGH
	      ,s.DOMN_DESC AS SEX_TYPE_DNRM
	      ,e.AGE_DNRM
	      ,e.RSLT
	      ,r.DOMN_DESC AS RSLT_DESC
	      ,e.CRET_DATE
	  FROM dbo.Exam e, D$EXTP x, D$RSLT r, D$SXTP s
	 WHERE (@FileNo IS NULL OR e.FIGH_FILE_NO = @FileNo)
	   AND e.RECT_CODE = '004'	   
	   AND e.TYPE = x.VALU
	   AND e.RSLT_DESC = r.VALU
	   AND e.SEX_TYPE_DNRM = s.VALU
)
GO
