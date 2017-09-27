SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$All_Debt_Fighter]
(	
)
RETURNS TABLE 
AS
RETURN 
(
   SELECT F.FILE_NO, F.NAME_DNRM, SUM(D.EXPN_PRIC) AS SUM_DEBT_EXPN_PRIC
     FROM Request R, Request_Row Rr, Fighter F, Payment P, Payment_Detail D
    WHERE R.RQID = Rr.RQST_RQID
      AND Rr.FIGH_FILE_NO = F.FILE_NO
      AND R.RQID = P.RQST_RQID
      AND P.RQST_RQID = D.PYMT_RQST_RQID
      AND D.PYMT_RQST_RQID = Rr.RQST_RQID
      AND D.RQRO_RWNO = Rr.RWNO
      AND R.RQST_STAT IN ('001', '002')
      AND F.CONF_STAT = '002'
      AND D.PAY_STAT = '001'
    GROUP BY F.FILE_NO, F.NAME_DNRM
)
GO
