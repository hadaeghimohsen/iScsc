SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[CHK_DEBT_U]
(
	@X XML
)
RETURNS INT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @FileNo BIGINT
		   ,@ExprDebtDay INT;

	-- Add the T-SQL statements to compute the return value here
	SELECT @FileNo = @X.query('Fighter').value('(Fighter/@fileno)[1]', 'BIGINT');
	SELECT @ExprDebtDay =  S.EXPR_DEBT_DAY
	  FROM dbo.Fighter F, dbo.Settings S 
	 WHERE FILE_NO = @FileNo
	   AND S.CLUB_CODE = F.CLUB_CODE_DNRM;
	
	-- میزان مبلغ بدهی هیچ مانعی ندارد
	IF ISNULL(@ExprDebtDay, 0) = 0
		RETURN 1; 
	
	-- آیا درخواستی وجود دارد که باعث شود پیام هشدار پایان مهلت بدهی نمایش داده شود یا خیر
	IF EXISTS (
		SELECT *
		  FROM Request R, dbo.Request_Row Rr, dbo.Payment_Detail Pd
		 WHERE R.RQID = Rr.RQST_RQID
		   AND Rr.FIGH_FILE_NO = @FileNo		   
		   AND Rr.RQST_RQID = Pd.PYMT_RQST_RQID
		   AND Rr.RWNO = Pd.RQRO_RWNO
		   AND R.RQST_STAT = '002'
		   AND Pd.PAY_STAT = '001'
		   AND CAST(DATEADD(DAY, @ExprDebtDay, Pd.CRET_DATE) AS DATE) < CAST(GETDATE() AS DATE)
	) OR EXISTS(
		SELECT *
		  FROM dbo.Request R, dbo.Request_Row Rr, dbo.Gain_Loss_Rial G
		 WHERE R.RQID = Rr.RQST_RQID
		   AND Rr.FIGH_FILE_NO = @FileNo
		   AND Rr.RQST_RQID = G.RQRO_RQST_RQID
		   AND Rr.RWNO = G.RQRO_RWNO
		   AND R.RQST_STAT = '002'
		   AND G.CONF_STAT = '002'
		   AND G.RWNO = (
			   SELECT MAX(RWNO)
			     FROM dbo.Gain_Loss_Rial Gt
			    WHERE Gt.FIGH_FILE_NO = G.FIGH_FILE_NO
			      AND Gt.CONF_STAT = '002'
		   )
		   AND G.CRNT_DEBT_DNRM > 0
		   AND CAST(DATEADD(DAY, @ExprDebtDay, G.PAID_DATE) AS DATE) < CAST(GETDATE() AS DATE)
	)
		RETURN 0;
	  

	RETURN 1;

END
GO
