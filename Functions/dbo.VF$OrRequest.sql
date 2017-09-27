SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$OrRequest]
(	
	@X XML
)
RETURNS TABLE 
AS
RETURN 
(
	WITH Condition AS(
	   SELECT r.value('(Condition/@subsys)[1]',   'SMALLINT')     AS Sub_Sys
	         ,r.value('(Condition/@rqid)[1]',     'BIGINT')       AS Rqid
	         ,r.value('(Condition/@rqtpcode)[1]', 'VARCHAR(3)')   AS Rqtp_Code
	         ,r.value('(Condition/@cretby)[1]',   'VARCHAR(250)') AS Cret_By
	         ,r.value('(Condition/@cretdate)[1]', 'DATE')         AS Cret_Date
	         ,r.value('(Condition/@mdfyby)[1]',   'VARCHAR(250)') AS Mdfy_By
	         ,r.value('(Condition/@mdfydate)[1]', 'DATE')         AS Mdfy_Date
	   FROM @X.nodes('//Condition') C(r)
	)
	SELECT R.SUB_SYS
	      ,R.RQID
	      ,R.RQTP_CODE
	      ,R.CRET_BY
	      ,R.CRET_DATE
	      ,R.MDFY_BY
	      ,R.MDFY_DATE
	FROM Request R, Condition C
	WHERE R.RQST_STAT = '001'
	  AND (
	         (ISNULL(C.Rqid, 0)       = 0 OR R.RQID = C.Rqid)
	      OR (LEN(C.Rqtp_Code)        = 0 OR R.RQTP_CODE = C.Rqtp_Code)
	      OR (ISNULL(C.Sub_Sys, 0)    = 0 OR R.SUB_SYS = C.Sub_Sys)
	      OR (LEN(C.Cret_By)          = 0 OR R.CRET_BY = UPPER(C.Cret_By))
	      OR (C.Cret_Date             = '1900-01-01' OR CAST(R.CRET_DATE AS DATE) = C.Cret_Date)
	      OR (LEN(C.Mdfy_By)          = 0 OR R.MDFY_BY = UPPER(C.Mdfy_By))
	      OR (C.Mdfy_Date             = '1900-01-01' OR CAST(R.MDFY_DATE AS DATE) = C.Mdfy_Date)
	  )
)
GO
