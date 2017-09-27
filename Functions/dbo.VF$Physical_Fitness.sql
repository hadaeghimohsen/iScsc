SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$Physical_Fitness]
(	
	@FileNo BIGINT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT p.RWNO
	      ,p.PULL_UP
	      ,p.PUSH_UP
	      ,p.SQUT_TRST
	      ,p.SQUT_JUMP
	      ,p.SIT_UP
	      ,p.PHSC_FITN_INDX_DNRM
	      ,p.CRET_DATE
	  FROM Physical_Fitness P
	 WHERE (@FileNo IS NULL OR p.FIGH_FILE_NO = @FileNo)
	   AND p.RECT_CODE = '004'	   
)
GO
