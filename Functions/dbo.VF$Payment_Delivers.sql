SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Batch submitted through debugger: SQLQuery21.sql|7|0|C:\Users\HADAEGHI\AppData\Local\Temp\~vsE87B.sql
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[VF$Payment_Delivers]
(	
	@X XML
)
RETURNS TABLE 
AS
RETURN 
(	
   WITH Q AS
   (
      SELECT @X.query('//Payment').value('(Payment/@fromdate)[1]', 'DATE') AS FromDate
            ,@X.query('//Payment').value('(Payment/@todate)[1]'  , 'DATE') AS ToDate
            ,@X.query('//Payment').value('(Payment/@delvstat)[1]', 'VARCHAR(3)') AS DelvStat
            ,@X.query('//Payment').value('(Payment/@cashby)[1]',   'VARCHAR(250)') AS CashBy
   )
   SELECT P.CASH_BY,
	       P.CLUB_CODE_DNRM,
	       --D$RCMT.DOMN_DESC, 
          --SUM(Pd.EXPN_PRIC) AS EXPN_PRIC          
          Pd.RCPT_MTOD,
          SUM(Pd.AMNT) AMNT
     FROM Request R,
          Payment P,
          --Payment_Detail Pd LEFT OUTER JOIN
          Payment_Method Pd LEFT OUTER JOIN
          D$RCMT ON Pd.RCPT_MTOD = D$RCMT.VALU,
          Q
    WHERE R.RQID      = P.RQST_RQID
      AND R.RQST_STAT <> '003'
      AND P.CASH_CODE = Pd.PYMT_CASH_CODE
      AND P.RQST_RQID = Pd.PYMT_RQST_RQID
      AND p.PYMT_STAT != '002'
	   AND R.REGN_PRVN_CODE + R.REGN_CODE IN (
         SELECT REGN_PRVN_CODE + REGN_CODE 
	        FROM V#URFGA
	       --WHERE UPPER(SYS_USER) = UPPER(COALESCE(Q.CashBy, SUSER_NAME()))	         
	       WHERE UPPER(SYS_USER) = UPPER(COALESCE(/*Q.CashBy*/NULL, SUSER_NAME()))	         
	   )
	   AND P.CLUB_CODE_DNRM IN (
		   SELECT CLUB_CODE
		     FROM V#UCFGA
		    --WHERE UPPER(SYS_USER) = UPPER(COALESCE(Q.CashBy, SUSER_NAME()))	         
		    WHERE UPPER(SYS_USER) = UPPER(COALESCE(/*Q.CashBy*/NULL, SUSER_NAME()))	         
	   )
      --AND Pd.PAY_STAT = '002'
      AND (Q.FromDate IN ( '1900-01-01' , '0001-01-01' ) OR CAST(Pd.ACTN_DATE AS DATE)  >= Q.FromDate)
      AND (Q.ToDate   IN ( '1900-01-01' , '0001-01-01' ) OR CAST(Pd.ACTN_DATE AS DATE)  <= Q.ToDate)
      AND (Q.DelvStat IS NULL        OR COALESCE(P.DELV_STAT, '001') = COALESCE(Q.DelvStat, '001'))
      AND P.CASH_BY = COALESCE(Q.CashBy, SUSER_NAME())
    GROUP BY P.CASH_BY,
	      P.CLUB_CODE_DNRM,
	      Pd.RCPT_MTOD
	      --D$RCMT.DOMN_DESC
)
GO
