SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$Campitition]
(	
	@FileNo BIGINT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT c.RWNO
	      ,l.DOMN_DESC AS LEVL_NUMB	      
	      ,s.DOMN_DESC AS SECT_NUMB
	      ,dbo.GET_MTOS_U(c.CAMP_DATE) AS CAMP_DATE
	      ,c.PLAC_ADRS
	  FROM Campitition C, D$CMLV l, D$CMSC s
	 WHERE (@FileNo IS NULL OR c.FIGH_FILE_NO = @FileNo)
	   AND c.RECT_CODE = '004'
	   AND c.LEVL_NUMB = l.VALU
	   AND c.SECT_NUMB = s.VALU
)
GO
