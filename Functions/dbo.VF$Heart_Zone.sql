SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$Heart_Zone]
(	
	@FileNo BIGINT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT h.RWNO
	      ,h.REST_HERT_RATE
	      ,h.AGE_DNRM
	      ,h.MAX_HERT_RATE_DNRM
	      ,h.WORK_HERT_RATE_DNRM
	      ,h.HR60_DNRM
	      ,h.HR70_DNRM
	      ,h.HR80_DNRM
	      ,h.HR85_DNRM
	      ,h.HR90_DNRM
	      ,h.CRET_DATE
	  FROM dbo.Heart_Zone h
	 WHERE (@FileNo IS NULL OR h.FIGH_FILE_NO = @FileNo)
	   AND h.RECT_CODE = '004'	   
)
GO
