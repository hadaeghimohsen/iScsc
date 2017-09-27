SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$AndRequest]
(	
	@X XML
)
RETURNS TABLE 
AS
RETURN 
(
WITH Condition AS(
	   SELECT r.query('.').value('(Condition/@subsys)[1]',   'SMALLINT')     AS Sub_Sys
	         ,r.query('.').value('(Condition/@rqid)[1]',     'BIGINT')       AS Rqid
	         ,r.query('.').value('(Condition/@rqtpcode)[1]', 'VARCHAR(3)')   AS Rqtp_Code
	         ,r.query('.').value('(Condition/@cretby)[1]',   'VARCHAR(250)') AS Cret_By
	         ,r.query('.').value('(Condition/@cretdate)[1]', 'DATE')         AS Cret_Date
	         ,r.query('.').value('(Condition/@mdfyby)[1]',   'VARCHAR(250)') AS Mdfy_By
	         ,r.query('.').value('(Condition/@mdfydate)[1]', 'DATE')         AS Mdfy_Date
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
	  AND (ISNULL(C.Rqid, 0)       = 0 OR R.RQID = C.Rqid)
	  AND (LEN(C.Rqtp_Code)        = 0 OR R.RQTP_CODE = C.Rqtp_Code)
	  AND (ISNULL(C.Sub_Sys, 0)    = 0 OR R.SUB_SYS = C.Sub_Sys)
	  AND (LEN(C.Cret_By)          = 0 OR R.CRET_BY = UPPER(C.Cret_By))
	  AND (C.Cret_Date             = '1900-01-01' OR CAST(R.CRET_DATE AS DATE) = C.Cret_Date)
	  AND (LEN(C.Mdfy_By)          = 0 OR R.MDFY_BY = UPPER(C.Mdfy_By))
	  AND (C.Mdfy_Date             = '1900-01-01' OR CAST(R.MDFY_DATE AS DATE) = C.Mdfy_Date)
)
GO
