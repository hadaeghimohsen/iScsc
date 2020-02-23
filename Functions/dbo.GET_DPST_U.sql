SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GET_DPST_U]
(
	@FileNo BIGINT
)
RETURNS BIGINT
AS
BEGIN
   DECLARE @SumDpstAmnt BIGINT
          ,@SumPymtAmnt BIGINT;
   
   -- مبلغ کل سپرده گذاری شده موجود
   SELECT @SumDpstAmnt = 
             SUM(
               CASE DPST_STAT 
                  WHEN '001' THEN -1 * AMNT
                  WHEN '002' THEN AMNT
               END
             )
     FROM dbo.Gain_Loss_Rial
    WHERE FIGH_FILE_NO = @FileNo
      AND CONF_STAT = '002';           
	
	-- مبلغ استفاده شده از سپرده
	SELECT @SumPymtAmnt = SUM(Pm.AMNT)
	  FROM dbo.Request r, dbo.Request_Row rr, dbo.Payment p, dbo.Payment_Method pm
	 WHERE r.RQID = rr.RQST_RQID
	   AND rr.RQST_RQID = pm.RQRO_RQST_RQID
	   AND rr.RWNO = pm.RQRO_RWNO
	   AND rr.FIGH_FILE_NO = @FileNo
	   AND r.RQID = p.RQST_RQID
	   AND p.RQST_RQID = pm.PYMT_RQST_RQID
	   AND p.PYMT_STAT != '002'
	   AND r.RQST_STAT = '002'
	   AND pm.RCPT_MTOD = '005';
   
   RETURN COALESCE(@SumDpstAmnt, 0) - COALESCE(@SumPymtAmnt, 0);
END
GO
