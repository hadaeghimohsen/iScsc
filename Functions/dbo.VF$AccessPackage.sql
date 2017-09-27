SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$AccessPackage]
(	
	@X XML
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	WITH Condition AS(
	   SELECT r.query('.').value('(Computer/@cpu)[1]',   'VARCHAR(30)')     AS CpuSrno
	   FROM @X.nodes('//Computer') C(r)
	)
	SELECT DISTINCT
	       ap.RWNO
	  FROM iProject.DataGuard.V#Access_Package ap, Condition c
	 WHERE SUB_SYS = 5
	   AND CPU_SRNO_DNRM = c.CpuSrno
	UNION ALL
	SELECT RWNO
	  FROM iProject.DataGuard.Sub_System_Item	  
	 WHERE SUB_SYS = 5
	   AND EXISTS(
	      SELECT *
	        FROM iProject.DataGuard.[User]
	       WHERE UPPER(USERDB) = UPPER(SUSER_NAME())
	         AND DFLT_FACT = '002'
	   )
)
GO
