SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$Calculate_Calorie]
(	
	@FileNo BIGINT
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT c.RWNO
	      ,c.HEGH
	      ,c.WEGH
	      ,c.TRAN_TIME
	      ,c.BASC_ENRG_DNRM
	      ,c.EXTR_ENRG_DNRM
	      ,c.TOTL_ENRG_DNRM
	      ,c.CARB_ENRG_DNRM
	      ,c.FAT_ENRG_DNRM
	      ,c.PROT_ENRG_DNRM
	      ,c.BMI_DNRM
	      ,b.DOMN_DESC AS BMI_RSLT_DNRM
	      ,c.CRET_DATE
	  FROM dbo.Calculate_Calorie c, D$BMIR b
	 WHERE (@FileNo IS NULL OR c.FIGH_FILE_NO = @FileNo)
	   AND c.RECT_CODE = '004'	   
	   AND c.BMI_RSLT_DNRM = b.VALU
)
GO
