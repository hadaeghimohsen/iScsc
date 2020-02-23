SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_DBBF_U]
(
	@FileNo BIGINT
)
RETURNS BIGINT
AS
BEGIN
   DECLARE @DebtDnrm BIGINT,
           @DiscAmnt BIGINT,
           @ConfPay BIGINT;
           
	SELECT @DebtDnrm = SUM((D.EXPN_PRIC + ISNULL(D.EXPN_EXTR_PRCT, 0)) * D.QNTY) 
     FROM Request R, Request_Row Rr, Fighter F, Payment P, Payment_Detail D
    WHERE R.RQID = Rr.RQST_RQID
      AND Rr.FIGH_FILE_NO = F.FILE_NO
      AND R.RQID = P.RQST_RQID
      AND P.RQST_RQID = D.PYMT_RQST_RQID
      AND D.PYMT_RQST_RQID = Rr.RQST_RQID
      AND D.RQRO_RWNO = Rr.RWNO
      AND R.RQTP_CODE = '016'
      AND R.RQST_STAT IN ('001', '002')
      AND F.CONF_STAT = '002'
      --AND D.PAY_STAT = '001'
      AND p.PYMT_STAT != '002'
      AND F.FILE_NO = @FileNo
      AND R.RQTP_CODE NOT IN ('022', '023');
   
   
   SELECT @DiscAmnt = ISNULL(SUM(D.AMNT), 0) 
     FROM Request R, Request_Row Rr, Fighter F, Payment P, Payment_Discount D
    WHERE R.RQID = Rr.RQST_RQID
      AND Rr.FIGH_FILE_NO = F.FILE_NO
      AND R.RQID = P.RQST_RQID
      AND P.RQST_RQID = D.PYMT_RQST_RQID
      AND D.PYMT_RQST_RQID = Rr.RQST_RQID
      AND D.RQRO_RWNO = Rr.RWNO
      AND R.RQTP_CODE = '016'
      AND R.RQST_STAT IN ('001', '002')
      AND F.CONF_STAT = '002'
      AND D.STAT = '002'
      --AND D.PAY_STAT = '001'
      AND p.PYMT_STAT != '002'
      AND F.FILE_NO = @FileNo
      AND R.RQTP_CODE NOT IN ('022', '023');
   
   
   SELECT @ConfPay = ISNULL(SUM(D.AMNT) ,0)
     FROM Request R, Request_Row Rr, Fighter F, Payment P, dbo.Payment_Method D
    WHERE R.RQID = Rr.RQST_RQID
      AND Rr.FIGH_FILE_NO = F.FILE_NO
      AND R.RQID = P.RQST_RQID
      AND P.RQST_RQID = D.PYMT_RQST_RQID
      AND D.PYMT_RQST_RQID = Rr.RQST_RQID
      AND D.RQRO_RWNO = Rr.RWNO
      AND R.RQTP_CODE = '016'
      AND R.RQST_STAT IN ('001', '002')
      AND F.CONF_STAT = '002'
      --AND D.PAY_STAT = '001'
      AND p.PYMT_STAT != '002'
      AND F.FILE_NO = @FileNo
      AND R.RQTP_CODE NOT IN ('022', '023');
   
   --IF EXISTS (
   --   SELECT *
   --     FROM dbo.Gain_Loss_Rial
   --    WHERE FIGH_FILE_NO = @FileNo
   --      AND CONF_STAT = '002'
   --)
   --BEGIN
   --   SELECT @DebtDnrm = COALESCE(@DebtDnrm, 0)- COALESCE(@DiscAmnt, 0) - COALESCE(@ConfPay, 0) + 
   --          ISNULL(
   --            SUM(
   --               CASE CHNG_TYPE 
   --                 WHEN '001' THEN
   --                 AMNT
   --                 WHEN '002' THEN
   --                 -1 * AMNT
   --               END
   --             ),
   --             0
   --          )
   --     FROM dbo.Gain_Loss_Rial
   --    WHERE FIGH_FILE_NO = @FileNo
   --      AND CONF_STAT = '002'
   --      AND DEBT_TYPE NOT IN ('002', '004');
   --END;  
   --ELSE
   BEGIN
      SET @DebtDnrm = COALESCE(@DebtDnrm, 0)- COALESCE(@DiscAmnt, 0) - COALESCE(@ConfPay, 0);
   END 
   RETURN COALESCE(@DebtDnrm, 0);
END
GO
