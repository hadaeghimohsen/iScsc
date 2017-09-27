SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$Test]
(	
	@FileNo BIGINT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT t.RWNO
	      ,dbo.GET_MTOS_U(t.CRTF_DATE) AS CRTF_DATE
	      ,t.CRTF_NUMB
	      ,dbo.GET_MTOS_U(t.TEST_DATE) AS TEST_DATE
	      ,d.DOMN_DESC AS RSLT
	      ,m.MTOD_DESC
	      ,c.CTGY_DESC
	  FROM Test t, Method m, Category_Belt c, D$TRSL d
	 WHERE (@FileNo IS NULL OR t.FIGH_FILE_NO = @FileNo)
	   AND t.RECT_CODE = '004'
	   AND t.CTGY_MTOD_CODE = m.CODE
	   AND t.CTGY_CODE = c.CODE
	   AND m.CODE = c.MTOD_CODE
	   AND t.RSLT = d.VALU
)
GO
